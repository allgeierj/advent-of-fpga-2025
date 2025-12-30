module Solver 
import AocPkg::*;
#(
    parameter ID_MAX_DIGITS = 10,
    parameter NUM_CHECKERS = 5
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

// TODO: Parameterize this module better
typedef logic [0:ID_MAX_DIGITS-1] [3:0] BcdArray_t;
typedef logic [$clog2(ID_MAX_DIGITS):0] BcdIter_t;
typedef logic [$clog2(NUM_CHECKERS):0] CheckerIter_t;

typedef enum logic {
    START_ID = 1'b0,
    END_ID
} Id_e;

typedef enum logic [2:0] {
    S_IDLE = 3'd0,
    S_GET_IDS,
    S_CONSTRUCT_ID,
    S_DEPLOY,
    S_POST_DEPLOY,
    S_WAIT,
    S_ERROR,
    S_DONE
} Fsm_e;

typedef struct packed {
    Fsm_e Fsm;
    Id_e Id;
    logic [33:0] StartId;
    BcdArray_t StartIdBCD;
    logic [33:0] EndId;
    BcdArray_t EndIdBCD;
    RomAddr_t Addr;
    CheckerIter_t CheckerDeploy;
    CheckerIter_t CheckerAccum;
    logic [39:0] InvalidIdSum;
} State_ts;
State_ts Q = {Fsm: S_IDLE, Id: START_ID, default: '0}, D;

// Generated checker nets
logic [0:NUM_CHECKERS-1][39:0] CheckerSum;
logic [0:NUM_CHECKERS-1] CheckerDone;
logic [0:NUM_CHECKERS-1] CheckerStart;
logic [0:NUM_CHECKERS-1] CheckerReady;
logic [0:NUM_CHECKERS-1] CheckerRst;

genvar genChecker;
generate
    for(genChecker = 0; genChecker < NUM_CHECKERS; genChecker++) begin : GEN_CHECKERS
        CheckId #(
            .ID_MAX_DIGITS(ID_MAX_DIGITS)
        ) CheckId_u 
        (
            .Clk(Clk),
            .Rst(CheckerRst[genChecker]),
            .Start(CheckerStart[genChecker]),
            .StartId(Q.StartId),
            .StartIdBcd(Q.StartIdBCD),
            .EndId(Q.EndId),
            .EndIdBcd(Q.EndIdBCD),
            .InvalidIdSum(CheckerSum[genChecker]),
            .Ready(CheckerReady[genChecker]),
            .Done(CheckerDone[genChecker])
        );
    end
endgenerate

always_comb begin
    D = Q;
    Error = 1'b0;
    Done = 1'b0;
    CheckerStart = '0;
    CheckerRst = '0;
    
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
                            D.StartId = (Q.StartId * 10);// + (Data - 8'h30);
                            D.StartIdBCD[9] = Data - 8'h30;
                            for(BcdIter_t i = 0; i < ID_MAX_DIGITS - 1; i++) begin
                                D.StartIdBCD[i] = Q.StartIdBCD[i + 1];
                            end
                        end
                        END_ID: begin
                            D.EndId = (Q.EndId * 10);// + (Data - 8'h30);
                            D.EndIdBCD[9] = Data - 8'h30;
                            for(BcdIter_t i = 0; i < ID_MAX_DIGITS - 1; i++) begin
                                D.EndIdBCD[i] = Q.EndIdBCD[i + 1];
                            end
                        end
                    endcase
                    // Addr = Q.Addr + 1;
                    D.Fsm = S_CONSTRUCT_ID;
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
                        END_ID: D.Fsm = S_DEPLOY;
                        default: D.Fsm = S_ERROR;
                    endcase
                end
                default: begin
                    D.Fsm = S_ERROR;
                end
            endcase
        end
        S_CONSTRUCT_ID: begin
            D.Fsm = S_GET_IDS;
            Addr = Q.Addr + 1;
            case(Q.Id)
                START_ID: D.StartId += (Data - 8'h30);
                END_ID: D.EndId += (Data - 8'h30);
            endcase
        end
        S_DEPLOY: begin
            if(CheckerReady[Q.CheckerDeploy]) begin
                CheckerStart[Q.CheckerDeploy] = 1'b1;
                D.Fsm = S_POST_DEPLOY;
            end
            D.CheckerDeploy = Q.CheckerDeploy == (NUM_CHECKERS - 1) ? 0 : Q.CheckerDeploy + 1;
        end
        S_POST_DEPLOY: begin
            Addr = Q.Addr + 1;
            D.Fsm = S_GET_IDS;
            D.StartId = '0;
            D.StartIdBCD = '0;
            D.EndId = '0;
            D.EndIdBCD = '0;
            D.Id = START_ID;
            if(Data == ASCII_EOT) begin
                D.Fsm = S_WAIT;
            end
        end
        S_WAIT: begin
            if(&CheckerReady) begin
                D.Fsm = S_DONE;
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

    if(CheckerDone[Q.CheckerAccum]) begin
        D.InvalidIdSum += CheckerSum[Q.CheckerAccum];
        CheckerRst[Q.CheckerAccum] = 1'b1;
    end
    D.CheckerAccum = Q.CheckerAccum == (NUM_CHECKERS - 1) ? 0 : Q.CheckerAccum + 1;
end

always_ff @(posedge Clk) begin
    Q <= D;
end

endmodule
