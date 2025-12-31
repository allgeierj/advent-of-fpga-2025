module Tb;

logic Clk;
logic Error;
logic Done;

initial begin
    Clk = 1'b0;
end

// 250 MHz clock
always #2 Clk = ~Clk;

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
        `elsif DAY02
        $display("Sum of invalid IDs is: %0d", Top_u.Solver_u.Q.InvalidIdSum);
        `elsif DAY03
        $display("Total joltage is: %0d", Top_u.Solver_u.Q.TotalJoltage);
        `endif
    end
    $finish;
end

endmodule
