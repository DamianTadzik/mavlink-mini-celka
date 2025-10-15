function worker(queue_to_worker, queue_to_gui, queue_debug)
try
    global global_queue_debug; %#ok
    global_queue_debug = queue_debug;
    log_message("Entered the worker function.");

    try 
        mavmc_deserializer_mex("reset"); 
    catch ME
        log_exception("Error reseting mex deserializer.", ME);
    end

    % ==== RAW logging init ====
    RAW_STEP = 2048;  % krok prealokacji
    RAW_FLUSH_THRESHOLD = 8192; % flush po tylu ramek
    RAW_LOG_INTERVAL = 10; % flush co 10 sekunda
    
    log_ts  = datestr(now,'yyyymmdd_HHMMSS');
    raw_file = fullfile(tempdir, "log_raw_" + log_ts + ".mat");
    raw = matfile(raw_file, 'Writable', true);
    raw.raw_count     = uint64(0);
    raw.raw_timestamp = uint32([]); % Nx1
    raw.raw_id        = uint16([]); % Nx1
    raw.raw_data      = uint8([]);  % Nx8
    log_message("Logging to: " + string(raw_file))
    
    % Bufor w pamięci
    raw_cap = RAW_STEP;
    raw_len = 0;
    raw_timestamp = zeros(raw_cap,1,'uint32');
    raw_id        = zeros(raw_cap,1,'uint16');
    raw_data      = zeros(raw_cap,8,'uint8');
    
    last_flush = tic;

    % ==== TELEMETRY init ====
    TELEM_INTERVAL = 5;           % co ile raport (s)
    telem_t0 = tic;                  % znacznik okresu
    telem = struct( ...
        'chunks', 0, ...         % ile chunków przetworzono
        'msgs',   0, ...         % ile mav_msgs (sumarycznie elementów)
        'raw_in', 0, ...         % ile raw ramek dodano do bufora
        'flushes',0, ...         % ile flushy wykonano w okresie
        'mex_time', 0.0, ...     % suma czasu MEX w okresie
        'decode_time', 0.0, ...  % suma czasu cmmc_database_decoder w okresie
        'decode_calls', 0, ...   % liczba udanych wywołań dekodera
        'total_len', 0, ...       % total lines saved 
        'busy_time', 0.0 ...   % czas sumarycznie zajęty w okresie
    );

catch ME
    log_exception("Something happend before loop, returning.", ME);
    return;
end
% Helper: powiększ bufor przy potrzebie
function ensure_raw_capacity(n_add)
    if raw_len + n_add <= raw_cap, return; end
    new_cap = raw_cap;
    while raw_len + n_add > new_cap
        new_cap = new_cap * 2;
    end
    raw_timestamp(new_cap,1) = uint32(0);
    raw_id(new_cap,1)        = uint16(0);
    raw_data(new_cap,8)      = uint8(0);
    raw_cap = new_cap;
end
log_message("Entered the loop in the worker function.");
while true
try
    % Poll, check if there is any new data to be processed
    [chunk, ok] = poll(queue_to_worker, 0.05);

     % If no data is recieved into the chunk skip the rest of the loop
    if ~ok
        continue;
    end

    % Start the busy time measurement
    busy_t0 = tic;

    % The chunk must be uint8 because we are not sending anything else
    % Process the chunk then
    try 
        t_mex = tic;
        mav_msgs = mavmc_deserializer_mex(chunk);
        telem.mex_time = telem.mex_time + toc(t_mex);
        telem.chunks = telem.chunks + 1;
    catch ME
        % Some exception occured we do not proceed with the loop
        log_message("Unexpected error with mavmc_deserializer_mex.");
        rethrow(ME);
    end

    % If there are any MAVLink messages deserialized
    if ~isempty(mav_msgs)
        telem.msgs = telem.msgs + numel(mav_msgs);
        % Iterate over all deserialized messages in order to find CAN frames
        for i = 1:numel(mav_msgs)
            mav_msg = mav_msgs{i};
                
            % If this mav_msg is carrying encoded can_msg inside
            if mav_msg.msgid == 200
                % APPEND TO raw.mat can occur here
                % mav_msg.id      <- uint16
                % mav_msg.data    <- uint8[8]
                % mav_msg.timestamp <- uint32
                ensure_raw_capacity(1);
                raw_len = raw_len + 1;
                raw_timestamp(raw_len,1) = uint32(mav_msg.timestamp);
                raw_id(raw_len,1)        = uint16(mav_msg.id);
                raw_data(raw_len,1:8)    = reshape(uint8(mav_msg.data),1,8);
                telem.raw_in = telem.raw_in + 1;

                % Try to decode the can message with decoder from database
                try
                    t_dec = tic;
                    can_msg = cmmc_database_decoder(uint32(mav_msg.id), uint8(mav_msg.data));
                    telem.decode_time  = telem.decode_time + toc(t_dec);
                    telem.decode_calls = telem.decode_calls + 1;
                catch ME
                    % Some exception occured we do not proceed with
                    % appending the decoded results to mav_msg
                    log_message("Unexpected error with cmmc_database_decoder.");
                    continue; % Skip this for-loop iteration
                    % Maybe generic results can be appended anyway if
                    % needed by GUI
                end
                % Append decoded can_msg to the mav_msg
                mav_msg.decoded = can_msg;
                mav_msg = rmfield(mav_msg, {'id','data'});
                % Replace the original struct with extended one
                mav_msgs{i} = mav_msg;
            end 
        end
        % Send back all those msgs to gui over queue
        send(queue_to_gui, mav_msgs);
    end
