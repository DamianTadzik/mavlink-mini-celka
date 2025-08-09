clear
% --- Konfiguracja odbiornika ---
comPort = "COM19";   % <- ustaw drugi moduł
baudRate = 115200;

s = serialport(comPort, baudRate);
configureTerminator(s,"LF");  % kończymy linie znakiem LF

disp("Odbiornik nasłuchuje...");

for i = 1:100
    if s.NumBytesAvailable > 0
        msg = readline(s);
        fprintf("Odebrano: %s\n", msg);
    end
    pause(0.1);
end

clear s
disp("Zakonczono odbiór.");
