# advent-of-fpga-2025

An FPGA Advent of Code repository containing per-day RTL, small simulation testbench, and helper scripts for generating ROMs and running synthesis/simulation. Targeting part `xc7a35tcpg236-1` @ 125 MHz for synthesis.

| Day | Part 1 | Part 2 |
|-----|--------|--------|
| 01  |✓||
| 02  | | |
| 03  |✓|✓|
| 04  |✓|✓|
| 05  | | |
| 06  | | |
| 07  | | |
| 08  | | |
| 09  | | |
| 10  | | |
| 11  | | |
| 12  | | |

## Usage: `run.sh`

- **Purpose:** Generates a ROM from a day's `input.txt`, writes `common/defines.svh`, and runs either synthesis or simulation flows.
- **Actions:** `synth`, `sim`, `sim_gui`.
- **Invocation:** Run from the repository root:

```bash
./run.sh <action> <DAY> <PART>
# examples:
./run.sh synth day01 part01
./run.sh sim day01 part01
./run.sh sim_gui day01 part01
```

- **Behavior:**
  - Runs `python3 generate_rom.py <DAY>/input.txt common/mem.rom` to create the ROM.
  - Writes `common/defines.svh` with `` `define ROM_DEPTH <n>``, `` `define <DAY>``, and `` `define <PART>``.
  - For `synth`: invokes Vivado batch synthesis: `vivado -mode batch -source synth.tcl -tclargs <DAY>`.
  - For `sim` / `sim_gui`: collects `common/*.sv`, `<DAY>/rtl/*.sv`, runs `xvlog -sv`, `xelab Tb -debug typical -timescale 1ns/1ps`, then `xsim work.Tb -runall` (or `-gui`).

- **Prerequisites:**
  - **Tools:** `python3`, Vivado tools (`vivado`, `xvlog`, `xelab`, `xsim`) available in `PATH` for synth/sim.
  - **Input file:** ensure `<DAY>/input.txt` exists (e.g., `day01/input.txt`).
  - **Permissions:** make the script executable if needed: `chmod +x run.sh`.

