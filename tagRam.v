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


module tagRam
#(
    parameter TAG_WIDTH = 25,
    parameter CACHE_LINES = 128,
    parameter INDEX_WIDTH = 7
)
(
    
    input clk,
    input [INDEX_WIDTH-1:0] index,
    input [TAG_WIDTH-1:0] data_in,
    input we,
    
    output reg [TAG_WIDTH-1:0] data_out
);


reg [TAG_WIDTH-1:0] mem [CACHE_LINES-1:0];

always@(posedge clk)
begin
    data_out <= mem[index];
    
    if(we) mem[index] <= data_in;
end

endmodule
