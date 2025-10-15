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
import psutil  # add near the top with other imports


# === CONFIG ===
SERIAL_PORT = "COM17"
BAUDRATE = 115200
UDP_ADDR = ("127.0.0.1", 9870)
SEND_PERIOD = 0.1
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

rx_bytes = 0
tx_bytes = 0
last_uart_sample = time.time()
uart_rx_speed = 0.0
uart_tx_speed = 0.0

last_remote_heartbeat = 0.0

# --- CAN and MAV diagnostic counters ---
can_frames = 0
can_decode_errors = 0
last_diag_sample = time.time()
can_fps = 0.0
loop_time = 0.0
can_errors_last = 0

print("[bridge] Running...")

while True:
    # --- Measure loop time ---
    t_loop_start = time.time()

    # --- Recieve bytes from serial port ---
    chunk = ser.read(4096)
    if chunk:
        # Count bytes for diagnostic purposes
        rx_bytes += len(chunk)
        for b in chunk:
            msg = parser.parse_char(bytes([b]))
            if msg is None:
                continue
            last_rx = time.time()

            if msg.get_msgId() == 200:  # GENERIC_CAN_FRAME
                frame_id = msg.id
                payload = bytes(msg.data)
                try:
                    can_msg = dbc.get_message_by_frame_id(frame_id)
                    decoded = can_msg.decode(payload)
                    frame_name = can_msg.name
                    can_frames += 1  # count CAN frames seen

                    # --- handle FLOAT32_IEEE conversions ---
                    import struct
                    for signal in can_msg.signals:
                        unit = signal.unit or ""
                        if "FLOAT32_IEEE" in unit and signal.name in decoded:
                            raw_val = decoded[signal.name]
                            if isinstance(raw_val, int):
                                try:
                                    decoded[signal.name] = struct.unpack('<f', raw_val.to_bytes(4, 'little'))[0]
                                except Exception:
                                    pass  # ignore malformed float

                    # --- store decoded signals with frame prefix ---
                    for sig_name, sig_value in decoded.items():
                        full_name = f"{frame_name}/{sig_name}"
                        latest_signals[full_name] = sig_value

                except Exception as e:
                    can_decode_errors += 1
                    print(f"[warn] CAN decode failed for ID {frame_id:#04x}: {e}")

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
                        "link/rssi":      rssi,
                        "link/remrssi":   remrssi,
                        "link/noise":     noise,
                        "link/remnoise":  remnoise,
                        "link/snr":       snr,
                        "link/rem_snr":   rem_snr,
                        "link/txbuf":     txbuf,
                        "link/rxerrors":  rxerrors,
                        "link/fixed":     fixed
                    })

                except Exception as e:
                    # keep bridge alive even if unexpected field missing
                    print(f"[warn] RADIO_STATUS decode failed: {e}")
                    pass

            elif msg.get_msgId() == 0:  # HEARTBEAT from remote
                last_remote_heartbeat = time.time()
                try:
                    # You can record heartbeat info too if you like
                    latest_signals.update({
                        "remote_heartbeat/type": msg.type,
                        "remote_heartbeat/autopilot": msg.autopilot,
                        "remote_heartbeat/system_status": msg.system_status,
                        "remote_heartbeat/base_mode": msg.base_mode,
                    })
                except Exception:
                    pass

            elif msg.get_msgId() == 201: # DEBUG_FRAME
                pass

    # --- Heartbeat send ---
    now = t_loop_start
    if now - last_heartbeat >= heartbeat_period:
        hb = sender.heartbeat_encode(
            type=6,
            autopilot=8,
            base_mode=0,
            custom_mode=0,
            system_status=0
        )
        # Pack manually to capture raw bytes
        payload = hb.pack(sender)
        ser.write(payload)          # actually send
        tx_bytes += len(payload)    # count bytes sent
        last_heartbeat = now

    # --- Diagnostics: compute FPS, CPU, loop time ---
    dt_diag = now - last_diag_sample
    if dt_diag >= 1.0:
        can_fps = can_frames / dt_diag
        can_errors_last = can_decode_errors  # surowy licznik z ostatniej sekundy

        # reset liczników
        can_frames = 0
        can_decode_errors = 0

        cpu_usage = psutil.cpu_percent(interval=None)
        last_diag_sample = now


    # --- Link & UART telemetry + UDP send ---
    link_alive = (now - last_remote_heartbeat) < 2.0

    # update UART throughput once per SEND_PERIOD
    dt_uart = now - last_uart_sample
    if dt_uart > 0:
        uart_rx_speed = rx_bytes / dt_uart
        uart_tx_speed = tx_bytes / dt_uart
        rx_bytes = 0
        tx_bytes = 0
        last_uart_sample = now

    uart_util_rx = (uart_rx_speed * 10 / ser.baudrate) * 100.0
    uart_util_tx = (uart_tx_speed * 10 / ser.baudrate) * 100.0

    # --- Send --- 
    if now - last_send >= SEND_PERIOD and latest_signals:
        loop_time = (time.time() - t_loop_start) * 1000.0  # ms

        latest_signals.update({
            "link/alive": 1.0 if link_alive else 0.0,
            "link/latency": now - last_rx,

            # UART stats
            "uart/rx_speed": uart_rx_speed,
            "uart/tx_speed": uart_tx_speed,
            "uart/util_rx": uart_util_rx,
            "uart/util_tx": uart_util_tx,

            # New diagnostics
            "can/fps": can_fps,
            "can/decode_errors_last_sec": can_errors_last,
            "bridge/cpu_usage": cpu_usage,
            "bridge/loop_time_ms": loop_time
        })

        packet = msgpack.packb({"timestamp": now, "fields": latest_signals})
        sock.sendto(packet, UDP_ADDR)
        latest_signals.clear()
        last_send = now
