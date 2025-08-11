% MAV_base_station.m
clear; clc;
dialect = mavlinkdialect("mavmc.xml")
mavlink = mavlinkio(dialect)

portName = 'COM17';
baudRate = 115200;
s = serialport(portName, baudRate);

pause(1.2);
disp("Base station listening...");

% Timer do wysyłania heartbeat
heartbeatTimer = tic;

%% Infinite loop
while true
    if toc(heartbeatTimer) >= 1
        hbMsg = createmsg(dialect, "HEARTBEAT");
        hbMsg.Payload.type = uint8(6);              % nc MAV_TYPE_GCS - 6
        hbMsg.Payload.autopilot = uint8(8);         % nc MAV_AUTOPILOT_INVALID - 8
        hbMsg.Payload.base_mode = uint8(0);         % nc
        hbMsg.Payload.system_status = uint8(0); % ? MAV_STATE_UNINIT - 0 
        hbMsg.Payload.custom_mode = uint32(0);  % ? 
        % hbMsg.Payload.mavlink_version = uint8(3); % not writable by user

        hbMsg.SystemID = uint8(255);    % nc
        hbMsg.ComponentID = uint8(190); % nc

        buffer = serializemsg(mavlink, hbMsg);
        write(s, buffer, "uint8");
        heartbeatTimer = tic;
    end

    if s.NumBytesAvailable > 0
        data = read(s, s.NumBytesAvailable, "uint8");
        
        buffer = uint8(data);
        
        [msg, status] = deserializemsg(dialect, buffer);
        bytes
        for m = 1:numel(msg)
            disp(status)
            if status(m) == 0
   
                disp(msg(m).Payload)
            end
        end
    end
    pause(0.05);
end


%%
readTimer = timer('ExecutionMode', 'fixedSpacing', ...
                  'Period', 0.02, ...
                  'TimerFcn', @(~,~) ProcessBuffer(s));

function ProcessBuffer(s)
    if s.NumBytesAvailable > 0
        data = read(s, s.NumBytesAvailable, "uint8");
        
        buffer = uint8(data);

        bytes_per_sec = length(buffer) / 0.02;
        disp(bytes_per_sec)
    else
        disp('0')
    end
end


start(readTimer)
    
pause(10);
    
stop(readTimer)
delete(readTimer)
