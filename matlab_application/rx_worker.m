function rx_worker(queue_to_worker, queue_to_gui, queue_debug)
send(queue_debug, "started");

try 
    mavmc_deserializer_mex("reset"); 
catch ME
    send(queue_debug, "Error reseting mex deserializer: " + ME.message);
end

% ==== TELEMETRIA ====
TELEMETRY_INTERVAL = 0.5;  % co ile sek. raport
tele = struct( ...
    't0', tic, ...
    'last_report', tic, ...
    'idle_time', 0.0, ...
    'busy_time', 0.0, ...
    'loops', uint64(0), ...
    'chunks', uint64(0), ...
    'msgs', uint64(0), ...
    'raw_appended', uint64(0), ...
    'dec_appended', uint64(0), ...
    'flushes', uint64(0), ...
    't_mex', 0.0, ...
    't_decode', 0.0, ...
    't_flush', 0.0);

% helper do wysyłania raportu (string) i zerowania liczników „od ostatniego raportu"
function telemetry_send()
    dt = toc(tele.last_report);
    work = tele.busy_time; idle = tele.idle_time;
    util = 100.0 * work / max(work+idle, eps);
    chunks_rate = double(tele.chunks) / max(dt, eps);
    msgs_rate   = double(tele.msgs)   / max(dt, eps);

    % średnie czasy na iterację (ms)
    ms_mex    = 1000.0 * tele.t_mex   / max(double(tele.chunks), 1);
    ms_decode = 1000.0 * tele.t_decode/ max(double(tele.chunks), 1);
    ms_flush  = 1000.0 * tele.t_flush / max(double(tele.flushes), 1);

    msg = sprintf(['@@telemetry util=%.1f%% chunks=%.1f/s msgs=%.0f/s ', ...
                   'raw_buf=%u dec_buf=%u flush=%u ', ...
                   'mex=%.2fms decode=%.2fms flush=%.2fms'],
                   util, chunks_rate; msgs_rate, ...
                   uint32(raw_len), uint32(dec_len), uint32(tele.flushes), ...
                   ms_mex, ms_decode, ms_flush);

    send(queue_debug, msg);

    % wyzeruj liczniki „delta"
    tele.last_report = tic;
    tele.idle_time = 0.0; tele.busy_time = 0.0;
    tele.chunks = uint64(0); tele.msgs = uint64(0);
    tele.raw_appended = uint64(0); tele.dec_appended = uint64(0);
    tele.flushes = uint64(0);
    tele.t_mex = 0.0; tele.t_decode = 0.0; tele.t_flush = 0.0;
end


log_ts = datestr(now,'yyyymmdd_HHMMSS');
raw_file = fullfile(tempdir, "log_raw_"     + log_ts + ".mat");
dec_file = fullfile(tempdir, "log_decoded_" + log_ts + ".mat");

raw = matfile(raw_file, 'Writable', true);
dec = matfile(dec_file, 'Writable', true);

% Liczniki i puste zmienne (kolumnowe)
raw.raw_count = uint64(0);
raw.raw_timestamp   = uint32([]);      % Nx1
raw.raw_id          = uint16([]);      % Nx1
raw.raw_data        = uint8([]);       % Nx8

dec.dec_count       = uint64(0);
dec.dec_timestamp   = uint32([]);     % Mx1
dec.dec_frame       = cell(0,1);      % Mx1 cellstr
dec.dec_signal      = cell(0,1);      % Mx1 cellstr
dec.dec_value       = double([]);     % Mx1

send(queue_debug, "Raw logging to: " + raw_file);
send(queue_debug, "Decoded logging to: " + dec_file);

% Raw buffers (PREALLOC with capacity-doubling)
RAW_STEP = 2048; DEC_STEP = 4096;   % dobra startowa pojemność; potem ×2
raw_cap = RAW_STEP;  dec_cap = DEC_STEP;

raw_timestamp = zeros(raw_cap,1,'uint32');
raw_id        = zeros(raw_cap,1,'uint16');
raw_data      = zeros(raw_cap,8,'uint8');
raw_len = 0;

dec_timestamp = zeros(dec_cap,1,'uint32');
dec_frame     = cell(dec_cap,1);
dec_signal    = cell(dec_cap,1);
dec_value     = zeros(dec_cap,1,'double');
dec_len = 0;

log_interval = 1.0; 
RAW_FLUSH_THRESHOLD = 4096;
DEC_FLUSH_THRESHOLD = 8192;
last_flush = tic;

% capacity-doubling
function ensure_raw_capacity(n_add)
    if raw_len + n_add > raw_cap
        new_cap = raw_cap;
        while raw_len + n_add > new_cap
            new_cap = new_cap * 2;
        end
        % realokacje „na miejscu"
        raw_timestamp(new_cap,1) = uint32(0);
        raw_id(new_cap,1)        = uint16(0);
        raw_data(new_cap,8)      = uint8(0);
        raw_cap = new_cap;
    end
