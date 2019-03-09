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
module cacheController_tb
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
reg                         lb_cpu2cc;
reg                         lbu_cpu2cc;
wire                        ack_cc2cpu;
wire    [DATA_WIDTH-1:0]    dat_cc2cpu;

        //MEM SIGNALS
reg                         ack_mem2cc;
reg     [DATA_WIDTH-1:0]    dat_mem2cc;
wire                        req_cc2mem;
wire    [ADR_WIDTH-1:0]     adr_cc2mem;

always #5 clk=~clk;

initial
begin
    
    #100
    
    clk         <= 0;
    rst          = 1'b1;
    req_cpu2cc <= 1'b0;
    ack_mem2cc <= 1'b0;
    rdwr_cpu2cc<= 1'b0;
    dat_cpu2cc <= {32{1'b0}};
    adr_cpu2cc <= {32{1'b0}};
    dat_mem2cc <= {32{1'b0}};
    lb_cpu2cc  <= 1'b0;
    lbu_cpu2cc <= 1'b0;
    
    repeat(42)@(negedge clk);
    
    rst         <= 1'b0;
    repeat(512)@(negedge clk);  
    
    //one: read miss 0way
    @(posedge clk);
    adr_cpu2cc  <= 32'b11111111000001111011110100001000;
    rdwr_cpu2cc <= 1'b0;
    req_cpu2cc  <= 1'b1;
    lb_cpu2cc   <= 1'b1;
    repeat(2) @(posedge clk);
    repeat(4)
    begin
        ack_mem2cc  <= 1'b1;
        dat_mem2cc  <= {32{1'b1}};
        @(posedge clk); 
    end
    ack_mem2cc <= 1'b0;
    req_cpu2cc <= 1'b0;
    lb_cpu2cc  <= 1'b0;
    
    repeat(2)@(posedge clk);
    
    //two: read miss 1way
    @(posedge clk);
    adr_cpu2cc  <= 32'b10100101010101010010110100001000;
    rdwr_cpu2cc <= 1'b0;
    req_cpu2cc  <= 1'b1;
    repeat(2) @(posedge clk);
    repeat(4)
    begin
        ack_mem2cc  <= 1'b1;
        dat_mem2cc  <= {32{1'b1}};
        @(posedge clk); 
    end
    ack_mem2cc <= 1'b0;
    req_cpu2cc <= 1'b0;
    
    repeat(2)@(posedge clk);
        
    //three: read miss 2way
    @(posedge clk);
    adr_cpu2cc  <= 32'b11010101000000001010110100001000;
    rdwr_cpu2cc <= 1'b0;
    req_cpu2cc  <= 1'b1;
    repeat(2) @(posedge clk);
    repeat(4)
    begin
        ack_mem2cc  <= 1'b1;
        dat_mem2cc  <= {32{1'b1}};
        @(posedge clk);     
    end
    ack_mem2cc <= 1'b0;
    req_cpu2cc <= 1'b0;
    
    repeat(2)@(posedge clk);
        
    //four: read miss 3way
    @(posedge clk);
    adr_cpu2cc  <= 32'b11111111111111111111110100001000;
    rdwr_cpu2cc <= 1'b0;
    req_cpu2cc  <= 1'b1;
    repeat(2) @(posedge clk);
    repeat(4)
    begin
        ack_mem2cc  <= 1'b1;
        dat_mem2cc  <= {32{1'b1}};
        @(posedge clk);     
    end
    ack_mem2cc <= 1'b0;
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
    
    repeat(2)@(posedge clk);
    
    //seven: read hit 2way
    @(posedge clk);
    adr_cpu2cc  <= 32'b11010101000000001010110100001000;
    rdwr_cpu2cc <= 1'b0;
    req_cpu2cc  <= 1'b1;
    repeat(3) @(posedge clk);
    req_cpu2cc <= 1'b0;
    
    repeat(2)@(posedge clk);
    
    //eight: write miss 1way deload
    adr_cpu2cc  <= 32'b01011111010101111110110100001000;
    rdwr_cpu2cc <= 1'b1;
    req_cpu2cc  <= 1'b1;
    dat_cpu2cc  <= 32'b10101010101010101010101010101010;
    repeat(2) @(posedge clk);
    repeat(4)
    begin
        ack_mem2cc  <= 1'b1;
        dat_mem2cc  <= {32{1'b1}};
        @(posedge clk);     
    end
    ack_mem2cc <= 1'b0;
    req_cpu2cc <= 1'b0;
    
    repeat(2)@(posedge clk);
        
    //nine: write hit 0way
    @(posedge clk);
    adr_cpu2cc  <= 32'b11111111000001111011110100001000;
    rdwr_cpu2cc <= 1'b1;
    dat_cpu2cc  <= 32'b11011101110111011101110111011101;
    req_cpu2cc  <= 1'b1;
    repeat(3) @(posedge clk);
    req_cpu2cc <= 1'b0;
    
    repeat(2)@(posedge clk);
          
    //ten: read miss deload 3way
    @(posedge clk);
    adr_cpu2cc  <= 32'b0111010100000101010110100001000;
    rdwr_cpu2cc <= 1'b0;
    req_cpu2cc  <= 1'b1;
    repeat(2) @(posedge clk);
    repeat(4)
    begin
        ack_mem2cc  <= 1'b1;
        dat_mem2cc  <= {32{1'b1}};
        @(posedge clk);    
    end
    ack_mem2cc <= 1'b0;
    req_cpu2cc <= 1'b0;
    
    repeat(2)@(posedge clk);
   
    //byte_request signed 
    @(posedge clk);
    lb_cpu2cc   <= 1'b1;
    adr_cpu2cc  <= 32'b11111111000001111011110100001001;
    rdwr_cpu2cc <= 1'b0;
    req_cpu2cc  <= 1'b1;
    repeat(3) @(posedge clk);
    req_cpu2cc <= 1'b0;
    lb_cpu2cc  <= 1'b0;
    
    repeat(2)@(posedge clk);
    
    //byte_request unsigned
    @(posedge clk);
    lbu_cpu2cc   <= 1'b1;
    adr_cpu2cc  <= 32'b11111111000001111011110100001001;
    rdwr_cpu2cc <= 1'b0;
    req_cpu2cc  <= 1'b1;
    repeat(3) @(posedge clk);
    req_cpu2cc <= 1'b0;
    lbu_cpu2cc <= 1'b0;
   
    #50
    
    $finish;
end

 cacheController cacheController0(
                        .clk(clk), 
                        .rst(rst), 
                        .lb_cpu2cc(lb_cpu2cc),
                        .lbu_cpu2cc(lbu_cpu2cc),
                        .req_cpu2cc(req_cpu2cc), 
                        .adr_cpu2cc(adr_cpu2cc), 
                        .dat_cpu2cc(dat_cpu2cc),
                        .rdwr_cpu2cc(rdwr_cpu2cc),
                        .ack_cc2cpu(ack_cc2cpu), 
                        .dat_cc2cpu(dat_cc2cpu), 
                        .req_cc2mem(req_cc2mem), 
                        .adr_cc2mem(adr_cc2mem), 
                        .ack_mem2cc(ack_mem2cc),
                        .dat_mem2cc(dat_mem2cc)
                       );

endmodule

