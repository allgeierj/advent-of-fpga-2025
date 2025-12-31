module Solver
import AocPkg::*;
#(
    parameter BATS_PER_BANK = 100
) 
(
    input logic Clk,
    output RomAddr_t Addr,
    input logic [7:0] Data,
    output logic Error,
    output logic Done
);

localparam logic [7:0] ASCII_EOT = 8'h04;

typedef enum {
    S_IDLE,
    S_READ,
    S_ACCUM_JOLTAGE,
    S_DONE,
    S_ERROR
} Fsm_e;

typedef struct packed {
    Fsm_e Fsm;
    RomAddr_t Addr;
    logic [$clog2(BATS_PER_BANK):0] BatteryCount;
    logic [3:0] Joltage1, Joltage2;
    logic [31:0] TotalJoltage;
} State_ts;
State_ts Q = '0, D;

always_comb begin
    D = Q;
    Error = 1'b0;
    Done = 1'b0;

    case(Q.Fsm)
        S_IDLE: begin
            Addr = '0;
            D.Fsm = S_READ;
        end
        S_READ: begin
            Addr = Q.Addr + 1;
            D.BatteryCount++;
            case(Data) inside
                [8'h30:8'h39]: begin // '0' to '9'
                automatic logic [3:0] joltage = Data - 8'h30;
                    case(Q.BatteryCount) inside
                        [0:BATS_PER_BANK - 2]: begin
                            if(joltage > Q.Joltage1) begin
                                 D.Joltage1 = joltage;
                                 D.Joltage2 = 4'd0;
                            end
                            else if(joltage > Q.Joltage2) begin
                                D.Joltage2 = joltage;
                            end
                        end
                        [BATS_PER_BANK - 1:BATS_PER_BANK]: begin
                            D.Fsm = S_ACCUM_JOLTAGE;
                            if(joltage > Q.Joltage2) D.Joltage2 = joltage;
                        end
                    endcase
                end
                ASCII_EOT: begin // EOT
                    D.Fsm = S_DONE;
                end
                default: begin
                    D.Fsm = S_ERROR;
                end
            endcase
        end
        S_ACCUM_JOLTAGE: begin
            D.Fsm = S_READ;
            D.TotalJoltage += (Q.Joltage1 * 10) + Q.Joltage2;
            D.Joltage1 = 4'd0; 
            D.Joltage2 = 4'd0;
            D.BatteryCount = '0;
        end
        S_DONE: begin
            Done = 1'b1;
        end
        S_ERROR: begin
            Error = 1'b1;
        end
    endcase
    D.Addr = Addr;
end

always_ff @(posedge Clk) begin
    Q <= D;
end

endmodule
