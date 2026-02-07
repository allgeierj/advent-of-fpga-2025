module Top 
import AocPkg::*;
(
    input logic Clk,
    output logic Error,
    output logic Done,
    output logic [15:0] Answer
);

RamAddr_t ReadAddr;
RamAddr_t WriteAddr;
logic ReadEnable;
logic WriteEnable;
logic [7:0] ReadData;
logic [7:0] WriteData;

ByteRam ByteRam_u 
(
    .Clk(Clk),
    .ReadAddr(ReadAddr),
    .WriteAddr(WriteAddr),
    .ReadEnable(ReadEnable),
    .WriteEnable(WriteEnable),
    .ReadData(ReadData),
    .WriteData(WriteData)
);

Solver Solver_u 
(
    .Clk(Clk),
    .ReadAddr(ReadAddr),
    .ReadEnable(ReadEnable),
    .ReadData(ReadData),
    .Error(Error),
    .Done(Done),
    .Answer(Answer)
);

endmodule
