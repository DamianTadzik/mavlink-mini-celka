clear
% Auto skaner dla modułów SiK telemetry
comPort = "COM17";  % <- ustaw swój port
baudRates = [57600, 115200, 38400, 19200, 9600];

found = false;

for b = baudRates
    fprintf("\n=== Testuje baud: %d ===\n", b);
    
    % Otwórz port
    s = serialport(comPort, b);
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
        pause(0.05);
    end
    fprintf("Odpowiedź: %s\n", resp);
    if contains(resp,"OK")
        fprintf(">>> Znalazlem modul SiK na %d baud!\n", b);
        found = true;
        
        configureTerminator(s,"CR/LF");
        flush(s);

        % Pobierz pełną konfigurację
        writeline(s,"ATI5");
        pause(1.2);
        
        configResp = "";
        while s.NumBytesAvailable > 0
            configResp = configResp + read(s, s.NumBytesAvailable, "char");
            pause(0.05);
        end
        
        disp(">>> Konfiguracja ATI5:");
        disp(configResp);
        
        break; % kończ skanowanie
    else
        disp("Brak odpowiedzi...");
    end
    
    clear s  % zamknij port zanim zmienisz baud
    pause(0.5);
end

if ~found
    disp("Nie znaleziono działającego baud rate w liście.");
end
%%
configureTerminator(s,"LF"); 
flush(s);

msg = "AT\r";    % Add carriage return
write(s, msg, 'char');
disp("Command:")
disp(msg)

pause(0.2);

resp = "";
while s.NumBytesAvailable > 0
    resp = resp + read(s, s.NumBytesAvailable, "char");
    pause(0.05);
end
disp("Response:")
disp(resp)
