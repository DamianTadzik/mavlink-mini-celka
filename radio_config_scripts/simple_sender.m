clear
% --- Konfiguracja nadajnika ---
comPort = "COM17";   % <- ustaw swój port USB
baudRate = 115200;    % typowa prędkość SiK

s = serialport(comPort, baudRate);

disp("Nadajnik gotowy. Wysyłam co 1 sek...");

for i = 1:100
    msg = sprintf("Hello %d", i);
    writeline(s, msg);
    fprintf("Wyslano: %s\n", msg);
    pause(1);  % 1 sekunda przerwy
end

clear s
disp("Zakonczono nadawanie.");
