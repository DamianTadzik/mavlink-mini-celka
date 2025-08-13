function rx_worker(queue_to_worker, queue_to_gui, queue_debug)
send(queue_debug, "started");

try 
    mavmc_deserializer_mex("reset"); 
catch ME
    send(queue_debug, "Error reseting mex deserializer: " + ME.message);
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

% Raw buffers
raw_timestamp   = uint32([]);
raw_id          = uint16([]);
raw_data        = uint8([]);   % Nx8

% Decoded buffers
dec_timestamp   = uint32([]);
dec_frame       = {};
dec_signal      = {};
dec_value       = double([]);

log_interval = 2; last_flush = tic;

function flush_all()
    try
        raw_count = size(raw_timestamp, 1);
        dec_count = size(dec_timestamp, 1);

        if raw_count > 0
            k0 = double(raw.raw_count);
            n  = size(raw_timestamp,1);
            raw.raw_timestamp(k0+1:k0+n,1) = raw_timestamp;
            raw.raw_id(       k0+1:k0+n,1) = raw_id;
            raw.raw_data(     k0+1:k0+n,1:8) = raw_data;
            raw.raw_count = uint64(k0 + n);
            raw_timestamp = uint32([]); raw_id = uint16([]); raw_data = uint8([]);
        end
        if dec_count > 0
            k0 = double(dec.dec_count);
            m  = size(dec_timestamp,1);
            dec.dec_timestamp(k0+1:k0+m,1) = dec_timestamp;
            dec.dec_frame(    k0+1:k0+m,1) = dec_frame;
            dec.dec_signal(   k0+1:k0+m,1) = dec_signal;
            dec.dec_value(    k0+1:k0+m,1) = dec_value;
            dec.dec_count = uint64(k0 + m);
            dec_timestamp = uint32([]); dec_frame = {}; dec_signal = {}; dec_value = double([]);
        end
        send(queue_debug, sprintf("flush_all done: %d raw frames and %d decoded signals written", raw_count, dec_count));
    catch MEf
        send(queue_debug, "flush_all error: " + MEf.message);
    end
end

while true
    [chunk, ok] = poll(queue_to_worker, 0.05);
    if ~ok
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

    try
        msgs = mavmc_deserializer_mex(chunk);
        if ~isempty(msgs)
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
                            signals = fieldnames(decoded.signals);
                            for n_of_signals = 1:numel(signals)
                                signal = signals{n_of_signals};
                                dec_timestamp(end+1,1) = uint32(s.timestamp);
                                dec_frame{end+1,1}     = char(decoded.frame);
                                dec_signal{end+1,1}    = char(signal);
                                dec_value(end+1,1)     = double(decoded.signals.(signal));
                            end
                        catch ME
                            debug(queue_debug, "decoded logging error: ", ME);
                        end
                    catch ME
                        debug(queue_debug, "cmmc_database_decoder error: ", ME);
                    end
     
                    % RAW zawsze
                    raw_timestamp(end+1,1)  = uint32(s.timestamp);
                    raw_id(end+1,1)         = uint16(s.id);
                    raw_data(end+1,1:8)     = reshape(uint8(s.data),1,8);
                end
            end
            % Zwrócenie struktury do gui
            send(queue_to_gui, msgs);
        end
    catch ME
        send(queue_debug, "MEX error: " + ME.message);
    end

    if toc(last_flush) >= log_interval && (~isempty(raw_timestamp) || ~isempty(dec_timestamp))
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

%% wnioski
% moj dekoder w mexie jest stworzony pod konkretnego database'a 
% gdzie w takim razie przechowywac tablice rozkodowanych wartosci i jak sobie z tym efektywnie radzić?
% Czy rozkodowane wartości dynamicznie mam przechowywać w matalbie czy
% jakoś je zapisywać? hmmm nie wiem xd na pewno któreś sygnały z magistrali
% będę czasem chciał plotować ale to po ich nagraniu, offline... ale na
% żywo też czasami
%
% Dobra zapisujemy dane z poziomu workera do matów i essa a na gui bufory
% kołowe do wyświetlania rameczek i jakieś strukturki do wyboru co
% wyświetlamy xd a na 

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


