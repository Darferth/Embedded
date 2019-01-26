`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.01.2019 15:51:44
// Design Name: 
// Module Name: validRam
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


module validRam

 #(
    parameter INDEX_LENGTH = 4,
    parameter CACHE_LINES = 256
 )
 (   
    input [INDEX_LENGTH-1:0] index_i,
    input we_i,
    //input clk,
    output wire valid_o
  );
  
    reg validRam [CACHE_LINES-1:0];
  
    always@(*)
    begin
        if(we_i)
            validRam[index_i] = 1;      
    end
    
   assign valid_o = validRam[index_i];

endmodule
