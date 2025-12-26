#!/bin/bash
# run.sh
# Usage: ./run.sh <action> <DAY>
# action: synth|sim|sim_gui

set -e

# Parse input
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $0 <action> <DAY> <PART> (action: synth|sim|sim_gui; e.g., synth day01 part01)"
    exit 1
fi

ACTION=$1
DAY=$2
PART=$3

case "$ACTION" in
    synth|sim|sim_gui)
        ;;
    *)
        echo "Invalid action: $ACTION. Must be 'synth' or 'sim'."
        exit 1
        ;;
esac

INPUT_FILE="$DAY/input.txt"
ROM_FILE="common/mem.rom"
DEFINES_FILE="common/defines.svh"

# Generate ROM
echo "Generating ROM for $DAY..."
python3 generate_rom.py "$INPUT_FILE" "$ROM_FILE"

# Determine ROM length
ROM_DEPTH=$(wc -l < "$ROM_FILE")
echo "ROM length: $ROM_DEPTH bytes"

# Generate defines.svh
echo "Creating $DEFINES_FILE..."
cat <<EOL > "$DEFINES_FILE"
\`define ROM_DEPTH $ROM_DEPTH
\`define ${DAY^^}
\`define ${PART^^}
EOL

# Call Vivado for selected action
if [ "$ACTION" = "synth" ]; then
    echo "Running synth.tcl..."
    vivado -mode batch -source synth.tcl -tclargs "$DAY"
else
    echo "Building file list for xvlog..."
    FILES=""

    # Add defines first if present
    if [ -f "$DEFINES_FILE" ]; then
        FILES="$DEFINES_FILE"
    fi

    # Helper to append .sv files from a directory into a space-delimited string
    append_sv_files() {
        DIR="$1"
        for f in "$DIR"/*.sv; do
            [ -e "$f" ] || continue
            if [ -z "$FILES" ]; then
                FILES="$f"
            else
                FILES="$FILES $f"
            fi
        done
    }

    append_sv_files common
    append_sv_files "$DAY/rtl"
    # append_sv_files "$DAY/sim"

    echo "File list:" 
    for fn in $FILES; do
        echo "  $fn"
    done

    if [ -z "$FILES" ]; then
        echo "No source files found for simulation. Aborting."
        exit 1
    fi

    echo "Running xvlog..."
    xvlog -sv $FILES

    echo "Running xelab..."
    xelab Tb -debug typical -timescale 1ns/1ps

    if [ "$ACTION" = "sim" ]; then
        echo "Running xsim..."
        xsim work.Tb -runall
    elif [ "$ACTION" = "sim_gui" ]; then
        echo "Running xsim with GUI..."
        xsim work.Tb -gui
    fi
fi
echo "Done."
