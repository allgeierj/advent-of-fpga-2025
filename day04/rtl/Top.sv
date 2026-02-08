module Top 
import AocPkg::*;
(
    input logic Clk,
    output logic Error,
    output logic Done,
    output logic [15:0] Answer
);

RamAddr_t ReadAddr;
logic ReadEnable;
logic [7:0] ReadData;
`ifdef PART02
RamAddr_t WriteAddr;
logic WriteEnable;
logic [7:0] WriteData;
`endif


`ifdef PART01
ByteRom ByteRom_u 
(
    .Clk(Clk),
    .Addr(ReadAddr),
    .Data(ReadData)
);
`elsif PART02
ByteRamSDP ByteRamSDP_u 
(
    .Clk(Clk),
    .ReadAddr(ReadAddr),
    .ReadEnable(ReadEnable),
    .ReadData(ReadData),
    .WriteAddr(WriteAddr),
    .WriteEnable(WriteEnable),
    .WriteData(WriteData)
);
`endif

Solver Solver_u 
(
    .Clk(Clk),
    .ReadAddr(ReadAddr),
    .ReadEnable(ReadEnable),
    .ReadData(ReadData),
    `ifdef PART02
    .WriteAddr(WriteAddr),
    .WriteEnable(WriteEnable),
    .WriteData(WriteData),
    `endif
    .Error(Error),
    .Done(Done),
    .Answer(Answer)
);

endmodule
