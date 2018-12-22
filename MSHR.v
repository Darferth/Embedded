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
    input cache_adr_i,
    input cache_dat_i,
    input mem_adr_i,
    input mem_dat_i,
    
    output cache_adr_o,
    output cache_dat_o,
    output mem_adr_o,
    output mem_dat_o

    );
    
    reg adr_slot_1, dat_slot_1;
    reg adr_slot_2, dat_slot_2;
    
    always@(*)
    begin
        adr_slot_1 = cache_adr_i;
        dat_slot_1 = cache_dat_i;
        adr_slot_2 = mem_adr_i;
        dat_slot_2 = mem_dat_i;
    end
    
    assign cache_adr_o = adr_slot_1;
    assign cache_dat_o = dat_slot_1;
    assign mem_adr_o = adr_slot_2;
    assign mem_dat_o = dat_slot_2;
    
    
    /*always@(posedge clk)
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
    end*/
        
endmodule
