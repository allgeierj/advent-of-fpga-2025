#!/usr/bin/env python3

import sys
from pathlib import Path

# Parse arguments
if len(sys.argv) < 2:
    print("Usage: python generate_rom.py <input_file> [<output_file>]")
    sys.exit(1)

input_file = Path(sys.argv[1])
output_file = Path(sys.argv[2]) if len(sys.argv) > 2 else input_file.with_name("rom_hex.txt")

# Read input and write hex ROM
with input_file.open() as f, output_file.open("w") as out:
    for line in f:
        line = line.strip()
        for c in line:
            out.write(f"{ord(c):02X}\n")  # ASCII → hex, one byte per line
    # Append EOT (End Of Transmission, ASCII 0x04) as the last ROM entry
    out.write(f"{0x04:02X}\n")

print(f"ROM file generated: {output_file}")
