function rx_worker(queue_to_worker, queue_to_gui, queue_debug)
send(queue_debug, "started");

try 
    mavmc_deserializer_mex("reset"); 
catch ME
    send(queue_debug, "Error reseting mex: " + ME.message);
end

while true
    [chunk, ok] = poll(queue_to_worker, 0.05);
    if ~ok
        continue;
    end
    try
        msgs = mavmc_deserializer_mex(chunk);
        if ~isempty(msgs)
            % send(queue_debug, length(msgs));
            send(queue_to_gui, msgs);
        end
    catch ME
        send(queue_debug, "MEX error: " + ME.message);
    end
end
end
