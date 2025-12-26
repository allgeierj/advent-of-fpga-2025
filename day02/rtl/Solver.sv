module Solver 
import AocPkg::*;
#(
    parameter ID_MAX_DIGITS = 10
)
(
    input logic Clk,
    output RomAddr_t Addr,
    input logic [7:0] Data,
    output logic Error,
    output logic Done
);

localparam logic [7:0] ASCII_DASH = 8'h2D;
localparam logic [7:0] ASCII_COMMA = 8'h2C;
localparam logic [7:0] ASCII_EOT = 8'h04;

typedef logic [0:ID_MAX_DIGITS-1] [3:0] BcdArray_t;

typedef enum logic {
    START_ID = 1'b0,
    END_ID
} Id_e;

typedef enum logic [2:0] {
    S_IDLE = 3'd0,
    S_GET_IDS,
    S_CALCULATE,
    S_ERROR,
    S_DONE
} Fsm_e;

typedef struct packed {
    Fsm_e Fsm;
    Id_e Id;
    logic [39:0] StartId;
    BcdArray_t StartIdBCD;
    logic [39:0] EndId;
    RomAddr_t Addr;
    // Solver
    logic [39:0] CurrentId;
    BcdArray_t CurrentIdBCD;
    logic [63:0] InvalidIdSum;
} State_ts;
State_ts Q = {Fsm: S_IDLE, Id: START_ID, default: '0}, D;

always_comb begin
    D = Q;
    Error = 1'b0;
    Done = 1'b0;
    
    case(Q.Fsm)
        S_IDLE: begin
            Addr = '0;
            D.Fsm = S_GET_IDS;
        end
        S_GET_IDS: begin
            case(Data) inside
                [8'h30 : 8'h39]: begin
                    case(Q.Id)
                        START_ID: begin
                            D.StartId = (Q.StartId * 10) + (Data - 8'h30);
                            D.StartIdBCD[9] = Data - 8'h30;
                            for(logic [3:0] i = 0; i < ID_MAX_DIGITS - 1; i++) begin
                                D.StartIdBCD[i] = Q.StartIdBCD[i + 1];
                            end
                        end
                        END_ID: begin
                            D.EndId = (Q.EndId * 10) + (Data - 8'h30);
                        end
                    endcase
                    Addr = Q.Addr + 1;
                end
                ASCII_DASH: begin
                    case(Q.Id)
                        START_ID: begin
                            D.Id = END_ID;
                            Addr = Q.Addr + 1;
                        end
                        END_ID: D.Fsm = S_ERROR;
                    endcase
                end
                ASCII_COMMA, ASCII_EOT: begin
                    case(Q.Id)
                        END_ID: begin
                            D.Fsm = S_CALCULATE;
                            D.CurrentId = Q.StartId;
                            D.CurrentIdBCD = Q.StartIdBCD;
                        end
                        default: D.Fsm = S_ERROR;
                    endcase
                end
                default: begin
                    D.Fsm = S_ERROR;
                end
            endcase
        end
        S_CALCULATE: begin
            if (IsInvalidIdBcd(Q.CurrentIdBCD)) begin
                D.InvalidIdSum += Q.CurrentId;
            end
            D.CurrentId++;
            D.CurrentIdBCD = IncrementIdBcd(Q.CurrentIdBCD);
            if (Q.CurrentId == Q.EndId) begin
                if(Data == ASCII_EOT) begin
                    D.Fsm = S_DONE;
                end 
                else begin
                    Addr = Q.Addr + 1;
                    D.StartId = '0;
                    D.StartIdBCD = '0;
                    D.EndId = '0;
                    D.Id = START_ID;
                    D.Fsm = S_GET_IDS;
                end
            end
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

function automatic BcdArray_t IncrementIdBcd(BcdArray_t bcd);
    BcdArray_t result = bcd;
    result[ID_MAX_DIGITS - 1] += 4'd1;
    for(logic [3:0] i = ID_MAX_DIGITS - 1; i >= 1; i--) begin
        if(result[i] > 4'd9) begin
            result[i] = 4'd0;
            result[i - 1] += 4'd1;
        end
    end
    return result;
endfunction

function automatic logic IsInvalidIdBcd(BcdArray_t bcd);
    automatic logic [3:0] msbIndex = ID_MAX_DIGITS - 1;
    for(logic [3:0] i = 0; i < ID_MAX_DIGITS; i++) begin
        if(bcd[i] != 4'd0) begin
            msbIndex = i;
            break;
        end
    end
    case(msbIndex) 
        4'd0: return (bcd[0+:5] == bcd[5+:5]);
        4'd2: return (bcd[2+:4] == bcd[6+:4]);
        4'd4: return (bcd[4+:3] == bcd[7+:3]);
        4'd6: return (bcd[6+:2] == bcd[8+:2]);
        4'd8: return (bcd[8+:1] == bcd[9+:1]);
        default: return 1'b0;
    endcase    
endfunction

endmodule
