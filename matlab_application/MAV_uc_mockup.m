% MAV_uc_mockup.m
clear; clc;
dialect = mavlinkdialect("mavmc.xml", 1);
mavlink = mavlinkio(dialect);

portName = 'COM20';
baudRate = 115200;
s = serialport(portName, baudRate);

pause(1.2);
disp("UC mockup running...");


%% Stałe / konfiguracja
SYS_ID   = uint8(1);
COMP_ID  = uint8(1);
% --- Częstotliwości wysyłek (Hz) ---
HB_FREQ  = 1;
DBG_FREQ = 0.01;
CAN_FREQ = 0.01;

% --- Szablony wiadomości (ustawiane raz) ---
% HEARTBEAT
hbMsg = createmsg(dialect, "HEARTBEAT");
hbMsg.Payload.type          = uint8(0);     % MAV_TYPE_GENERIC
hbMsg.Payload.autopilot     = uint8(8);     % nc MAV_AUTOPILOT_INVALID - 8
hbMsg.Payload.base_mode     = uint8(0);     % nc
hbMsg.Payload.system_status = uint8(0);     % ? MAV_STATE_UNINIT - 0 
hbMsg.Payload.custom_mode   = uint32(0);    % ? 
% hbMsg.Payload.mavlink_version = uint8(3); % not writable by user
hbMsg.SystemID   = SYS_ID;
hbMsg.ComponentID= COMP_ID;

% DEBUG_FRAME
dbgMsg = createmsg(dialect, "DEBUG_FRAME");
dbgMsg.SystemID    = SYS_ID;
dbgMsg.ComponentID = COMP_ID;

dbgMsgText = "Test 123! ten tekst ma na pewno wiecej znakow niz mozna miec";

% GENERIC_CAN_FRAME
canMsg = createmsg(dialect, "GENERIC_CAN_FRAME");
canMsg.Payload.timestamp = uint32(0);
canMsg.Payload.id        = uint16(65);
canMsg.Payload.data      = uint8([0 0 0 0 0 0 0 0]);
canMsg.SystemID    = SYS_ID;
canMsg.ComponentID = COMP_ID;

% --- Helper: serializacja + zapis + licznik bajtów ---
function nbytes = sendMsg(s, mavlink, msg)
    buf = serializemsg(mavlink, msg);
    write(s, buf, "uint8");
    nbytes = numel(buf);
end

%% Main loop
disp('Start loop');
% --- Czas odniesienia i znaczniki ostatnich wysyłek ---
tStart = tic;
lastHB  = -inf;
lastDBG = -inf;
lastCAN = -inf;
bytes_accum = 0;
tRateLast = tic;   % czas ostatniego pomiaru prędkości
while true
    HB_DT  = 1 / HB_FREQ;
    DBG_DT = 1 / DBG_FREQ;
    CAN_DT = 1 / CAN_FREQ;
    tNow = toc(tStart);   % sekundy od startu
    bytes_total = 0;

    % --- HEARTBEAT ---
    if tNow - lastHB >= HB_DT
        bytes_total = bytes_total + sendMsg(s, mavlink, hbMsg);
        lastHB = tNow;
    end

    % --- DEBUG_FRAME ---
    if tNow - lastDBG >= DBG_DT
        dbgMsg.Payload.status = uint8(randi(255));
        % tekst: zero-terminated, max 50 znaków
        temp = [char(dbgMsgText) char(0)];
        dbgMsg.Payload.text = temp(1:min(length(temp),50));
        bytes_total = bytes_total + sendMsg(s, mavlink, dbgMsg);
        lastDBG = tNow;
    end

    % --- GENERIC_CAN_FRAME ---
    if tNow - lastCAN >= CAN_DT
        % Timestamp w ms od startu mockupu
        ms = floor(toc(tStart) * 1000);   
        canMsg.Payload.timestamp = uint32(ms);
        bytes_total = bytes_total + sendMsg(s, mavlink, canMsg);
        lastCAN = tNow;
    end

    % (opcjonalnie) log tylko gdy coś poszło
    if bytes_total > 0
        fprintf('\t sent: %f B\n', bytes_total); 
    end

    % aktualizacja sumy bajtów
    bytes_accum = bytes_accum + bytes_total;
    
    % co 1 s wyświetl prędkość i wyzeruj licznik
    if toc(tRateLast) >= 1.0
        bps = bytes_accum / toc(tRateLast);   %bajty/s
        fprintf('Tx rate: %.1f B/s\n', bps); %
        bytes_accum = 0;
        tRateLast = tic;
    end
end

%% Test commands?

info = msginfo(dialect, "DEBUG_FRAME")
info.Fields{:}
