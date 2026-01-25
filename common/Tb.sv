module Tb;

logic Clk;
logic Error;
logic Done;

initial begin
    Clk = 1'b0;
end

// 125 MHz clock
always #4 Clk = ~Clk;

Top Top_u 
(
    .Clk(Clk),
    .Error(Error),
    .Done(Done)
);

always @(posedge Error or posedge Done)
begin
    $display("Error: %b, Done: %b", Error, Done);
    if(Done) begin
        `ifdef DAY01
        $display("Password is: %0d", Top_u.Solver_u.Q.Password);
        `elsif DAY03
        $display("Total joltage is: %0d", Top_u.Solver_u.Answer);
        `elsif DAY04
        $display("Number of accessible rolls is: %0d", Top_u.Solver_u.Answer);
        `endif
    end
    $finish;
end

endmodule
