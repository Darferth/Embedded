`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.01.2019 11:41:21
// Design Name: 
// Module Name: comparator
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

/*
module comp_tb();

reg [7:0]a,b;
wire eq;

comparator comp (.a(a), .b(b), .eq(eq));

initial
begin
    a = 8'b01101111;
    b = 8'b01101100;
    #10;
    a = 8'b01101111;
    b = 8'b01101111;
    #10;
    $finish;
end

endmodule
*/

module comparator #(parameter LENGTH = 22)(a,b,eq);

    input [LENGTH-1:0] a;
    input [LENGTH-1:0] b;
    output wire eq;
    
    wire [LENGTH-1:0] local_eq;
     
    genvar i;
    generate
        for(i=0; i<LENGTH; i=i+1) begin:comp
            oneBit_comparator comp_inst (.a(a[i]), .b(b[i]), .eq(local_eq[i]));    
        end:comp
    endgenerate
    
    assign eq = &local_eq;
    
endmodule

module oneBit_comparator(input a, input b, output wire eq);

assign eq = 1 ? a==b : 0;

endmodule
