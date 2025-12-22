module ByteRom 
import AocPkg::*;
(
    input logic Clk,
    input RomAddr_t Addr,
    output logic [7:0] Data
);

logic [7:0] Mem [0:ROM_DEPTH-1];

initial begin
    $readmemh("common/mem.rom", Mem);
end

always_ff @(posedge Clk) begin
    Data <= Mem[Addr];
end

endmodule
