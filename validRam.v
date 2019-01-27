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
    input valid_i,
    input deload_i,
    //input clk,
    input rst,
    
    output reg valid_o
);
  
    reg validRam [CACHE_LINES-1:0];
    reg i; // <-- genvar?
  
    always@(*)
    begin
        if(rst)
        begin            
            for(i=0; i<CACHE_LINES; i=i+1)
                validRam[i]=1'bx;
        end
        else
        begin
            if(we_i)
                validRam[index_i] = valid_i;
            valid_o = validRam[index_i]; 
            
            if(deload_i)
                validRam[index_i] = 1'bx;
        end
    end
endmodule
