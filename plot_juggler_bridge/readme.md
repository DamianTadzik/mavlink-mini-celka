# Workflow z telemetrią

1. Activate the virtual env

source venv/Scripts/activate


2. Run the telemetry bridge

python plot_juggler_bridge/telemetry_bridge.py \
--dbc D:/Dane/workspace/can-messages-mini-celka/can_messages_mini_celka.dbc

--serial-port COM17 

3. Run the PlotJuggler

plotjuggler

4. Start the udp server with default settings and the msg pack protocol

5. enjoy


