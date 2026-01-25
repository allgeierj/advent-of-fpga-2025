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
    output logic Done,
    output logic [47:0] Answer
);

localparam logic [7:0] ASCII_EOT = 8'h04;

`ifdef PART01
localparam BATS_PER_JOLTAGE = 2;
localparam BANK_JOLTAGE_BITS = 7;
localparam TOTAL_JOLTAGE_BITS = 32;
localparam logic [3:0] JoltageMult [0:1] = '{
    10,
    1
};
`elsif PART02
localparam BATS_PER_JOLTAGE = 12;
localparam BANK_JOLTAGE_BITS = 40;
localparam TOTAL_JOLTAGE_BITS = 48;
localparam logic [36:0] JoltageMult [0:11] = '{
    37'd100_000_000_000,
    37'd10_000_000_000,
    37'd1_000_000_000,
    37'd100_000_000,
    37'd10_000_000,
    37'd1_000_000,
    37'd100_000,
    37'd10_000,
    37'd1000,
    37'd100,
    37'd10,
    1
};
`endif


typedef enum logic [1:0] {
    S_IDLE,
    S_RUN,
    S_DONE,
    S_ERROR
} Fsm_e;

typedef struct packed {
    Fsm_e Fsm;
    RomAddr_t Addr;
    logic [$clog2(BATS_PER_BANK):0] BatteryCount;
    logic [0:BATS_PER_JOLTAGE-1][3:0] Joltage;
    logic Accum;
    logic [$clog2(BATS_PER_JOLTAGE):0] AccumMultPlace;
    logic [BANK_JOLTAGE_BITS-1:0] AccumJoltage;
    logic [TOTAL_JOLTAGE_BITS-1:0] TotalJoltage;
    logic [1:0] Flush;
} State_ts;
State_ts Q = '0, D;

assign Answer = Q.TotalJoltage;

always_comb begin
    D = Q;
    Error = 1'b0;
    Done = 1'b0;

    case(Q.Fsm)
        S_IDLE: begin
            Addr = '0;
            D.Fsm = S_RUN;
        end
        S_RUN: begin
            Addr = Q.Addr + 1;
            D.BatteryCount++;
            case(Data) inside
                [8'h30:8'h39]: begin // '0' to '9'
                    automatic logic [3:0] joltage = Data - 8'h30;
                    automatic logic joltageSet = 1'b0;
                    automatic logic [3:0] minPlace = 0;
                    if (Q.BatteryCount >= BATS_PER_BANK - BATS_PER_JOLTAGE) begin
                        minPlace = Q.BatteryCount - (BATS_PER_BANK - BATS_PER_JOLTAGE);
                        D.Accum = 1'b1;
                    end
                    for(logic [$clog2(BATS_PER_JOLTAGE):0] i = 0; i < BATS_PER_JOLTAGE; i++) begin
                        if(i < minPlace) continue;
                        if(joltageSet) D.Joltage[i] = 4'd0;
                        else if(joltage > Q.Joltage[i]) begin
                            D.Joltage[i] = joltage;
                            joltageSet = 1'b1;
                        end
                    end
                    if(Q.BatteryCount == BATS_PER_BANK -1) begin
                        D.Joltage[0] = 4'd0;
                        D.BatteryCount = '0;
                    end
                end
                ASCII_EOT: begin // EOT
                    D.Fsm = S_DONE;
                    D.Flush = 2'd1;
                end
                default: begin
                    D.Fsm = S_ERROR;
                end
            endcase
        end
        S_DONE: begin
            if(Q.Flush > 0) D.Flush--;
            else Done = 1'b1;
        end
        S_ERROR: begin
            Error = 1'b1;
        end
    endcase

    if(Q.Accum) begin
        D.AccumMultPlace++;
        D.TotalJoltage += Q.AccumJoltage;
        if(Q.AccumMultPlace < BATS_PER_JOLTAGE)
            D.AccumJoltage = Q.Joltage[Q.AccumMultPlace] * JoltageMult[Q.AccumMultPlace];
        else D.AccumJoltage = '0;
        if(Q.AccumMultPlace == BATS_PER_JOLTAGE) begin
            D.Accum = 1'b0;
            D.AccumMultPlace = '0;
            D.AccumJoltage = '0;
        end
    end

    D.Addr = Addr;
end

always_ff @(posedge Clk) begin
    Q <= D;
end

endmodule
