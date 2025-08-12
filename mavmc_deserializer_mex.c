// mavmc_deserializer_mex.c
// MEX: deserializacja MAVLink v1.0 (dialekt: mavmc)
// Wejście: uint8 vector (porcja bajtów)
// Wyjście: cell 1xK z MATLAB-owymi strukturami (1 struktura = 1 komunikat)

#include "mex.h"
#include <stdint.h>
#include <string.h>

// *** WŁĄCZ NAGŁÓWKI MAVLink (Twoje wygenerowane) ***
#include "generated/mavmc/mavlink.h"   // ten plik zwykle wciąga resztę (helpers, types)

// --- Pomocnicze: tworzenie prostych typów MATLAB ---
static mxArray* mx_scalar_double(double v) {
    mxArray* a = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(a) = v;
    return a;
}

static mxArray* mx_uint8_row(const uint8_t* data, mwSize n) {
    mxArray* a = mxCreateNumericMatrix(1, n, mxUINT8_CLASS, mxREAL);
    uint8_t* p = (uint8_t*)mxGetData(a);
    if (n && data) memcpy(p, data, n);
    return a;
}

// --- Fallback: struktura "generic" dla nieobsługiwanych msgid ---
static mxArray* make_generic_msg_struct(const mavlink_message_t* msg) {
    const char* fn[] = {"name","msgid","seq","sysid","compid","len","payload_raw"};
    mxArray* s = mxCreateStructMatrix(1,1,7,fn);

    // Nazwa – jeżeli masz tablicę nazw, możesz ustawić prawdziwą; tu ustawiamy "UNKNOWN"
    mxSetField(s,0,"name",        mxCreateString("UNKNOWN"));
    mxSetField(s,0,"msgid",       mx_scalar_double((double)msg->msgid));
    mxSetField(s,0,"seq",         mx_scalar_double((double)msg->seq));
    mxSetField(s,0,"sysid",       mx_scalar_double((double)msg->sysid));
    mxSetField(s,0,"compid",      mx_scalar_double((double)msg->compid));
    mxSetField(s,0,"len",         mx_scalar_double((double)msg->len));
    mxSetField(s,0,"payload_raw", mx_uint8_row(_MAV_PAYLOAD(msg), msg->len));
    return s;
}

// --- HEARTBEAT ---
static mxArray* make_heartbeat_struct(const mavlink_message_t* msg) {
    mavlink_heartbeat_t hb;
    mavlink_msg_heartbeat_decode(msg, &hb);

    const char* fn[] = {
        "name","msgid","seq","sysid","compid",
        "type","autopilot","base_mode","custom_mode","system_status","mavlink_version"
    };
    mxArray* s = mxCreateStructMatrix(1,1,11,fn);

    mxSetField(s,0,"name",           mxCreateString("HEARTBEAT"));
    mxSetField(s,0,"msgid",          mx_scalar_double((double)msg->msgid));
    mxSetField(s,0,"seq",            mx_scalar_double((double)msg->seq));
    mxSetField(s,0,"sysid",          mx_scalar_double((double)msg->sysid));
    mxSetField(s,0,"compid",         mx_scalar_double((double)msg->compid));

    mxSetField(s,0,"type",           mx_scalar_double((double)hb.type));
    mxSetField(s,0,"autopilot",      mx_scalar_double((double)hb.autopilot));
    mxSetField(s,0,"base_mode",      mx_scalar_double((double)hb.base_mode));
    mxSetField(s,0,"custom_mode",    mx_scalar_double((double)hb.custom_mode));
    mxSetField(s,0,"system_status",  mx_scalar_double((double)hb.system_status));
    mxSetField(s,0,"mavlink_version",mx_scalar_double((double)hb.mavlink_version));
    return s;
}

// --- RADIO_STATUS ---
static mxArray* make_radio_status_struct(const mavlink_message_t* msg) {
    mavlink_radio_status_t rs;
    mavlink_msg_radio_status_decode(msg, &rs);

    const char* fn[] = {
        "name","msgid","seq","sysid","compid",
        "rssi","remrssi","txbuf","noise","remnoise","rxerrors","fixed"
    };
    mxArray* s = mxCreateStructMatrix(1,1,12,fn);

    mxSetField(s,0,"name",      mxCreateString("RADIO_STATUS"));
    mxSetField(s,0,"msgid",     mx_scalar_double((double)msg->msgid));
    mxSetField(s,0,"seq",       mx_scalar_double((double)msg->seq));
    mxSetField(s,0,"sysid",     mx_scalar_double((double)msg->sysid));
    mxSetField(s,0,"compid",    mx_scalar_double((double)msg->compid));

    mxSetField(s,0,"rssi",      mx_scalar_double((double)rs.rssi));
    mxSetField(s,0,"remrssi",   mx_scalar_double((double)rs.remrssi));
    mxSetField(s,0,"txbuf",     mx_scalar_double((double)rs.txbuf));
    mxSetField(s,0,"noise",     mx_scalar_double((double)rs.noise));
    mxSetField(s,0,"remnoise",  mx_scalar_double((double)rs.remnoise));
    mxSetField(s,0,"rxerrors",  mx_scalar_double((double)rs.rxerrors));
    mxSetField(s,0,"fixed",     mx_scalar_double((double)rs.fixed));
    return s;
}

