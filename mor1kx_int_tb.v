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
reg                         lb_cpu2cc;
reg                         lbu_cpu2cc;
wire                        ack_cc2cpu;
wire    [DATA_WIDTH-1:0]    dat_cc2cpu;

        //MEM SIGNALS
reg                         ack_mem2cc;
reg     [DATA_WIDTH-1:0]    dat_mem2cc;
wire                        req_cc2mem;
wire    [ADR_WIDTH-1:0]     adr_cc2mem;

integer                     wait_time, start_time, end_time;



always #5 clk=~clk;

task refill;
    input ack;
    input [31:0] dat;
    begin
        @(posedge clk);
        ack_mem2cc  <= ack;
        dat_mem2cc  <= dat;
    end
endtask 
task read_request;
    input [ADR_WIDTH-1:0]  adr;
    input                  lb;
    input                  lbu;

    begin
        @(posedge clk);
        adr_cpu2cc  <=     adr;
        lb_cpu2cc   <=     lb;
        lbu_cpu2cc  <=     lbu;
        rdwr_cpu2cc <=     1'b0;
        req_cpu2cc  <=     1'b1;
        ack_mem2cc  <=     1'b0;

        wait_time    =     0;
        start_time  =     $time;
        @(posedge clk);
        $display("================================================ \n start time %d, READ request on adr %h \n=====", start_time, adr_cpu2cc);
        $display ("Waiting for signal ack or req");
        while (!(req_cc2mem || ack_cc2cpu))
        begin
        @(posedge clk);
        end
        
        if(req_cc2mem)
        begin
            $display("=====\nSent req_cc2mem signal");
            wait_time=$urandom_range(1,10);
            repeat(wait_time)@(posedge clk);
            $display("Waited %d cycle for ack_mem2cc",wait_time);
            repeat(4)
            begin
                refill(1'b1, {32{1'b1}});
            end
            $display("Memory transfer complete \n=====");
        end
        else if(ack_cc2cpu)
        begin
            req_cpu2cc <= 1'b0;
            $display("=====\n Sent ack_cc2cpu, READ request HIT, dat is %h \n=====", dat_cc2cpu);
        end 
    end_time    = $time - start_time;
    $display("Took %d cycles for READ operation", end_time/10);
    @(posedge clk);
    ack_mem2cc  <= 1'b0;
    req_cpu2cc <= 1'b0;
    lbu_cpu2cc <= 1'b0;
    lb_cpu2cc <= 1'b0;
 
    end
endtask

task write_request;
    input [ADR_WIDTH-1:0]  adr;
    input [DATA_WIDTH-1:0] dat;

    begin
        
        adr_cpu2cc  <=     adr;
        dat_cpu2cc  <=     dat;
        rdwr_cpu2cc <=     1'b1;
        req_cpu2cc  <=     1'b1;
        ack_mem2cc  <=     1'b0;
        wait_time    =     0;
        start_time   =     $time;
        @(posedge clk);
        $display("================================================ \n start time %d, WRITE request on adr %h, dat %h \n=====", start_time, adr_cpu2cc, dat_cpu2cc);
    
    $display ("Waiting for signal ack or req");
    while (!(req_cc2mem || ack_cc2cpu))
        begin
        @(posedge clk);
        
        end
    if(req_cc2mem)
        begin
            $display("=====\n Sent req_cc2mem signal");
            wait_time=$urandom_range(1,10);
            repeat(wait_time)@(posedge clk);
            $display("waited %d cycle for ack_mem2cc",wait_time);
            repeat(4)
            begin
                refill(1'b1, {32{1'b1}});
            end
            $display("Memory transfer complete \n=====");
        end
    else if(ack_cc2cpu)
           $display("=====\n Sent ack_cc2cpu, WRITE request HIT  \n=====");
           req_cpu2cc <= 1'b0; 
    
    end_time    <= $time - (start_time + wait_time);
    $display("Took %d cycles for WRITE operation", end_time/10);
    @(posedge clk);
    ack_mem2cc  <= 1'b0;
    req_cpu2cc <= 1'b0;
    end
