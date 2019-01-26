`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.01.2019 15:21:05
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
    parameter INDEX_LENGTH = 4,
    parameter DATA_LENGTH = 32,
    parameter CACHE_LINES = 256
 )
 (   
    input [INDEX_LENGTH-1:0] index_i,
    input [DATA_LENGTH-1:0] data_i,
    input we_i,
    //input clk,
    output wire [DATA_LENGTH-1:0] data_o
  );
  
    reg [DATA_LENGTH-1:0] dataRam [CACHE_LINES-1:0];
  
    always@(*)
    begin
        if(we_i)
            dataRam[index_i] = data_i;      
    end
    
   assign data_o = dataRam[index_i];
  
endmodule
