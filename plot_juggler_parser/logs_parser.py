#!/usr/bin/env python3
"""
TXT → Parquet log converter for Celka / PlotJuggler

Usage example:
python plot_juggler_parser/logs_parser.py \
--dbc D:/Dane/workspace/can-messages-mini-celka/can_messages_mini_celka.dbc \
--input F:/LOG014.TXT \
--output D:/Dane/workspace/can-logs-mini-celka/logs_parquet/LOG014.parquet \
--verbose

"""

import os
import sys
import argparse
import datetime
import struct
from typing import Set
import cantools
import pandas as pd


# ========== Helper functions ==========

def human_readable_size(size, decimal_places=2) -> str:
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size < 1024:
            return f"{size:.{decimal_places}f} {unit}"
        size /= 1024


def is_valid_hex(s: str) -> bool:
    valid_chars = set("0123456789ABCDEFabcdef")
    return all(c in valid_chars for c in s)


# ========== NKPL core ==========

class NKPL:
    """
    NKPL — Niezły Kurczę Parser Logów :)
    Decodes Celka TXT logs to structured data.
    """

    def __init__(self):
        # Ignored IDs
        self.ignored_ids: Set[int] = set()
        self.init_and_clear_fields()

    # ------------------------------------
    def init_and_clear_fields(self) -> None:
        self.corrupted_line_counter = 0
        self.line_counter = 0
        self.id_exception_counter = 0
        self.ignored_messages_counter = 0
        self.decoded_messages_counter = 0
        self.database = dict()

    # ------------------------------------
    def set_ignored_ids(self, ids: Set[int] = set()) -> None:
        self.ignored_ids = set(ids)

    # ------------------------------------
    def parse_and_decode(self, dbc_path: str, log_path: str, PRINT_ADDITIONAL_INFO=False):
        """Decode TXT log file using DBC definition."""
        self.init_and_clear_fields()
        print(f"[decode] Using DBC: {dbc_path}")
        print(f"[decode] Input log: {log_path}")

        dbc = cantools.database.load_file(dbc_path)
        line_count = sum(1 for _ in open(log_path, 'r', encoding='utf-8', errors='ignore'))
        print(f"[decode] {line_count} lines detected ({human_readable_size(os.path.getsize(log_path))})")

        with open(log_path, 'r', encoding='utf-8', errors='ignore') as file:
            for line in file:
                line = line.strip()
                if not line or line.startswith("#"):
                    # skip comments and empty lines
                    continue
                self.line_counter += 1

                # Parse expected structure HH:MM:SS,KKK;ID;DATA
                spl = line.split(';')
                if len(spl) != 3:
                    self.handle_corrupted_line(line, "Split != 3")
                    continue

                timestamp_str, id_str, payload_str = spl

                # Validate timestamp
                try:
                    timestamp = datetime.datetime.strptime(timestamp_str, '%H:%M:%S,%f')
                except Exception:
                    self.handle_corrupted_line(line, "Bad timestamp")
                    continue

                # Validate ID
                if not is_valid_hex(id_str):
                    self.handle_corrupted_line(line, "Bad ID hex")
                    continue
                try:
                    can_id = int(id_str, 16)
                except Exception:
                    self.handle_corrupted_line(line, "Bad ID int")
                    continue

                # Validate payload
                if not is_valid_hex(payload_str) or len(payload_str) % 2 != 0:
                    self.handle_corrupted_line(line, "Bad payload hex")
                    continue
                try:
                    payload = bytes.fromhex(payload_str)
                except Exception:
                    self.handle_corrupted_line(line, "Payload parse fail")
                    continue

                # Skip ignored IDs
                if can_id in self.ignored_ids:
                    self.ignored_messages_counter += 1
                    continue

                # Decode CAN frame
                try:
                    message = dbc.get_message_by_frame_id(can_id)
                    decoded = message.decode(payload)
                except Exception as e:
                    self.id_exception_counter += 1
                    if PRINT_ADDITIONAL_INFO:
                        print(f"[warn] ID 0x{can_id:X} decode fail: {e}")
                    continue

                # FLOAT32_IEEE conversion
                for signal in message.signals:
                    unit = signal.unit or ""
                    if "FLOAT32_IEEE" in unit and signal.name in decoded:
                        raw = decoded[signal.name]
                        if isinstance(raw, int):
                            try:
                                decoded[signal.name] = struct.unpack('<f', raw.to_bytes(4, 'little'))[0]
                            except Exception:
                                pass

                # Store decoded values
                for key, val in decoded.items():
                    name = f"{message.name}__{key}"
                    if name not in self.database:
                        self.database[name] = {'timestamps': [], 'values': []}
                    self.database[name]['timestamps'].append(timestamp)
                    self.database[name]['values'].append(val)

                # Count this as one decoded CAN frame
                self.decoded_messages_counter += 1


        # Compute timespan
        if self.database:
            all_ts = [ts for d in self.database.values() for ts in d['timestamps']]
            self.min_dt = min(all_ts)
            self.max_dt = max(all_ts)
        else:
            self.min_dt = self.max_dt = None

        print(f"[decode] Done. {self.line_counter} lines, "
              f"{self.corrupted_line_counter} corrupted, "
              f"{self.decoded_messages_counter} decoded.")

        if PRINT_ADDITIONAL_INFO:
            self.print_stats()

    # ------------------------------------
    def handle_corrupted_line(self, line: str, reason: str = None) -> None:
        self.corrupted_line_counter += 1
        if reason:
            print(f"[corrupt] {reason}: {line}")

    # ------------------------------------
    def print_stats(self):
        if not self.line_counter:
            return
        perc = (self.corrupted_line_counter / self.line_counter) * 100
        print(f"[stats] Corrupted lines: {self.corrupted_line_counter} ({perc:.2f}%)")
        print(f"[stats] ID exceptions: {self.id_exception_counter}")
        print(f"[stats] Ignored messages: {self.ignored_messages_counter}")
        print(f"[stats] Decoded messages: {self.decoded_messages_counter}")
        if self.min_dt and self.max_dt:
            span = self.max_dt - self.min_dt
            print(f"[stats] Timespan: {self.min_dt.strftime('%H:%M:%S.%f')[:-3]} → "
                  f"{self.max_dt.strftime('%H:%M:%S.%f')[:-3]} ({span})")

    # ------------------------------------
    def to_dataframe(self) -> pd.DataFrame:
        """Convert database to pandas DataFrame (wide format)."""
        if not self.database:
            print("[warn] No decoded data to export.")
            return pd.DataFrame()

        frames = []
        for name, rec in self.database.items():
            ts = pd.to_datetime(rec['timestamps'])
            vals = rec['values']
            df_part = pd.DataFrame({"timestamp": ts, name: vals})
            frames.append(df_part)

        # Merge without forcing unique timestamps
        df = pd.concat(frames, axis=1)
        df = df.loc[:, ~df.columns.duplicated()]  # drop accidental duplicate column names

        # Ensure timestamps are sorted and numeric
        df.sort_values("timestamp", inplace=True, ignore_index=True)

        # Convert timestamp → seconds since start
        t0 = df["timestamp"].iloc[0]
        df["time_s"] = (df["timestamp"] - t0).dt.total_seconds()

        # Reorder columns so time_s is first
        cols = ["time_s"] + [c for c in df.columns if c not in ["time_s", "timestamp"]]
        df = df[cols]

        print(f"[dataframe] Created DataFrame with shape {df.shape}")
        return df


    # ------------------------------------
    def export_parquet(self, df: pd.DataFrame, output_path: str, dbc_path: str):
        if df.empty:
            print("[warn] Empty DataFrame — skipping save.")
            return
        # Optional: attach metadata to Parquet file
        meta = {
            "source_log": os.path.basename(output_path),
            "dbc_file": os.path.basename(dbc_path) if 'dbc_path' in locals() else "unknown",
            "frames_decoded": str(self.decoded_messages_counter),
            "start_time": self.min_dt.isoformat() if self.min_dt else "",
            "end_time": self.max_dt.isoformat() if self.max_dt else "",
            "duration_s": str((self.max_dt - self.min_dt).total_seconds()) if self.min_dt and self.max_dt else "",
        }
        df.attrs.update(meta)
        df.to_parquet(output_path, compression="zstd")
        print(f"[ok] Parquet saved: {output_path} ({human_readable_size(os.path.getsize(output_path))})")


# ========== CLI entrypoint ==========

def main():
    parser = argparse.ArgumentParser(description="Decode Celka TXT logs into Parquet for PlotJuggler")
    parser.add_argument("--dbc", required=True, help="Path to .dbc file")
    parser.add_argument("--input", required=True, help="Path to .txt log file")
    parser.add_argument("--output", required=True, help="Path to output .parquet file")
    parser.add_argument("--ignore", nargs="*", default=[], help="IDs to ignore (hex, e.g. 0A 0B)")
    parser.add_argument("--verbose", action="store_true", help="Print extra corruption and decoding info")
    args = parser.parse_args()

    nkpl = NKPL()
    if args.ignore:
        nkpl.set_ignored_ids({int(x, 16) for x in args.ignore})

    nkpl.parse_and_decode(args.dbc, args.input, PRINT_ADDITIONAL_INFO=args.verbose)
    df = nkpl.to_dataframe()
    nkpl.export_parquet(df, args.output, args.dbc)
    print(f"[done] Parsed '{args.input}' → '{args.output}' successfully.")


if __name__ == "__main__":
    main()