endtask

            
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
    lbu_cpu2cc <= 1'b0;
    lb_cpu2cc  <= 1'b0;
    repeat(42)@(negedge clk);
    
    rst         <= 1'b0;
    repeat(512)@(negedge clk);
    
    lbu_cpu2cc <= 1'b0;
    lb_cpu2cc  <= 1'b0;
    //first req: read miss w.o. 2
    @(posedge clk);
    read_request(32'b11111111000001111011110100001000, 1'b0, 1'b0);
    
    repeat(2)@(posedge clk);
    
    
    //second req: read miss w.o. 3
    @(posedge clk);
    read_request(32'b10100101010101010010110100001100, 1'b0, 1'b0);
    
    repeat(2)@(posedge clk);
        
    //third req: read miss w.o. 0
    @(posedge clk);
    read_request(32'b11010101000000001010110100000000, 1'b0, 1'b0);
   
    repeat(2)@(posedge clk);
        
    //fourth req: read miss w.o 2
    @(posedge clk);
    read_request(32'b11111111111111111111110100001000, 1'b0, 1'b0);
    repeat(2)@(posedge clk);
        
    //five: read hit 0way
    @(posedge clk);
    read_request(32'b11111111000001111011110100000000, 1'b0, 1'b0);
    repeat(2)@(posedge clk);
    
    //six: write hit 3way
    @(posedge clk);
    write_request(32'b11111111111111111111110100001000,
                  32'b1010101010001010101010101010010);
   
    
    repeat(2)@(posedge clk);
    //seven: write hit way
    @(posedge clk);
    write_request(32'b10100101010101010010110100001000,
                  32'b10101010100010101010101010100100);
    
    repeat(2)@(posedge clk);
    //eight: read miss 2way
    @(posedge clk);
    read_request(32'b10101111110101010010110100001000, 1'b0, 1'b0);
    
    repeat(2)@(posedge clk);
    //nine: read hit, reads the value written in test 7
    @(posedge clk);
    read_request(32'b10100101010101010010110100001000, 1'b0, 1'b0);
    
    repeat(2)@(posedge clk);
    //ten: write hit w.o. 0
    @(posedge clk);
    write_request(32'b10100101010101010010110100000000,
                  32'b10101010100010101111111111100100);

    
    repeat(2)@(posedge clk);
    //eleven: write hit w.o. 1
    @(posedge clk);
    write_request(32'b10100101010101010010110100000100,
                  32'b11111111111110101010101010100100);
    
    repeat(2)@(posedge clk);
    //twelve: write hit w.o. 3
    @(posedge clk);
    write_request(32'b10100101010101010010110100001100,
                  32'b10101010111010111010101010110100);
    
    
    repeat(2)@(posedge clk);
    //thirteen: read hit w.o. 3 byte read lbu
     read_request(32'b10100101010101010010110100001100, 1'b0, 1'b1);
   
    
    repeat(2)@(posedge clk);
    //fourteen: read hit w.o. 3 byte read lb
    read_request(32'b10100101010101010010110100001100, 1'b1, 1'b0);
    
    repeat(2)@(posedge clk);
    //fifteen: read hit w.o. 3 byte read lbu offset 1
    read_request(32'b10100101010101010010110100001101, 1'b0, 1'b1);
                 
    repeat(2)@(posedge clk);
    //sixteen: read hit w.o. 3 byte read lb offset 1
    read_request(32'b10100101010101010010110100001101, 1'b1, 1'b0);
   
    #50
    
    $finish;
end

 cacheController cacheController0(
                        .clk(clk), 
                        .rst(rst), 
                        .req_cpu2cc(req_cpu2cc), 
                        .adr_cpu2cc(adr_cpu2cc), 
                        .dat_cpu2cc(dat_cpu2cc),
                        .rdwr_cpu2cc(rdwr_cpu2cc),
                        .lb_cpu2cc(lb_cpu2cc),
                        .lbu_cpu2cc(lbu_cpu2cc),
                        .ack_cc2cpu(ack_cc2cpu), 
                        .dat_cc2cpu(dat_cc2cpu), 
                        .req_cc2mem(req_cc2mem), 
                        .adr_cc2mem(adr_cc2mem), 
                        .ack_mem2cc(ack_mem2cc),
                        .dat_mem2cc(dat_mem2cc)
                       );

endmodule
