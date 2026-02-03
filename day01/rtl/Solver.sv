module Solver 
import AocPkg::*;
(
    input logic Clk,
    output RomAddr_t Addr,
    input logic [7:0] Data,
    output logic Error,
    output logic Done,
    output logic [15:0] Answer
);

localparam logic [7:0] ASCII_L = 8'h4C;
localparam logic [7:0] ASCII_R = 8'h52;
localparam logic [7:0] ASCII_EOT = 8'h04;

typedef enum logic [2:0] {
    S_IDLE = 3'd0,
    S_READ,
    S_CHECK_ZERO,
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
    logic signed [15:0] DialPos;
    logic [9:0] DialAcc;
    logic [15:0] Password;
    RomAddr_t Addr;
} State_ts;
State_ts Q = {DialPos: 8'd50, Fsm: S_IDLE, DialDir:LEFT, default: '0}, D;

assign Answer = Q.Password;

always_comb begin
    D = Q;
    Addr = Q.Addr;
    Error = 1'b0;
    Done = 1'b0;

    case(Q.Fsm)
        S_IDLE: begin
            D.Fsm = S_READ;
            Addr = 0;
        end
        S_READ: begin
            Addr = Q.Addr + 1;
            case(Data) inside
                ASCII_L, ASCII_R: begin
                    D.Fsm = S_CHECK_ZERO;
                    case(Q.DialDir)
                        LEFT: D.DialPos = Q.DialPos - Q.DialAcc;
                        RIGHT: D.DialPos = Q.DialPos + Q.DialAcc;
                    endcase
                    D.DialDir = Data == ASCII_L ? LEFT : RIGHT;
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
        S_CHECK_ZERO: begin
            `ifdef PART01
            if(Q.DialPos >= 100) D.DialPos = Q.DialPos - 100;
            else if(Q.DialPos < 0) D.DialPos = Q.DialPos + 100;
            else begin
                D.Fsm = S_READ;
                D.Password = Q.DialPos == 0 ? Q.Password + 1 : Q.Password;
            end
            `elsif PART02
            if(Q.DialPos > 99) begin 
                D.DialPos = Q.DialPos - 100;
                D.Password = Q.Password + 1;
            end
            else if(Q.DialPos < 0) begin
                D.DialPos = Q.DialPos + 100;
                D.Password = Q.Password + 1;
            end
            else begin
                D.Fsm = S_READ;
            end
            `endif
            D.DialAcc = '0;
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
