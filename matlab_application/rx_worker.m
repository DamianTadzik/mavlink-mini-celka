function rx_worker(queue_to_worker, queue_to_gui)
    while true
        data = poll(queue_to_worker, inf); 
        
        % Utwórz opis typu i rozmiaru
        text = sprintf("Type: %s, Size: [%s]", ...
            class(data), num2str(size(data)));
    
        send(queue_to_gui, text);
    end
end
