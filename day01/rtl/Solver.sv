module Solver 
import AocPkg::*;
(
    input logic Clk,
    output RomAddr_t Addr,
    input logic [7:0] Data,
    output logic Error,
    output logic Done
);

localparam logic [7:0] ASCII_L = 8'h4C;
localparam logic [7:0] ASCII_R = 8'h52;
localparam logic [7:0] ASCII_EOT = 8'h04;

typedef enum logic [1:0] {
    S_IDLE = 2'd0,
    S_RUN,
    S_DONE,
    S_ERROR
} Fsm_e;

typedef enum logic {
    LEFT = 1'b0,
    RIGHT
} DialDir_e;

typedef struct packed {
    Fsm_e Fsm;
    DialDir_e DialDir;
    logic signed [31:0] DialPos;
    logic [31:0] DialAcc;
    logic [31:0] Password;
    RomAddr_t Addr;
} State_ts;
State_ts Q = {DialPos: 16'd50, Fsm: S_IDLE, DialDir:LEFT, default: '0}, D;

always_comb begin
    D = Q;
    Error = 1'b0;
    Done = 1'b0;

    case(Q.Fsm)
        S_IDLE: begin
            D.Fsm = S_RUN;
            Addr = 0;
        end
        S_RUN: begin
            Addr = Q.Addr + 1;
            case(Data) inside
                ASCII_L, ASCII_R: begin
                    automatic logic signed [31:0] dialPos = Q.DialPos;
                    automatic logic signed [31:0] dialDelta = (Q.DialDir == LEFT) ? -$signed(Q.DialAcc) : $signed(Q.DialAcc);
                    automatic logic signed [31:0] dialPosUnwrapped = Q.DialPos + dialDelta;
                    automatic logic [31:0] numCrosses = 32'd0;
                    
                    dialPos = (dialPos + dialDelta) % 100;
                    if(dialPos < 0) dialPos = dialPos + 100;
                    
                    `ifdef PART01
                    if(dialPos == 0) begin
                        D.Password++;
                    end
                    `else
                    if (dialDelta >= 0) begin
                        numCrosses = (dialPosUnwrapped >= 0) ? (dialPosUnwrapped / 100) : 32'd0;
                    end 
                    else begin
                        automatic logic [31:0] dialDeltaMag = -dialDelta;
                        automatic logic [31:0] clicksToZero = (Q.DialPos == 0) ? 32'd100 : Q.DialPos;
                        if (dialDeltaMag >= clicksToZero) begin
                            numCrosses = 32'd1 + (dialDeltaMag - clicksToZero) / 100;
                        end
                    end
                    D.Password = D.Password + numCrosses;
                    `endif
                    
                    D.DialPos = dialPos;
                    D.DialAcc = 32'd0;
                    D.DialDir = (Data == ASCII_L) ? LEFT : RIGHT;
                end
                [8'h30:8'h39]: begin // '0' to '9'
                    D.DialAcc = Q.DialAcc * 10 + (Data - 8'h30); 
                end
                ASCII_EOT: begin // EOT
                    D.Fsm = S_DONE;
                end
                default: begin
                    D.Fsm = S_ERROR;
                end
            endcase
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
