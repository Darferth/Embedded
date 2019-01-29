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


module mux2to1#(parameter DATA_WIDTH=32)(

    input [DATA_WIDTH-1:0] a,
    input [DATA_WIDTH-1:0] b,
    output reg [DATA_WIDTH-1:0] out,
    input sel1,
    input sel2);
    
    always@(*)
    begin
        if(sel1==1'b1)
            out = a;
        else if(sel2==1'b1)
            out = b;
        else
            out = {DATA_WIDTH{1'bx}};
    end
    
    endmodule
