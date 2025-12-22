# advent-of-fpga-2025

A small FPGA Advent-of-Code repository containing per-day RTL, small simulation testbenches,
and helper scripts for generating ROMs and running synthesis/simulation.

## Usage: `run.sh`

- **Purpose:** Generates a ROM from a day's `input.txt`, writes `common/defines.svh`, and runs either synthesis or simulation flows.
- **Actions:** `synth`, `sim`, `sim_gui`.
- **Invocation:** Run from the repository root:

```bash
./run.sh <action> <DAY>
# examples:
./run.sh synth day01
./run.sh sim day01
./run.sh sim_gui day01
```

- **Behavior:**
  - Runs `python3 generate_rom.py <DAY>/input.txt common/mem.rom` to create the ROM.
  - Writes `common/defines.svh` with `` `define ROM_DEPTH <n>`` and `` `define DAY "<DAY>"``.
  - For `synth`: invokes Vivado batch synthesis: `vivado -mode batch -source synth.tcl -tclargs <DAY>`.
  - For `sim` / `sim_gui`: collects `common/*.sv`, `<DAY>/rtl/*.sv`, `<DAY>/sim/*.sv`, runs `xvlog -sv`, `xelab Tb -debug typical -timescale 1ns/1ps`, then `xsim work.Tb -runall` (or `-gui`).

- **Prerequisites:**
  - **Tools:** `python3`, Vivado tools (`vivado`, `xvlog`, `xelab`, `xsim`) available in `PATH` for synth/sim.
  - **Input file:** ensure `<DAY>/input.txt` exists (e.g., `day01/input.txt`).
  - **Permissions:** make the script executable if needed: `chmod +x run.sh`.

- **Notes:**
  - The script exits with usage help if action or day are missing or invalid.
  - ROM depth is computed from the generated ROM and written into `common/defines.svh`.
  - See `run.sh` for exact implementation details and file discovery order.