catch ME
    log_exception("Something happend inside the loop.", ME);
end %exception
try
    % --- Periodic RAW flush ---
    if (raw_len >= RAW_FLUSH_THRESHOLD) || ...
       (toc(last_flush) >= RAW_LOG_INTERVAL && raw_len > 0)
        try
            k0 = double(raw.raw_count);
            raw.raw_timestamp(k0+1:k0+raw_len,1) = raw_timestamp(1:raw_len);
            raw.raw_id(       k0+1:k0+raw_len,1) = raw_id(1:raw_len);
            raw.raw_data(     k0+1:k0+raw_len,1:8) = raw_data(1:raw_len,1:8);
            raw.raw_count = uint64(k0 + raw_len);
            telem.flushes = telem.flushes + 1;
            telem.total_len = telem.total_len + raw_len;
            log_message(string(sprintf("flush_raw %d frames", raw_len)))
            raw_len = 0;
        catch ME
            log_exception("RAW flush error:", ME);
        end
        last_flush = tic;
    end
catch ME
    log_exception("Something happend during flushing.", ME);
end %exception
try
    telem.busy_time = telem.busy_time + toc(busy_t0);
    if toc(telem_t0) >= TELEM_INTERVAL
        dt = toc(telem_t0);
        log_telemetry(telem, dt);
        % zerowanie okresu
        telem.chunks = 0;
        telem.msgs = 0;
        telem.raw_in = 0;
        telem.flushes = 0;
        telem.mex_time = 0.0;
        telem.decode_time = 0.0;
        telem.decode_calls = 0;
        telem.busy_time = 0.0;
        telem_t0 = tic;
    end
catch ME
    log_exception("Something happend during telemetry send.", ME)
end %exception
end %while
end %function

%% All telemetry and status reporting functions throught queue_debug defined here
function log_exception(msg, ME)
    global global_queue_debug; %#ok
    msg = string(msg);
    send(global_queue_debug, "EXCEPTION " + msg + ME.message);
    if ~isempty(ME.stack)
        fileName = ME.stack(1).file;
        lineNum  = ME.stack(1).line;
        funcName = ME.stack(1).name;
        send(global_queue_debug, ...
             sprintf('\tError in file: %s\n\tIn function: %s\n\tLine: %d', ...
                     fileName, funcName, lineNum));
    end
end
function log_message(msg)
    global global_queue_debug; %#ok
    send(global_queue_debug, "MESSAGE " + string(msg));
end
function log_telemetry(telem, dt)
    global global_queue_debug; %#ok
    chunks_rate       = telem.chunks / dt;
    msgs_rate         = telem.msgs   / dt;
    mex_ms_per_chunk  = 1000.0 * (telem.mex_time   / max(telem.chunks,1));
    dec_ms_per_call   = 1000.0 * (telem.decode_time / max(telem.decode_calls,1));
    busy_pct          = 100.0 * (telem.busy_time / dt);

    msg = sprintf(['TELEMETRY chunks=%.1f/s msgs=%.1f/s ', ...
                   'total_len=%u flush=%u mex=%.2fms/chunk dec=%.2fms/call ', ...
                   'busy=%.1f%%'], ...
                   chunks_rate, msgs_rate, telem.total_len, ...
                   uint32(telem.flushes), mex_ms_per_chunk, dec_ms_per_call, ...
                   busy_pct);
    send(global_queue_debug, msg);
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