end

function ensure_dec_capacity(n_add)
    if dec_len + n_add > dec_cap
        new_cap = dec_cap;
        while dec_len + n_add > new_cap
            new_cap = new_cap * 2;
        end
        dec_timestamp(new_cap,1) = uint32(0);
        dec_value(new_cap,1)     = double(0);
        dec_frame{new_cap,1}     = [];
        dec_signal{new_cap,1}    = [];
        dec_cap = new_cap;
    end
end

function flush_all()
    tf = tic;
    try
        raw_count = raw_len;
        dec_count = dec_len;

        if raw_count > 0
            k0 = double(raw.raw_count);
            raw.raw_timestamp(k0+1:k0+raw_count,1) = raw_timestamp(1:raw_count);
            raw.raw_id(       k0+1:k0+raw_count,1) = raw_id(1:raw_count);
            raw.raw_data(     k0+1:k0+raw_count,1:8) = raw_data(1:raw_count,1:8);
            raw.raw_count = uint64(k0 + raw_count);
            raw_len = 0;
        end

        if dec_count > 0
            k0 = double(dec.dec_count);
            dec.dec_timestamp(k0+1:k0+dec_count,1) = dec_timestamp(1:dec_count);
            dec.dec_frame(    k0+1:k0+dec_count,1) = dec_frame(1:dec_count);
            dec.dec_signal(   k0+1:k0+dec_count,1) = dec_signal(1:dec_count);
            dec.dec_value(    k0+1:k0+dec_count,1) = dec_value(1:dec_count);
            dec.dec_count = uint64(k0 + dec_count);
            dec_len = 0;
        end

        send(queue_debug, sprintf('@@flush_all done: %d raw frames and %d decoded signals written', raw_count, dec_count));
    catch MEf
        send(queue_debug, "flush_all error: " + MEf.message);
    end
    tele.t_flush = tele.t_flush + toc(tf);
    tele.flushes = tele.flushes + 1;
end

while true
    t_wait = tic;
    [chunk, ok] = poll(queue_to_worker, 0.05);
    waited = toc(t_wait);
    
    if ~ok
        tele.idle_time = tele.idle_time + waited;
        tele.loops = tele.loops + 1;
        % okresowo raportuj nawet gdy nic nie robimy
        if toc(tele.last_report) >= TELEMETRY_INTERVAL
            telemetry_send();
        end
        continue;
    end

    if ~isa(chunk,'uint8') && ( ...
        (ischar(chunk)   && strcmp(chunk,'__SHUTDOWN__')) || ...
        (isstring(chunk) && chunk=="__SHUTDOWN__")        || ...
        (isstruct(chunk) && isfield(chunk,'cmd') && strcmp(chunk.cmd,'shutdown')) )
        
        send(queue_debug, "shutdown signal received, flushing");
        flush_all();
        send(queue_debug, "Raw log saved: " + raw_file);
        send(queue_debug, "Decoded log saved: " + dec_file);
        send(queue_debug, "shutdown signal received, returning");
        return;   % clean exit
    end

    t_busy = tic;
    tele.chunks = tele.chunks + 1;
    try
        t_mex = tic;
        msgs = mavmc_deserializer_mex(chunk);
        tele.t_mex = tele.t_mex + toc(t_mex);
        if ~isempty(msgs)
            tele.msgs = tele.msgs + uint64(numel(msgs));
            for i = 1:numel(msgs)
                s = msgs{i};
                % Dekodowanie CAN (msgid=200) i doklejanie 'decoded' 
                if isstruct(s) && isfield(s,'msgid') && s.msgid == 200
                    try
                        % Try to decode
                        decoded = cmmc_database_decoder(uint32(s.id), uint8(s.data));
                        % Extend the structure
                        s.decoded = decoded;
                        % Replace the original structure with extended one
                        msgs{i} = s;

                        try
                            % ===== OPTIMAL BATCH-APPEND DLA DECODED =====
                            % Wyciągnij listę nazw pól (sygnałów) i odpowiadające wartości RAZ na ramkę
                            sig_names = fieldnames(decoded.signals);     % 1x na ramkę (konieczne u Ciebie)
                            sig_vals  = struct2cell(decoded.signals);    % wartości w tej samej kolejności co sig_names
                            
                            n_add = numel(sig_names);
                            tele.dec_appended = tele.dec_appended + uint64(n_add);

                            if n_add > 0
                                ensure_dec_capacity(n_add);

                                % zakres docelowy w buforze
                                idx0 = dec_len + 1;
                                idx1 = dec_len + n_add;
                            
                                % stałe dla tej ramki
                                t    = uint32(s.timestamp);
                                fstr = decoded.frame;  % nie konwertuj na char, trzymaj bezpośrednio
                            
                                % WRZUCAMY HURTEM (bez pętli po 1 elemencie):
                                dec_timestamp(idx0:idx1, 1) = t;                    % jeden timestamp do całego zakresu
                                dec_frame(    idx0:idx1, 1) = {fstr};               % powielenie nazwy ramki
                                dec_signal(   idx0:idx1, 1) = sig_names;            % bez char(), zostaje cellstr
                                % zamień wartości na double wektorem i wstaw hurtem
                                dec_value(    idx0:idx1, 1) = cellfun(@double, sig_vals);
                            
                                % zaktualizuj długość
                                dec_len = idx1;
                            end

                        catch ME
                            debug(queue_debug, "decoded logging error: ", ME);
                        end
                    catch ME
                        debug(queue_debug, "cmmc_database_decoder error: ", ME);
                    end
     
                    ensure_raw_capacity(1);
                    raw_len = raw_len + 1;
                    raw_timestamp(raw_len,1) = uint32(s.timestamp);
                    raw_id(raw_len,1)        = uint16(s.id);
                    raw_data(raw_len,1:8)    = reshape(uint8(s.data),1,8);

                    tele.raw_appended = tele.raw_appended + uint64(1);
                end
            end
            % Zwrócenie struktury do gui
            send(queue_to_gui, msgs);
        end
    catch ME
        send(queue_debug, "MEX error: " + ME.message);
    end

    % ==== [ADD] stop pomiaru busy + okresowy raport ====
    tele.busy_time = tele.busy_time + toc(t_busy);
    
    if toc(tele.last_report) >= TELEMETRY_INTERVAL
        telemetry_send();
    end

    if (toc(last_flush) >= log_interval) && (raw_len > 0 || dec_len > 0)
        flush_all(); last_flush = tic;
    end


