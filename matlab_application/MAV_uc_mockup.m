% MAV_uc_mockup.m
clear; clc;
dialect = mavlinkdialect("mavmc.xml")
mavlink = mavlinkio(dialect)

portName = 'COM18';
baudRate = 115200;
s = serialport(portName, baudRate);

pause(1.2);
disp("UC mockup running...");

mytext = "Test 123! ten tekst ma na pewno wiecej niz mozna miec";

%% Infinite loop
while true
    % HEARTBEAT
    hbMsg = createmsg(dialect, "HEARTBEAT");
    hbMsg.Payload.type = uint8(0);              % nc MAV_TYPE_GENERIC - 0
    hbMsg.Payload.autopilot = uint8(8);         % nc MAV_AUTOPILOT_INVALID - 8
    hbMsg.Payload.base_mode = uint8(0);         % nc
    hbMsg.Payload.system_status = uint8(0); % ? MAV_STATE_UNINIT - 0 
    hbMsg.Payload.custom_mode = uint32(0);  % ? 
    % hbMsg.Payload.mavlink_version = uint8(3); % not writable by user
    
    hbMsg.SystemID = uint8(1);    % nc
    hbMsg.ComponentID = uint8(1); % nc

    buffer = serializemsg(mavlink, hbMsg);
    write(s, buffer, "uint8");

    % DEBUG_FRAME
    dbgMsg = createmsg(dialect, "DEBUG_FRAME");
    dbgMsg.Payload.status = uint8(randi(255));
    temp = [char(mytext) char(0)];
    dbgMsg.Payload.text = temp(1:min(length(temp),50));

    hbMsg.SystemID = uint8(1);    % nc
    hbMsg.ComponentID = uint8(1); % nc
   
    buffer = serializemsg(mavlink, dbgMsg);
    write(s, buffer, "uint8");

    disp("Sent HEARTBEAT and DEBUG_FRAME");
    pause(1);
end

%% Test commands?

info = msginfo(dialect, "DEBUG_FRAME")
info.Fields{:}