module Top 
import AocPkg::*;
(
    input logic Clk,
    output logic Error,
    output logic Done,
    output logic [47:0] Answer
);

RomAddr_t Addr;
logic [7:0] Data;

ByteRom ByteRom_u 
(
    .Clk(Clk),
    .Addr(Addr),
    .Data(Data)
);

Solver Solver_u 
(
    .Clk(Clk),
    .Addr(Addr),
    .Data(Data),
    .Error(Error),
    .Done(Done),
    .Answer(Answer)
);

endmodule
