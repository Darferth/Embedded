`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.01.2019 12:21:36
// Design Name: 
// Module Name: mux2to1
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
    parameter INDEX_LENGTH = 4,
    parameter TAG_LENGTH = 22,
    parameter CACHE_LINES = 256,
    parameter RESET_VALUE = 22'bx
)
(   
    input [INDEX_LENGTH-1:0] index_i,
    input [TAG_LENGTH-1:0] tag_i,
    input we_i,
    input deload_i,
    //input clk,
    input rst,
    
    output reg [TAG_LENGTH-1:0] tag_o,
    output wire free_o
);
    
    reg [TAG_LENGTH-1:0] tagRam [CACHE_LINES-1:0];
    reg i; // <-- genvar?
      
    always@(*)
    begin
        if(rst)
        begin            
            for(i=0; i<CACHE_LINES; i=i+1)
                tagRam[i]=RESET_VALUE;
        end
        else
        begin
            if(we_i && tagRam[index_i]==RESET_VALUE)
            begin
                tagRam[index_i] = tag_i;
            end
           
            tag_o = tagRam[index_i];
            
            if(deload_i)
            begin
                tagRam[index_i] = RESET_VALUE;
            end
        end
    end
    
    assign free_o = 1'b1 ? tagRam[index_i]==RESET_VALUE : 1'b0;
    
endmodule
