clc
clear
poolobj = gcp('nocreate') % sprawdź czy jest aktywna pula
if ~isempty(poolobj)
    delete(poolobj) % usuń ją
end

pool = parpool('Threads',1); % teraz stwórz nową pulę
queue_to_worker = parallel.pool.PollableDataQueue(Destination="any");
queue_to_gui = parallel.pool.DataQueue;
afterEach(queue_to_gui, @(data) disp("Odebrano z workera: " + string(data)));

worker = parfeval(pool, @rx_worker, 0, queue_to_worker, queue_to_gui)
pause(1)
send(queue_to_worker, "test data")
pause(1)
send(queue_to_worker, "test data")
pause(4);
worker

cancel(worker);
delete(worker);
delete(pool);

%% test for this basic worker
% function rx_worker(queue_to_worker, queue_to_gui)
%     send(queue_to_gui, 'Worker started');
%     while true
%         data = poll(queue_to_worker, 3); % timeout 3s
%         if isempty(data)
%             send(queue_to_gui, "No data received in last 3 seconds");
%             continue
%         else
%             send(queue_to_gui, "Worker received: " + string(data));
%             send(queue_to_gui, "Response: " + string(data));
%         end
%     end
% end
