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
    `ifdef PART02
    output RamAddr_t WriteAddr,
    output logic WriteEnable,
    output logic [7:0] WriteData,
    `endif
    output logic Error,
    output logic Done,
    output logic [15:0] Answer
);

localparam logic [7:0] ASCII_DOT = 8'h2E;
localparam logic [7:0] ASCII_AT = 8'h40;
localparam logic [7:0] ASCII_X = 8'h58;
localparam logic [7:0] ASCII_EOT = 8'h04;

typedef logic [$clog2(GRID_COLUMNS):0] ColumnIter_t;
typedef logic [0:GRID_COLUMNS-1] Row_t;
typedef logic [0:2] RowWindow_t;

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
    RowWindow_t PrevRowWindow;
    RowWindow_t CurrRowWindow;
    logic EvalCellIsRoll;
    logic [15:0] AccessibleRolls;
    `ifdef PART02
    logic IsFirstRow;
    RamAddr_t WriteAddr;
    logic WriteEnable;
    logic [7:0] WriteData;
    RamAddr_t CurrRowStartAddr;
    logic CurrIterRollRemoved;
    `endif
    logic Error;
    logic Done;
} State_ts;
State_ts Q = '{ReadEnable: 1'b1, Fsm: S_IDLE, default: '0}, D;

assign ReadAddr = Q.ReadAddr;
assign ReadEnable = Q.ReadEnable;
assign Answer = Q.AccessibleRolls;
`ifdef PART02
assign WriteAddr = Q.WriteAddr;
assign WriteEnable = Q.WriteEnable;
assign WriteData = Q.WriteData;
`endif
assign Error = Q.Fsm == S_ERROR;
assign Done = Q.Fsm == S_DONE;

always_comb begin
    D = Q;
    `ifdef PART02 D.WriteEnable = 1'b0; `endif
    
    case(Q.Fsm)
        S_IDLE: begin
            D.Fsm = S_RUN;
            D.ReadAddr++;
            D.Column = '0;
            D.ReadCell = 1'b1;
            `ifdef PART02
            D.IsFirstRow = 1'b1;
            D.CurrRowStartAddr = '0; 
            `endif
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
            // Row window for Prev and Curr rows
            // Reduces muxing for adjacent count logic
            D.PrevRowWindow = '0;
            D.CurrRowWindow = '0;
            if(Q.Column inside {[0:GRID_COLUMNS-1]}) begin
                if(Q.Column > 0) begin
                    D.PrevRowWindow[0] = Q.PrevRow[Q.Column-1];
                    D.CurrRowWindow[0] = Q.CurrRow[Q.Column-1];
                end
                D.PrevRowWindow[1] = Q.PrevRow[Q.Column];
                D.CurrRowWindow[1] = Q.CurrRow[Q.Column];
                if(Q.Column < GRID_COLUMNS - 1) begin
                    D.PrevRowWindow[2] = Q.PrevRow[Q.Column+1];
                    D.CurrRowWindow[2] = Q.CurrRow[Q.Column+1];
                end
                D.EvalCellIsRoll = Q.CurrRow[Q.Column];
            end
            // Count
            if(Q.Column inside {[1:GRID_COLUMNS]}) begin
                // Evaluating CurrRow[Column - 1]
                if(Q.CurrRowValid) begin
                    automatic logic [3:0] adjacentCount = 4'd0;
                    // Top
                    if(Q.PrevRowWindow[1]) adjacentCount++;
                    // Bottom
                    if(Q.NextRow[Q.Column-1]) adjacentCount++;
                    // Left
                    if(Q.Column > 1) begin
                        if(Q.CurrRowWindow[0]) adjacentCount++;
                        if(Q.PrevRowWindow[0]) adjacentCount++;
                        if(Q.NextRow[Q.Column-2]) adjacentCount++;
                    end
                    // Right
                    if(Q.Column < GRID_COLUMNS) begin
                        if(Q.CurrRowWindow[2]) adjacentCount++;
                        if(Q.PrevRowWindow[2]) adjacentCount++;
                        // D since this was read on same clock
                        if(D.NextRow[Q.Column]) adjacentCount++; 
                    end
                    if(Q.EvalCellIsRoll && adjacentCount < 4) begin
                        D.AccessibleRolls++;
                        `ifdef PART02
                        D.CurrIterRollRemoved = 1'b1;
                        D.CurrRow[Q.Column-1] = 1'b0;
                        D.WriteAddr = Q.CurrRowStartAddr + (Q.Column - 1);
                        D.WriteData = ASCII_X;
                        D.WriteEnable = 1'b1;
                        `endif
                    end
                end
            end
            // Shift rows
            if(Q.Column == GRID_COLUMNS) begin
                D.Column = '0;
                D.PrevRow = Q.CurrRow;
                D.CurrRow = Q.NextRow;
                D.CurrRowValid = Q.NextRowValid;
                D.NextRow = '0;
                D.NextRowValid = 1'b0;

                `ifdef PART02
                D.IsFirstRow = 1'b0;
                if(!Q.IsFirstRow) D.CurrRowStartAddr += GRID_COLUMNS;
                else D.CurrRowStartAddr = '0;
                `endif

                if(Q.ReadCell) D.ReadAddr++;
                if(!({Q.CurrRowValid, Q.NextRowValid})) begin
                    `ifdef PART01
                    D.Fsm = S_DONE;
                    `elsif PART02
                    D.CurrIterRollRemoved = 1'b0;
                    if(Q.CurrIterRollRemoved) begin
                        D.ReadAddr = '0;
                        D.Fsm = S_IDLE;
                        D.PrevRow = '0;
                        D.CurrRow = '0;
                    end
                    else begin
                        D.Fsm = S_DONE;
                    end
                    `endif
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