/*
 // --- PRZYKŁAD: Twoje własne wiadomości (odkomentuj, uzupełnij pola)
 // DEBUG_FRAME (jeśli znasz pola)
 static mxArray* make_debug_frame_struct(const mavlink_message_t* msg) {
     mavlink_debug_frame_t d;
     mavlink_msg_debug_frame_decode(msg,&d);
     const char* fn[] = {"name","msgid","seq","sysid","compid","...twoje pola..."};
     mxArray* s = mxCreateStructMatrix(1,1,/*N*//*,"fn");
     // mxSetField(...);  // wypełnij wg generated struct
     return s;
 }

 // GENERIC_CAN_FRAME
 static mxArray* make_generic_can_frame_struct(const mavlink_message_t* msg) {
     mavlink_generic_can_frame_t c;
     mavlink_msg_generic_can_frame_decode(msg,&c);
     // Wypisz faktyczne pola z wygenerowanego nagłówka
 }
*/

// --- Parser state utrzymywany między wywołaniami ---
static mavlink_status_t g_status;
static mavlink_message_t g_msg;
static int g_initialized = 0;

// Opcjonalnie: prosty "reset" stanu parsera
static void parser_reset(void) {
    memset(&g_status, 0, sizeof(g_status));
    memset(&g_msg, 0, sizeof(g_msg));
}

// --- Wejściowy bufor bajtów -> cell z komunikatami ---
void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
    if (!g_initialized) {
        parser_reset();
        g_initialized = 1;
    }

    if (nrhs < 1) {
        mexErrMsgIdAndTxt("mavmc_deserializer_mex:args",
                          "Podaj co najmniej jeden argument: uint8 wektor bajtów lub 'reset'.");
    }

    // Obsługa "reset"
    if (mxIsChar(prhs[0])) {
        char cmd[16] = {0};
        if (mxGetString(prhs[0], cmd, sizeof(cmd)) == 0 && strcmp(cmd,"reset")==0) {
            parser_reset();
            if (nlhs > 0) plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
            return;
        } else {
            mexErrMsgIdAndTxt("mavmc_deserializer_mex:args",
                              "Nieznane polecenie tekstowe. Użyj 'reset' lub przekaż uint8.");
        }
    }

    if (!mxIsUint8(prhs[0])) {
        mexErrMsgIdAndTxt("mavmc_deserializer_mex:args",
                          "Wejście musi być wektorem typu uint8 (porcja bajtów).");
    }

    const uint8_t* data = (const uint8_t*)mxGetData(prhs[0]);
    mwSize N = mxGetNumberOfElements(prhs[0]);

    // Potencjalnie max K ~ N (w praktyce mniej) – zbierzemy wskaźniki i potem złożymy cell
    // Rezerwujemy umiarkowanie; jeśli pusto – zwrócimy [].
    mxArray** items = (mxArray**)mxCalloc(N > 1 ? N : 1, sizeof(mxArray*));
    mwSize k = 0;

    for (mwSize i = 0; i < N; ++i) {
        if (mavlink_parse_char(MAVLINK_COMM_0, data[i], &g_msg, &g_status)) {
            mxArray* s = NULL;

            switch (g_msg.msgid) {
                case MAVLINK_MSG_ID_HEARTBEAT:
                    s = make_heartbeat_struct(&g_msg);
                    break;
                case MAVLINK_MSG_ID_RADIO_STATUS:
                    s = make_radio_status_struct(&g_msg);
                    break;

                // --- TU DODASZ SWOJE WIADOMOŚCI ---
                // case MAVLINK_MSG_ID_DEBUG_FRAME:
                //     s = make_debug_frame_struct(&g_msg);
                //     break;
                // case MAVLINK_MSG_ID_GENERIC_CAN_FRAME:
                //     s = make_generic_can_frame_struct(&g_msg);
                //     break;

                default:
                    s = make_generic_msg_struct(&g_msg);
                    break;
            }

            items[k++] = s;
        }
    }

    if (k == 0) {
        // brak pełnych ramek
        if (nlhs > 0) plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    } else {
        mxArray* cell = mxCreateCellMatrix(1, k);
        for (mwIndex i = 0; i < (mwIndex)k; ++i) {
            mxSetCell(cell, i, items[i]);
        }
        if (nlhs > 0) plhs[0] = cell;
    }

    mxFree(items);
}
