module CheckId
#(
    parameter ID_MAX_DIGITS = 10
)
(
    input logic Clk,
    input logic Rst,
    input logic Start,
    input logic [33:0] StartId,
    input [0:ID_MAX_DIGITS-1] [3:0] StartIdBcd,
    input logic [33:0] EndId,
    input [0:ID_MAX_DIGITS-1] [3:0] EndIdBcd,
    output logic [39:0] InvalidIdSum,
    output logic Ready,
    output logic Done
);

// TODO: Parameterize this module better
typedef logic [0:ID_MAX_DIGITS-1] [3:0] BcdArray_t;
typedef logic [$clog2(ID_MAX_DIGITS):0] BcdIter_t;

typedef enum {
    S_IDLE = 0,
    S_SETUP,
    S_CONSTRUCT,
    S_CHECK_MIN,
    S_CHECK_MAX,
    S_CHECK_DONE,
    S_DONE
} Fsm_e;

typedef struct packed {
    Fsm_e Fsm;
    logic [33:0] StartId;
    logic [33:0] EndId;
    BcdIter_t StartIdNumDigits;
    BcdIter_t EndIdNumDigits;
    BcdIter_t CurrNumDigits;
    logic [16:0] LeftHalf;
    logic [33:0] TestId;
    logic [2:0] HalfDigits;
    logic [2:0] HalfDigitMultCount;
    logic [33:0] CurrEndId;
    logic CheckDone;
    logic [39:0] InvalidIdSum;
} State_ts;
State_ts Q = {Fsm: S_IDLE, default: '0}, D;

assign InvalidIdSum = Q.InvalidIdSum;
assign Ready = (Q.Fsm == S_IDLE);

always_comb begin
    D = Q;
    Done = 1'b0;

    case(Q.Fsm)
        S_IDLE: begin
            if(Start) begin
                D.Fsm = S_SETUP;
                D.StartId = StartId;
                D.EndId = EndId;
                D.StartIdNumDigits = GetBcdNumDigits(StartIdBcd);
                D.EndIdNumDigits = GetBcdNumDigits(EndIdBcd);
                D.CurrNumDigits = D.StartIdNumDigits;
            end
        end
        S_SETUP: begin
            automatic BcdIter_t halfDigits = GetHalfDigits(Q.CurrNumDigits);
            D.HalfDigits = halfDigits;
            D.Fsm = S_SETUP;
            D.CurrNumDigits++;
            D.HalfDigitMultCount = 0;
            
            // Next state
            if(Q.CurrNumDigits <= Q.EndIdNumDigits) begin
                if(halfDigits != 0) D.Fsm = S_CONSTRUCT;
            end
            else begin
                D.Fsm = S_DONE;
            end
            // Starting left half
            // TODO: Optimize this
            case(halfDigits)
                5: D.LeftHalf = 10000;
                4: D.LeftHalf = 1000;
                3: D.LeftHalf = 100;
                2: D.LeftHalf = 10;
                1: D.LeftHalf = 0;
            endcase
            // EndId
            if(Q.CurrNumDigits == Q.EndIdNumDigits) begin
                D.CurrEndId = Q.EndId;
            end
            else begin
                case(Q.CurrNumDigits)
                    8: D.CurrEndId = 99999999;
                    6: D.CurrEndId = 999999;
                    4: D.CurrEndId = 9999;
                    2: D.CurrEndId = 99;
                endcase
            end
        end
        S_CONSTRUCT: begin
            D.Fsm = S_CONSTRUCT;
            D.HalfDigitMultCount++;
            if(Q.HalfDigitMultCount == 0) begin
                D.TestId = Q.LeftHalf * 10;
            end
            else if (Q.HalfDigitMultCount < Q.HalfDigits) begin
                D.TestId = Q.TestId * 10;
            end
            else begin
                D.TestId = Q.TestId + Q.LeftHalf;
                D.LeftHalf++;
                D.HalfDigitMultCount = 0;
                D.Fsm = S_CHECK_MIN;
            end
        end
        S_CHECK_MIN: begin
            D.Fsm = S_CHECK_MAX;
            if(Q.TestId < Q.StartId) D.Fsm = S_CONSTRUCT;
        end
        S_CHECK_MAX: begin
            D.Fsm = S_CHECK_DONE;
            if(Q.TestId <= Q.CurrEndId) begin
                D.InvalidIdSum += Q.TestId;
            end
            else begin
                D.CheckDone = 1'b1;
            end
        end
        S_CHECK_DONE: begin
            D.Fsm = Q.CheckDone ? S_SETUP : S_CONSTRUCT;
        end
        S_DONE: begin
            Done = 1'b1;
        end
    endcase
end

always_ff @(posedge Clk) begin
    if (Rst) Q <= '0;
    else Q <= D;
end

function automatic BcdIter_t GetBcdNumDigits(BcdArray_t bcd);
    for(BcdIter_t i = 0; i < ID_MAX_DIGITS; i++) begin
        if(bcd[i] != 4'd0) begin
            return ID_MAX_DIGITS - i;
        end
    end
endfunction

function automatic BcdIter_t GetHalfDigits(BcdArray_t numDigits);
    if(numDigits % 2 == 0) begin
        return numDigits / 2;
    end
    else return 0;
endfunction

endmodule
