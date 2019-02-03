`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.01.2019 20:58:27
// Design Name: 
// Module Name: dcache_tb
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

`define WAY_NUMBER 2
`define ADR_LENGTH 32
`define INDEX_LENGTH 7
`define TAG_LENGTH 22
`define DATA_LENGTH 32
`define CACHE_LINES 32

module dcache_tb();

    reg clk;
    reg rst;
    reg cc_req_i;
    reg cc_we_i;
    reg [`DATA_LENGTH-1:0] cc_dat_i;
    reg [`ADR_LENGTH-1:0] cc_adr_i;
    reg cc_deload_i;
    
    wire [`DATA_LENGTH-1:0] cache_dat_o;
    wire cache_hit_o;
    wire cache_free_o;
    
    always #5 clk = ~clk;
    
    initial
    begin
    
        clk = 0;
        /*
        cc_req_i <= 1'b1;
        cc_we_i <= 1'b1;
        cc_dat_i <= 32'b11101010100110011010100101001010;
        cc_adr_i <= 32'b00000000110011000011101101000011;
        #5
        cc_req_i <= 1'bx;
        cc_we_i <= 1'bx;
        cc_dat_i <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
        cc_adr_i <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
        #5
        cc_req_i <= 1'b1;
        cc_we_i <= 1'b1;
        cc_dat_i <= 32'b11111111110000000000001110010011;
        cc_adr_i <= 32'b00000111010010101001100111110101;
        #5
        cc_req_i <= 1'bx;
        cc_we_i <= 1'bx;
        cc_dat_i <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
        cc_adr_i <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
        #5
        cc_req_i <= 1'b1;
        cc_we_i <= 1'b0;
        cc_adr_i <= 32'b00000000110011000011101101000011;
        #5
        cc_req_i <= 1'bx;
        cc_we_i <= 1'bx;
        cc_dat_i <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
        cc_adr_i <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
        #5
        cc_req_i <= 1'b1;
        cc_we_i <= 1'b1;
        cc_dat_i <= 32'b00000000000000011111111111110101;
        cc_adr_i <= 32'b00000000111100111111111111111111;
        #5
        cc_req_i <= 1'bx;
        cc_we_i <= 1'bx;
        cc_dat_i <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
        cc_adr_i <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
        */
        
        /* lettura e scrittura easy */
        /*
        cc_req_i <= 1'b1;
        cc_we_i <= 1'b1;
        cc_dat_i <= 32'b11101010100110011010100101001010;
        cc_adr_i <= 32'b00000000110011000011101101000011;
        #5
        cc_req_i <= 1'bx;
        cc_we_i <= 1'bx;
        cc_dat_i <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
        cc_adr_i <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
        #5
        cc_req_i <= 1'b1;
        cc_we_i <= 1'b0;
        cc_adr_i <= 32'b00000000110011000011101101000011;
        #5
        */
        
        cc_req_i <= 1'b1;
        cc_we_i <= 1'b1;
        cc_dat_i <= 32'b11101010100110011010100101001010;
        cc_adr_i <= 32'b00000000110011000011101101000011;
        #5
        cc_req_i <= 1'bx;
        cc_we_i <= 1'bx;
        cc_dat_i <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
        cc_adr_i <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
        #5
        cc_req_i <= 1'b1;
        cc_we_i <= 1'b1;
        cc_dat_i <= 32'b00010100000011111111111000111111;
        cc_adr_i <= 32'b00000000110011000011111111000011;
        #5
        cc_req_i <= 1'bx;
        cc_we_i <= 1'bx;
        cc_dat_i <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
        cc_adr_i <= 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
        #5
        
        
        $finish;
    
    end
    
    dcache cache(.rst(rst), .cc_req_i(cc_req_i), .cc_we_i(cc_we_i), .cc_dat_i(cc_dat_i), .cc_adr_i(cc_adr_i), .cc_deload_i(cc_deload_i),
                 .cache_dat_o(cache_dat_o), .cache_hit_o(cache_hit_o), .cache_free_o(cache_free_o), .clk(clk));

endmodule
