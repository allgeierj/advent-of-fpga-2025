module ByteRamSDP
import AocPkg::*;
(
    input logic Clk,
    input RomAddr_t ReadAddr,
    input logic ReadEnable,
    output logic [7:0] ReadData,
    input RomAddr_t WriteAddr,
    input logic WriteEnable,
    input logic [7:0] WriteData
);

(* ram_style = "block" *) logic [7:0] Mem [0:ROM_DEPTH-1];

initial begin
    $readmemh("common/mem.rom", Mem);
end

always_ff @(posedge Clk) begin
    if (WriteEnable) begin
        Mem[WriteAddr] <= WriteData;
    end
end

always_ff @(posedge Clk) begin
    if (ReadEnable) begin
        ReadData <= Mem[ReadAddr];
    end
end

endmodule
