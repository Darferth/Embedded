`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/01/2019 12:24:28 PM
// Design Name: 
// Module Name: dataRam
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module dataRam
#(
    parameter DATA_WIDTH = 32,
    parameter CACHE_LINES = 128,
    parameter WORD_NUM = 4,
    parameter INDEX_WIDTH = 7,
    parameter WORD_OFFSET_WIDTH = 2
)
(
    
    input clk,
    input [INDEX_WIDTH-1:0] index,
    input [WORD_OFFSET_WIDTH-1:0] offset,
    input [DATA_WIDTH-1:0] data_in,
    input we,
    
    output reg [DATA_WIDTH-1:0] data_out
);

reg [DATA_WIDTH-1:0][WORD_NUM-1:0] mem [CACHE_LINES-1:0];

always@(posedge clk)
begin
    data_out <= mem[index][offset];
    
    if(we) mem[index][offset] = data_in;
end

endmodule
