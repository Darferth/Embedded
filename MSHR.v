`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.12.2018 10:35:22
// Design Name: 
// Module Name: MSHR
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


module MSHR(

    input clk,
    input rst,
    input cache_line_i,
    input mem_line_i,
    
    output reg cache_line_o,
    output reg mem_line_o

    );
    
    wire inner_slot_1;
    wire inner_slot_2;
    
    always@(posedge clk)
    begin
        if(rst==1'b1)
        begin
            cache_line_o <= 1'b0;
            mem_line_o <= 1'b0;
        end
        else
        begin
            cache_line_o <= inner_slot_2;
            mem_line_o <= inner_slot_1;
        end
    end
    
    assign inner_slot_1 = cache_line_i;
    assign inner_slot_2 = mem_line_i;
    
endmodule
