module Solver
import AocPkg::*;
#(
    parameter GRID_COLUMNS = 138
) 
(
    input logic Clk,
    output RamAddr_t ReadAddr,
    output logic ReadEnable,
    input logic [7:0] ReadData,
    output logic Error,
    output logic Done,
    output logic [15:0] Answer
);

localparam logic [7:0] ASCII_DOT = 8'h2E;
localparam logic [7:0] ASCII_AT = 8'h40;
localparam logic [7:0] ASCII_EOT = 8'h04;

typedef logic [$clog2(GRID_COLUMNS):0] ColumnIter_t;
typedef logic [0:GRID_COLUMNS-1] Row_t;

typedef enum logic [1:0] {
    S_IDLE,
    S_RUN,
    S_DONE,
    S_ERROR
} Fsm_e;

typedef struct packed {
    RamAddr_t ReadAddr;
    logic ReadEnable;
    Fsm_e Fsm;
    ColumnIter_t Column;
    logic ReadCell;
    Row_t PrevRow;
    Row_t CurrRow;
    logic CurrRowValid;
    Row_t NextRow;
    logic NextRowValid;
    logic [15:0] AccessibleRolls;
    logic Error;
    logic Done;
} State_ts;
State_ts Q = '{ReadEnable: 1'b1, Fsm: S_IDLE, default: '0}, D;

assign ReadAddr = Q.ReadAddr;
assign ReadEnable = Q.ReadEnable;
assign Answer = Q.AccessibleRolls;
assign Error = Q.Fsm == S_ERROR;
assign Done = Q.Fsm == S_DONE;

always_comb begin
    D = Q;
    
    case(Q.Fsm)
        S_IDLE: begin
            D.Fsm = S_RUN;
            D.ReadAddr++;
            D.Column = '0;
            D.ReadCell = 1'b1;
        end
        S_RUN: begin
            D.Column++;
            // Read
            if(Q.Column inside {[0:GRID_COLUMNS-1]}) begin
                D.NextRow[Q.Column] = 1'b0;
                if(Q.ReadCell) begin
                    if(Q.Column < GRID_COLUMNS - 1) D.ReadAddr++;
                    case(ReadData)
                        ASCII_AT: D.NextRow[Q.Column] = 1'b1;
                        ASCII_EOT: D.ReadCell = 1'b0;
                    endcase
                    if(Q.Column == GRID_COLUMNS - 1) D.NextRowValid = 1'b1;
                end
            end
            // Count
            if(Q.Column inside {[1:GRID_COLUMNS]}) begin
                // Evaluating CurrRow[Column - 1]
                if(Q.CurrRowValid) begin
                    automatic logic [3:0] adjacentCount = 4'd0;
                    // Top
                    if(Q.PrevRow[Q.Column-1]) adjacentCount++;
                    // Bottom
                    if(Q.NextRow[Q.Column-1]) adjacentCount++;
                    // Left
                    if(Q.Column > 1) begin
                        if(Q.CurrRow[Q.Column-2]) adjacentCount++;
                        if(Q.PrevRow[Q.Column-2]) adjacentCount++;
                        if(Q.NextRow[Q.Column-2]) adjacentCount++;
                    end
                    // Right
                    if(Q.Column < GRID_COLUMNS) begin
                        if(Q.CurrRow[Q.Column]) adjacentCount++;
                        if(Q.PrevRow[Q.Column]) adjacentCount++;
                        // D since this was read on same clock
                        if(D.NextRow[Q.Column]) adjacentCount++; 
                    end
                    if(Q.CurrRow[Q.Column-1] && adjacentCount < 4) begin
                        D.AccessibleRolls++;
                    end
                end
            end
            // Switch rows
            if(Q.Column == GRID_COLUMNS) begin
                D.Column = '0;
                D.PrevRow = Q.CurrRow;
                D.CurrRow = Q.NextRow;
                D.CurrRowValid = Q.NextRowValid;
                D.NextRow = '0;
                D.NextRowValid = 1'b0;
                if(Q.ReadCell) D.ReadAddr++;
                if(!({Q.CurrRowValid, Q.NextRowValid})) begin
                    D.Fsm = S_DONE;
                end
            end
        end       
        S_DONE:;
        S_ERROR:;
    endcase
end

always_ff @(posedge Clk) begin
    Q <= D;
end

endmodule
