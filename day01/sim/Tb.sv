module Tb;

logic Clk;
logic Error;
logic Done;

initial begin
    Clk = 1'b0;
end

always #5 Clk = ~Clk;

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
        $display("Password is: %0d", Top_u.Solver_u.Q.Password);
    end
    $finish;
end

endmodule
