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
module mor1kx_int_tb
#(
    parameter ADR_WIDTH     =   32,
    parameter DATA_WIDTH    =   32,
    parameter WORD_OFFSET   =    2,
    parameter DATAMEM_WIDTH =   128
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
wire    [DATAMEM_WIDTH-1:0]    dat_cc2mshr;


always #5 clk=~clk;

initial
begin
    
    clk         <= 0;
    rst          = 1'b1;
    @(posedge clk);
    rst         <= 1'b0;
    
    //first req
    @(posedge clk);
    adr_cpu2cc  <= 32'b11111111000001111011110100001000;
    rdwr_cpu2cc <= 1'b0;
    req_cpu2cc  <= 1'b1;
    repeat(3) @(posedge clk);
    repeat(4)
    begin
        ack_mem2cc  <= 1'b1;
        dat_mem2cc  <= {32{1'b1}};
        @(posedge clk);     
        ack_mem2cc <= 1'b0;
        @(posedge clk); 
    end
    req_cpu2cc <= 1'b0;
    
    repeat(2)@(posedge clk);
    
    
    //first req
    @(posedge clk);
    adr_cpu2cc  <= 32'b10100101010101010010110100001000;
    rdwr_cpu2cc <= 1'b0;
    req_cpu2cc  <= 1'b1;
    repeat(3) @(posedge clk);
    repeat(4)
    begin
        ack_mem2cc  <= 1'b1;
        dat_mem2cc  <= {32{1'b1}};
        @(posedge clk);     
        ack_mem2cc <= 1'b0;
        @(posedge clk); 
    end
    req_cpu2cc <= 1'b0;
    
    repeat(2)@(posedge clk);
        
    //first req
    @(posedge clk);
    adr_cpu2cc  <= 32'b11010101000000001010110100001000;
    rdwr_cpu2cc <= 1'b0;
    req_cpu2cc  <= 1'b1;
    repeat(3) @(posedge clk);
    repeat(4)
    begin
        ack_mem2cc  <= 1'b1;
        dat_mem2cc  <= {32{1'b1}};
        @(posedge clk);     
        ack_mem2cc <= 1'b0;
        @(posedge clk); 
    end
    req_cpu2cc <= 1'b0;
    
    repeat(2)@(posedge clk);
        
    //first req
    @(posedge clk);
    adr_cpu2cc  <= 32'b11111111111111111111110100001000;
    rdwr_cpu2cc <= 1'b0;
    req_cpu2cc  <= 1'b1;
    repeat(3) @(posedge clk);
    repeat(4)
    begin
        ack_mem2cc  <= 1'b1;
        dat_mem2cc  <= {32{1'b1}};
        @(posedge clk);     
        ack_mem2cc <= 1'b0;
        @(posedge clk); 
    end
    req_cpu2cc <= 1'b0;
    
    repeat(2)@(posedge clk);
        
    //five: read hit 0way
    @(posedge clk);
    adr_cpu2cc  <= 32'b11111111000001111011110100001000;
    rdwr_cpu2cc <= 1'b0;
    req_cpu2cc  <= 1'b1;
    repeat(3) @(posedge clk);
    req_cpu2cc <= 1'b0;
    
    repeat(2)@(posedge clk);
    
    //six: write hit 3way
    @(posedge clk);
    adr_cpu2cc  <= 32'b11111111111111111111110100001000;
    rdwr_cpu2cc <= 1'b1;
    req_cpu2cc  <= 1'b1;
    dat_cpu2cc  <= 32'b10101010100010101010101010100100; 
    repeat(3) @(posedge clk);
    req_cpu2cc <= 1'b0;
    
    #50
    
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