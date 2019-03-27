`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.02.2019 17:20:57
// Design Name: 
// Module Name: 4_way_tb
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
module cache_tb#
(
    parameter ADR_WIDTH     =   32,
    parameter DATA_WIDTH    =   32,
    parameter WORD_OFFSET   =    2
)
();

        //CONTROL SIGNALS
reg                         clk;
reg                         rst;

        //CPU SIGNALS
reg                         req_cpu2cc;
reg     [ADR_WIDTH-1:0]     adr_cpu2cc;
reg     [DATA_WIDTH-1:0]    dat_cpu2cc;
reg                         rdwr_cpu2cc;
wire                        ack_cc2cpu;
wire    [DATA_WIDTH-1:0]    dat_cc2cpu;

        //MEM SIGNALS
reg                         ack_mem2cc;
reg     [DATA_WIDTH-1:0]    dat_mem2cc;
wire                        req_cc2mem;
wire    [ADR_WIDTH-1:0]     adr_cc2mem;

        //MSHR SIGNALS
wire    [DATA_WIDTH-1:0]    dat_mem2mshr;
wire    [WORD_OFFSET-1:0]   word_mem2mshr;
wire    [DATA_WIDTH-1:0]    dat_cc2mshr;


always #5 clk=~clk;

initial
begin
    
    clk         <=      0;
    rst          =      1'b0;
    
    #10
    
    /*READ REQUEST MISS, FREE CACHE =>
     ALLOCATES IN CACHE THE LINE, THEN READS WORD*/
    rst         <=      1'b1;
    
    #10
    rst         <=      1'b0;
    #10
    
    /*
    adr_cpu2cc  <=      32'b00000000110011000011101101000000;
    rdwr_cpu2cc <=      1'b0;
    req_cpu2cc  <=      1'b1;
    #55
    ack_mem2cc  <=      1'b1;
    dat_mem2cc  <=      32'b1110101010011001101010010100101;
    #10
    ack_mem2cc  <=      1'b0;
    #30
    ack_mem2cc  <=      1'b1;
    dat_mem2cc  <=      32'b1110101010011001101010010111101;
    #10
    ack_mem2cc  <=      1'b0;
    #30
    ack_mem2cc  <=      1'b1;
    dat_mem2cc  <=      32'b1110101010011001011010010100101;
    #10
    ack_mem2cc  <=      1'b0;
    #30
    ack_mem2cc  <=      1'b1;
    dat_mem2cc  <=      32'b1110101010000001101010010100101;
    #10
    ack_mem2cc  <=      1'b0;
    #5
    req_cpu2cc  <=      1'b0;
    
    #40
    
    adr_cpu2cc  <=      32'b00000000110011000011101101000000;
    rdwr_cpu2cc <=      1'b1;
    req_cpu2cc  <=      1'b1;
    dat_cpu2cc<=        32'b11111111111111111111111111111111;
    
    #20 
    
    req_cpu2cc  <=      1'b0;
    
    #40
    
    adr_cpu2cc  <=      32'b11111111000001111011110100001000;
    rdwr_cpu2cc <=      1'b1;
    req_cpu2cc  <=      1'b1;
    dat_cpu2cc<=        32'b11001100110011001100110011001100; 
    #40
    ack_mem2cc  <=      1'b1;
    dat_mem2cc  <=      32'b01001111010100001111010100010101;
    #10
    ack_mem2cc  <=      1'b0;
    #10
    ack_mem2cc  <=      1'b1;
    dat_mem2cc  <=      32'b11111111110000000000100000000100;
    #10
    ack_mem2cc  <=      1'b0;
    #10
    ack_mem2cc  <=      1'b1;
    dat_mem2cc  <=      32'b11111000100101010001010100000101;
    #10
    ack_mem2cc  <=      1'b0;
    #10
    ack_mem2cc  <=      1'b1;
    dat_mem2cc  <=      32'b11101000111110010101011111100101;
    #10
    ack_mem2cc  <=      1'b0;
    #5 
        
    req_cpu2cc  <=      1'b0;
    */
    
    adr_cpu2cc  <=      32'b11111111000001111011110100001000;
    rdwr_cpu2cc <=      1'b1;
    req_cpu2cc  <=      1'b1;
    dat_cpu2cc<=        32'b00000001010111111101111100011110;
    #55
    ack_mem2cc  <=      1'b1;
    dat_mem2cc  <=      32'b11110101010011001101010010100101;
    #10
    ack_mem2cc  <=      1'b0;
    #30
    ack_mem2cc  <=      1'b1;
    dat_mem2cc  <=      32'b11110101010011001101010010111101;
    #10
    ack_mem2cc  <=      1'b0;
    #30
    ack_mem2cc  <=      1'b1;
    dat_mem2cc  <=      32'b11110101010011001011010010100101;
    #10
    ack_mem2cc  <=      1'b0;
    #30
    ack_mem2cc  <=      1'b1;
    dat_mem2cc  <=      32'b11110101010000001101010010100101;
    #10
    ack_mem2cc  <=      1'b0;
    #5
    req_cpu2cc  <=      1'b0;
    #40
    adr_cpu2cc  <=      32'b00010101100010101010110100001000;
    rdwr_cpu2cc <=      1'b1;
    req_cpu2cc  <=      1'b1;
    dat_cpu2cc<=        32'b11001100110011001100110011001100; 
    #40
    ack_mem2cc  <=      1'b1;
    dat_mem2cc  <=      32'b01001111010100001111010100010101;
    #10
    ack_mem2cc  <=      1'b0;
    #10
    ack_mem2cc  <=      1'b1;
    dat_mem2cc  <=      32'b11111111110000000000100000000100;
    #10
    ack_mem2cc  <=      1'b0;
    #10
    ack_mem2cc  <=      1'b1;
    dat_mem2cc  <=      32'b11111000100101010001010100000101;
    #10
    ack_mem2cc  <=      1'b0;
    #10
    ack_mem2cc  <=      1'b1;
    dat_mem2cc  <=      32'b11101000111110010101011111100101;
    #10
    ack_mem2cc  <=      1'b0;
    #5 
    #100
    
//    /*READ REQUEST MISS, FREE CACHE=> ASSUMING (TAG+INDEX+4bit)
//    ALLOCATES IN ANOTHER WAY, SAME INDEX AS BEFORE(FIRST BIT OF TAG 0 INSTEAD OF 1)
//    MEM VALUE MISSING, NEED TO ADD IT
    
//    adr_cpu2cc<=32'b00000000110011000011001101000011;
//    rdwr_cpu2cc<=1'b0;
//    req_cpu2cc<=1'b1;
    
//    #10
    
//    req_cpu2cc<=1'bx;
//    adr_cpu2cc<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
//    dat_cpu2cc<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
//    rdwr_cpu2cc<=1'bx;
    
//    #10
    
   
    
//    req_cpu2cc<=1'bx;
//    adr_cpu2cc<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
//    dat_cpu2cc<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
//    rdwr_cpu2cc<=1'bx;
    
//    #10
    
//    /*FILL A 4 WAY BLOCK IN ORDER TO INDUCE A READ MISS/WRITE MISS WITH REFILL*/
//    adr_cpu2cc<=32'b00000000110011000010001101000011;
//    rdwr_cpu2cc<=1'b0;
//    req_cpu2cc<=1'b1;
    
//    #10
    
//    req_cpu2cc<=1'bx;
//    adr_cpu2cc<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
//    dat_cpu2cc<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
//    rdwr_cpu2cc<=1'bx;
    
//    #10
    
//    adr_cpu2cc<=32'b00000000110011000000001101000011;
//    rdwr_cpu2cc<=1'b0;
//    req_cpu2cc<=1'b1;
    
//    #10
    
//    req_cpu2cc<=1'bx;
//    adr_cpu2cc<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
//    dat_cpu2cc<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
//    rdwr_cpu2cc<=1'bx;
        
//    #10
    
//    /*READ MISS, NO SPACE LEFT IN THE SAME INDEX=>
//    REPLACE THE OLDEST LINE WITH THE ONE REQUESTED
//    MEM VALUE MISSING, NEED TO ADD IT*/ 
//    adr_cpu2cc<=32'b00000000110011100000001101000011;
//    rdwr_cpu2cc<=1'b0;
//    req_cpu2cc<=1'b1;
    
//    #10
    
//    req_cpu2cc<=1'b0;
//    adr_cpu2cc<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
//    dat_cpu2cc<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
//    rdwr_cpu2cc<=1'bx;
            
//    #10
    
//    /*WRITE MISS, NO SPACE LEFT IN THE SAME INDEX=>
//    REPLACE THE OLDEST LINE WITH THE ONE IN WHICH I WRITE THE WORD
//    MEM VALUE MISSING, NEED TO ADD IT*/
//    adr_cpu2cc<=32'b00000000100001000011101101000011;
//    dat_cpu2cc<=32'b11101010100110011010100101001010;
//    rdwr_cpu2cc<=1'b1;
//    req_cpu2cc<=1'b1;
    
//    #10
    
    
    $finish;
end

 cache4way cache_4way0(
                        .clk(clk), 
                        .rst(rst), 
                        .req_cpu2cc(req_cpu2cc), 
                        .adr_cpu2cc(adr_cpu2cc), 
                        .dat_cpu2cc(dat_cpu2cc),
                        .rdwr_cpu2cc(rdwr_cpu2cc),
                        .ack_cc2cpu(ack_cc2cpu), 
                        .dat_cc2cpu(dat_cc2cpu), 
                        .req_cc2mem(req_cc2mem), 
                        .adr_cc2mem(adr_cc2mem), 
                        .ack_mem2cc(ack_mem2cc),
                        .dat_mem2cc(dat_mem2cc),
                        .dat_mem2mshr(dat_mem2mshr), 
                        .word_mem2mshr(word_mem2mshr), 
                        .dat_cc2mshr(dat_cc2mshr)
                       );

endmodule
