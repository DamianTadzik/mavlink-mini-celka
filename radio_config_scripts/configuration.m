clc
clear
s = [];
%% Open port and enter the AT (or RT) mode
comPort = "COM17";  % <- ustaw swój port
baudRate = 115200;

% Otwórz port
if isempty(s)
    s = serialport(comPort, baudRate);
end
configureTerminator(s,"LF"); 
flush(s);

% Musi być cisza na linii przez ~1s
pause(1.2);

% Wyślij '+++'
write(s, '+++', 'char');

% Czekaj chwilę na odpowiedź
pause(1.2);

% Odczytaj dane
resp = "";
while s.NumBytesAvailable > 0
    resp = resp + read(s, s.NumBytesAvailable, "char");
    pause(0.2);
end
fprintf("%s\n", resp);

if contains(resp, "OK")
    configureTerminator(s,"CR/LF");
    s.Timeout = 2;
    flush(s);
    pause(0.2);
else
    fprintf("Could not enter the AT (or RT) mode at %s\n", comPort);
    clear s
    return
end

%% Select the device AT - this or RT - remote 
device = "AT";
% device = "RT";

%% Write the ATI commands and listen to the responses

% ATI - show radio version
msg = device + "I";
writeline(s, msg);
fprintf(">%s\n", msg);
pause(0.2);
resp = "";
while s.NumBytesAvailable > 0
    resp = resp + read(s, s.NumBytesAvailable, "char");
    pause(0.2);
end
fprintf("<%s\n", resp);
pause(1.2);

% ATI2 - show board type
msg = device + "I2";
writeline(s, msg);
fprintf(">%s\n", msg);
pause(0.2);
resp = "";
while s.NumBytesAvailable > 0
    resp = resp + read(s, s.NumBytesAvailable, "char");
    pause(0.2);
end
fprintf("<%s\n", resp);
pause(1.2);

% ATI3 - show board frequency
msg = device + "I3";
writeline(s, msg);
fprintf(">%s\n", msg);
pause(0.2);
resp = "";
while s.NumBytesAvailable > 0
    resp = resp + read(s, s.NumBytesAvailable, "char");
    pause(0.2);
end
fprintf("<%s\n", resp);
pause(1.2);

% ATI4 - show board version
msg = device + "I4";
writeline(s, msg);
fprintf(">%s\n", msg);
pause(0.2);
resp = "";
while s.NumBytesAvailable > 0
    resp = resp + read(s, s.NumBytesAvailable, "char");
    pause(0.2);
end
fprintf("<%s\n", resp);
pause(1.2);

% ATI5 - show board version
msg = device + "I5";
writeline(s, msg);
fprintf(">%s\n", msg);
pause(0.2);
resp = "";
while s.NumBytesAvailable > 0
    resp = resp + read(s, s.NumBytesAvailable, "char");
    pause(0.2);
end
fprintf("<%s\n", resp);
pause(1.2);

return

%% Write ATI6 ATI7 command and listen to the response

% ATI6 - display TDM timing report
msg = device + "I6";
writeline(s, msg);
fprintf(">%s\n", msg);
pause(0.2);
resp = "";
while s.NumBytesAvailable > 0
    resp = resp + read(s, s.NumBytesAvailable, "char");
    pause(0.2);
end
fprintf("<%s\n", resp);
pause(1.2);

% ATI7 - display RSSI signal report
msg = device + "I7";
writeline(s, msg);
fprintf(">%s\n", msg);
pause(0.2);
resp = "";
while s.NumBytesAvailable > 0
    resp = resp + read(s, s.NumBytesAvailable, "char");
    pause(0.2);
end
fprintf("<%s\n", resp);
pause(1.2);

return

%% Write the ATS4=2 command and listen to the response
% ATSn=X - set radio parameter number 'n' to 'X'
msg = device + "S4=2";
writeline(s, msg);
fprintf(">%s\n", msg);
pause(0.2);
resp = "";
while s.NumBytesAvailable > 0
    resp = resp + read(s, s.NumBytesAvailable, "char");
    pause(0.2);
end
fprintf("<%s\n", resp);
pause(1.2);

%% Write the AT&W command and listen to the response
% AT&W - write current parameters to EEPROM
msg = device + "&W";
writeline(s, msg);
fprintf(">%s\n", msg);
pause(0.2);
resp = "";
while s.NumBytesAvailable > 0
    resp = resp + read(s, s.NumBytesAvailable, "char");
    pause(0.2);
end
fprintf("<%s\n", resp);
pause(1.2);

%% Write the ATZ command and listen to the response
% ATZ - reboot the radio
msg = device + "Z";
writeline(s, msg);
fprintf(">%s\n", msg);
pause(0.2);
resp = "";
while s.NumBytesAvailable > 0
    resp = resp + read(s, s.NumBytesAvailable, "char");
    pause(0.2);
end
fprintf("<%s\n", resp);
pause(1.2);

return
