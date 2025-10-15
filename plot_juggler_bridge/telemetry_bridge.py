#!/usr/bin/env python3
"""
Telemetry bridge: UART → MAVLink (custom dialect) → CAN decode → MsgPack UDP
"""

import serial
import socket
import msgpack
import time
import mavmc_dialect as mavlink
from pymavlink import mavutil
import cantools


# === CONFIG ===
SERIAL_PORT = "COM17"
BAUDRATE = 115200
UDP_ADDR = ("127.0.0.1", 9870)
SEND_PERIOD = 0.02
DBC_PATH = r"D:\Dane\workspace\can-messages-mini-celka\can_messages_mini_celka.dbc"
# ==============

dbc = cantools.database.load_file(DBC_PATH)
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
ser = serial.Serial(SERIAL_PORT, BAUDRATE, timeout=0.01)

# Create MAVLink parser for incoming messages
parser = mavlink.MAVLink(None)     # use your dialect directly
parser.srcSystem = 1
parser.srcComponent = 1

# Create MAVLink serializer for outgoing messages
sender = mavlink.MAVLink(ser)  # use serial as its output stream
sender.srcSystem = 255         # GCS system ID
sender.srcComponent = 190      # GCS component ID

latest_signals = {}
last_send = time.time()

heartbeat_period = 1.0
last_heartbeat = time.time()
last_rx = time.time()
link_alive = True

print("[bridge] Running...")

while True:
    chunk = ser.read(4096)
    if chunk:
        for b in chunk:
            msg = parser.parse_char(bytes([b]))
            if msg is None:
                continue
            last_rx = time.time()
            if msg.get_msgId() == 200: # GENERIC_CAN_FRAME
                frame_id = msg.id
                payload = bytes(msg.data)
                try:
                    can_msg = dbc.get_message_by_frame_id(frame_id)
                    decoded = can_msg.decode(payload)
                    frame_name = can_msg.name
                    for sig_name, sig_value in decoded.items():
                        full_name = f"{frame_name}/{sig_name}"
                        latest_signals[full_name] = sig_value

                except Exception:
                    pass
            elif msg.get_msgId() == 109: # RADIO_STATUS
                # Convert raw telemetry to dBm and compute SNRs
                try:
                    # scale and offset identical to MATLAB
                    rssi      = (msg.rssi     / 1.9) - 127.0
                    remrssi   = (msg.remrssi  / 1.9) - 127.0
                    noise     = (msg.noise    / 1.9) - 127.0
                    remnoise  = (msg.remnoise / 1.9) - 127.0

                    txbuf     = float(msg.txbuf)
                    rxerrors  = float(msg.rxerrors)
                    fixed     = float(msg.fixed)

                    # Compute SNRs
                    snr      = rssi - noise     if not (rssi is None or noise is None) else float('nan')
                    rem_snr  = remrssi - remnoise if not (remrssi is None or remnoise is None) else float('nan')

                    # Feed to PlotJuggler-friendly structure
                    latest_signals.update({
                        "radio/rssi":      rssi,
                        "radio/remrssi":   remrssi,
                        "radio/noise":     noise,
                        "radio/remnoise":  remnoise,
                        "radio/snr":       snr,
                        "radio/rem_snr":   rem_snr,
                        "radio/txbuf":     txbuf,
                        "radio/rxerrors":  rxerrors,
                        "radio/fixed":     fixed
                    })

                except Exception as e:
                    # keep bridge alive even if unexpected field missing
                    print(f"[warn] RADIO_STATUS decode failed: {e}")
                    pass
            elif msg.get_msgId() == 0: # HEARTBEAT
                pass
            elif msg.get_msgId() == 201: # DEBUG_FRAME
                pass

    # --- Heartbeat send ---
    now = time.time()
    if now - last_heartbeat >= heartbeat_period:
        hb = sender.heartbeat_encode(
            type=6,
            autopilot=8,
            base_mode=0,
            custom_mode=0,
            system_status=0
        )
        sender.send(hb)
        last_heartbeat = now

    # --- Link status + UDP send ---
    link_alive = (now - last_rx) < 2.0
    if now - last_send >= SEND_PERIOD and latest_signals:
        latest_signals["link/alive"] = 1.0 if link_alive else 0.0
        latest_signals["link/latency"] = now - last_rx
        packet = msgpack.packb({"timestamp": now, "fields": latest_signals})
        sock.sendto(packet, UDP_ADDR)
        last_send = now
