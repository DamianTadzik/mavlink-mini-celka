function rx_worker(s)

    while true
        pause(0.02); % 20 ms
        if s.NumBytesAvailable > 0
            data = read(s, s.NumBytesAvailable, 'uint8');
            % Parsuj MAVLink, zapisz dane do DataQueue
            buffer = uint8(data);
                
            bytes_per_sec = length(buffer) / 0.02;
            disp(bytes_per_sec)
        end
    end
end