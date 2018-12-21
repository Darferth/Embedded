`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.12.2018 09:58:09
// Design Name: 
// Module Name: cacheController
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


module cacheController(

    // Input signals from CPU
    input req_cpu_i,
    input adr_cpu_i,
    input dat_cpu_i,
    input we_cpu_i,
    
    // Output signals to CPU
    output reg dat_cpu_o,
    output reg ack_cpu_o,
    output err_cpu_o,
    
    // Input signals from MEM
    input dat_mem_i,
    input ack_mem_i,
    
    // Output signals to MEM
    output reg cyc_m2s,
    output reg we_m2s,
    output reg adr_m2s,
    output reg dat_m2s,
    
    // GP signals
    input clk,
    input rst,
    
    // Inner signals CACHE
    input hit,
    input valid,
    input lru
    );
    
    // Inner signals
    reg[1:0] ss, ss_next;
    reg ack_cpu_o_next;
    reg free;
    reg deload_line;
    reg load_line;
   
    
    localparam [1:0] IDLE = 2'b00, READ_MEM = 2'b01, WRITE_MEM = 2'b10, REPLACE = 2'b11; 
    
    always@(posedge clk)
    begin
        if(rst == 1'b1)
        begin
            ss <= IDLE;
        end
        else
        begin
            ss <= ss_next;
            //ack_cpu_o <= ack_cpu_o_next;
        end
    end
    
    always@(*)
    begin
        //latch
        
        case(ss)
            IDLE:
            begin
                if(req_cpu_i && ~we_cpu_i && hit)
                begin
                    //dat_cpu_o = cache;
                    //ack_cpu_o_next = 1;
                    ack_cpu_o = 1'b1;
                end
                else if(req_cpu_i && we_cpu_i && hit)
                begin
                    //ack_cpu_o_next = 1;
                    ack_cpu_o = 1'b1;
                end
                else if(req_cpu_i && ~we_cpu_i && (~hit || ~valid) && free) 
                begin
                    cyc_m2s = 1'b1;
                    we_m2s = 0;
                    adr_m2s = adr_cpu_i;
                    ss_next = READ_MEM;
                end
                else if(req_cpu_i && we_cpu_i && (~hit || ~valid) && free) 
                begin
                    cyc_m2s = 1'b1;
                    we_m2s = 1'b1;
                    adr_m2s = adr_cpu_i;
                    dat_m2s = dat_cpu_i;
                    ss_next = WRITE_MEM;
                end
                else if(req_cpu_i && (~hit || ~valid) && ~free)
                begin
                    //deload_line = cache[LRU];
                    cyc_m2s = 1'b1;
                    adr_m2s = adr_cpu_i;
                    dat_m2s = dat_cpu_i;
                    we_m2s = we_cpu_i;
                    ss_next = REPLACE;    
                end
            end
            READ_MEM:
            begin
                if(ack_mem_i)
                begin
                    //write in cache
                    dat_cpu_o = dat_mem_i;
                    ack_cpu_o = 1'b1;
                end
            end
            WRITE_MEM:
            begin
                if(ack_mem_i)
                begin
                    //write in cache
                    ack_cpu_o = 1'b1;
                end
            end
            REPLACE:
            begin
                if(ack_mem_i)
                begin
                    load_line = dat_mem_i;
                    
                    //write the deload line in mem
                    cyc_m2s = 1'b1;
                    //adr_m2s = deload_line_adr;
                    //dat_m2s = deload_line_dat;
                    we_m2s = 1'b1;
                    
                    //write in cache load line
                    
                    //return load line to CPU if request, otherwise return only the ack
                    if(~we_cpu_i)
                        dat_cpu_o = load_line;
                     ack_cpu_o = 1'b1;
                end
            end
        endcase
    end
    
    MSHR mshr_0 (.clk(clk), .rst(rst), .cache_line_i(deload_line), .mem_line_i(dat_mem_i), .cache_line_o(load_line), .mem_line_o(deload_line));
    
endmodule