end
end

function debug(queue_debug, msg, ME)
    msg = string(msg);
    send(queue_debug, msg + ME.message);

    % Szczegóły lokalizacji
    if ~isempty(ME.stack)
        fileName = ME.stack(1).file;
        lineNum  = ME.stack(1).line;
        funcName = ME.stack(1).name;
        send(queue_debug, sprintf('\tError in file: %s\n\tIn function: %s\n\tLine: %d', ...
                                   fileName, funcName, lineNum));
    end
end

%% Struktury zwracane przez mavmc_deserializer_mex
% s =
%   struct with fields:
%     name:            'HEARTBEAT'
%     msgid:           0
%     seq:             <uint8>   % licznik sekwencji
%     sysid:           <uint8>   % ID systemu
%     compid:          <uint8>   % ID komponentu
%     type:            <double>  % MAV_TYPE_*
%     autopilot:       <double>  % MAV_AUTOPILOT_*
%     base_mode:       <double>  % tryb bazowy (bitmask)
%     custom_mode:     <double>  % tryb niestandardowy (uint32)
%     system_status:   <double>  % MAV_STATE_*
%     mavlink_version: <double>  % zwykle 3
% 
% s =
%   struct with fields:
%     name:     'RADIO_STATUS'
%     msgid:    109
%     seq:      <uint8>
%     sysid:    <uint8>
%     compid:   <uint8>
%     rssi:     <double>  % lokalny RSSI
%     remrssi:  <double>  % zdalny RSSI
%     txbuf:    <double>  % % wolnego TX bufora
%     noise:    <double>  % lokalny szum
%     remnoise: <double>  % zdalny szum
%     rxerrors: <double>  % błędy RX
%     fixed:    <double>  % liczba naprawionych pakietów
% 
% s =
%   struct with fields:
%     name:      'GENERIC_CAN_FRAME'
%     msgid:     200
%     seq:       <uint8>
%     sysid:     <uint8>
%     compid:    <uint8>
%     timestamp: <double>   % uint32 w ms
%     id:        <double>   % uint16 (ID ramki CAN)
%     data:      [1×8 uint8] % payload CAN
% 
% s =
%   struct with fields:
%     name:    'DEBUG_FRAME'
%     msgid:   201
%     seq:     <uint8>
%     sysid:   <uint8>
%     compid:  <uint8>
%     status:  <double>    % uint8 (kod statusu)
%     text:    '...'       % string (max 50 znaków, ucięty przy NUL)

%% Struktury zwracane przez _database_decoder
% decoded = 
%   struct with fields:
%       frame: 'SERVO_POSITION'       % Frame name
%     signals: [1×1 struct]           % Signals in the frame structure
% 
% decoded.signals = 
%   struct with fields:
%        SETPOINT: 0                    % Field with value
%         ADC_RAW: 256                  % Field with value
%     ADC_VOLTAGE: 3.3686e+04           % Field with value


%% Todo numero uno
% wysłać mavlinka z minicelki na osobnym branchu zeby nie stracic roboty z
% czujnikeim i serwem
% 1. podłączyć radio do canloggera
% 2. skonfigurować canloggera
% 3. napisać kod mavlink send
% % Poprawić zapis na karte sd (dwa bufory kurwamac)
%% DOS
% 1. jak mablink bedzie dzialal to essa testowanie
% 2. bufory kolowe


