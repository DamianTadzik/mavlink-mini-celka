#!/usr/bin/env python3
"""
Telemetry Bridge: UART → MsgPack over UDP for PlotJuggler
---------------------------------------------------------
- Reads CAN/MAVLink frames from UART
- Decodes into named physical signals
- Packs them as MsgPack (binary JSON)
- Sends over UDP to PlotJuggler (single port)

Protocol in PlotJuggler:
UDP Server → Protocol: 'msgpack' → Port: 9870
"""

import serial
import socket
import msgpack
import time
import random
import threading

# ==== CONFIGURATION ====
SERIAL_PORT = "COM5"
BAUDRATE = 921600
UDP_ADDR = ("127.0.0.1", 9870)
SEND_PERIOD = 0.02  # seconds between UDP updates
HEARTBEAT_PERIOD = 2.0

# If you don't have UART yet, set to None and it will simulate frames
USE_FAKE_FRAMES = True
# =======================


# ---------------------------------------------------------------------
# Mock CAN frame generator (simulates 10 frame types, different rates)
# ---------------------------------------------------------------------
FRAME_DEFS = {
    0x100: ("motor/rpm", "motor/torque", "bus/voltage", "bus/current"),
    0x101: ("bms/voltage", "bms/current", "bms/temp", "bms/soc"),
    0x102: ("gps/lat", "gps/lon", "gps/alt"),
    0x103: ("imu/roll", "imu/pitch", "imu/yaw"),
    0x104: ("rc/throttle", "rc/roll", "rc/pitch", "rc/yaw"),
    0x105: ("sys/temp_cpu", "sys/temp_board"),
    0x106: ("env/temp", "env/pressure"),
    0x107: ("foil/left_angle", "foil/right_angle"),
    0x108: ("battery1/voltage", "battery2/voltage"),
    0x109: ("psu/current", "psu/voltage"),
}

def simulate_frame_generator():
    """Fake CAN frame generator at random rates."""
    while True:
        frame_id = random.choice(list(FRAME_DEFS.keys()))
        signals = {}
        for name in FRAME_DEFS[frame_id]:
            signals[name] = random.uniform(0, 100)
        yield frame_id, signals
        time.sleep(random.uniform(0.002, 0.02))  # simulate 50–500 Hz

# ---------------------------------------------------------------------
# Bridge Core
# ---------------------------------------------------------------------
class TelemetryBridge:
    def __init__(self):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.ser = None if USE_FAKE_FRAMES else serial.Serial(SERIAL_PORT, BAUDRATE, timeout=0.001)
        self.last_udp_send = time.time()
        self.last_heartbeat = time.time()
        self.latest_signals = {}
        self.running = True

    def decode_frame(self, raw_bytes):
        """
        Replace this stub with your real CAN/MAVLink decoder.
        Must return (frame_id, {signal_name: value})
        """
        # For now, simulate
        frame_id, signals = next(fake_gen)
        return frame_id, signals

    def send_udp(self):
        """Pack all latest signals and send to PlotJuggler."""
        msg = {
            "timestamp": time.time(),
            "fields": self.latest_signals
        }
        packet = msgpack.packb(msg)
        self.sock.sendto(packet, UDP_ADDR)

    def run(self):
        while self.running:
            # --- Read from UART or simulation ---
            if USE_FAKE_FRAMES:
                frame_id, signals = next(fake_gen)
            else:
                raw = self.ser.read_until(b'\n')
                if not raw:
                    continue
                frame_id, signals = self.decode_frame(raw)

            # --- Update latest values ---
            self.latest_signals.update(signals)

            # --- Send UDP batch periodically ---
            now = time.time()
            if now - self.last_udp_send >= SEND_PERIOD:
                self.send_udp()
                self.last_udp_send = now

            # --- Heartbeat back to UART (optional) ---
            if not USE_FAKE_FRAMES and now - self.last_heartbeat >= HEARTBEAT_PERIOD:
                self.ser.write(b'\xAA\x55')
                self.last_heartbeat = now


# ---------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------
if __name__ == "__main__":
    print("Starting Telemetry Bridge...")
    fake_gen = simulate_frame_generator() if USE_FAKE_FRAMES else None
    bridge = TelemetryBridge()

    try:
        bridge.run()
    except KeyboardInterrupt:
        bridge.running = False
        print("\nStopped.")
