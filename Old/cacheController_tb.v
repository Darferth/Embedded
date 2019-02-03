`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.12.2018 21:41:59
// Design Name: 
// Module Name: cacheController_tb
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


module cacheController_tb();
    
    reg clk;
    reg rst;
    wire [1:0] state_test;
    wire [1:0] state_next_test;
    reg req_cpu_i;
    reg adr_cpu_i;
    reg dat_cpu_i;
    reg we_cpu_i;
    reg dat_mem_i;
    reg ack_mem_i;
    reg cc_hit_i;
    reg cc_dat_i;
    reg cc_valid_i;
    reg adr_mshr_load_i;
    reg dat_mshr_load_i;
    reg adr_mshr_deload_i;
    reg dat_mshr_deload_i;
    reg lru;
    reg free;
    
    wire dat_cpu_o;
    wire ack_cpu_o;
    wire err_cpu_o;
    wire cyc_m2s;
    wire we_m2s;
    wire adr_m2s;
    wire dat_m2s;
    wire cc_we_o;
    wire cc_adr_o;
    wire cc_dat_o;
    wire adr_mshr_load_o;
    wire dat_mshr_load_o;
    wire adr_mshr_deload_o;
    wire dat_mshr_deload_o;
    
    
    always #10 clk=~clk;
    
    initial
    begin
        clk<=0;
        rst=1;
        free=1'b1;
        repeat(5) @(posedge clk);
        rst<=0;
        repeat(5) @(posedge clk);
        */
        // WRITE MISS
        /*
        #1
        req_cpu_i = 1'b1;
        adr_cpu_i = 1'b1;
        dat_cpu_i = 1'b0;
        we_cpu_i = 1'b1;
        #2
        cc_hit_i = 1'b0;
        cc_valid_i = 1'b0;
        @(posedge clk);
        req_cpu_i = 1'b0;
        #2
        dat_mem_i = 1'b0;
        ack_mem_i = 1'b1;
        */
        
        // READ MISS
        /*
        #1
        req_cpu_i = 1'b1;
        adr_cpu_i = 1'b1;
        we_cpu_i = 1'b0;
        #2
        cc_hit_i = 1'b0;
        cc_valid_i = 1'b0;
        @(posedge clk);
        req_cpu_i = 1'b0;
        #2
        dat_mem_i = 1'b0;
        ack_mem_i = 1'b1;
        */
        
        // READ HIT
        /*
        #1
        req_cpu_i = 1'b1;
        adr_cpu_i = 1'b0;
        we_cpu_i = 1'b0;
        #2
        cc_hit_i = 1'b1;
        cc_valid_i = 1'b1;
        cc_dat_i = 1'b1;
        @(posedge clk);
        req_cpu_i = 1'b0;
        */
        
        //WRITE HIT
        /*
        #1
        req_cpu_i = 1'b1;
        adr_cpu_i = 1'b0;
        dat_cpu_i = 1'b1;
        we_cpu_i = 1'b1;
        #2
        cc_hit_i = 1'b1;
        cc_valid_i = 1'b1;
        @(posedge clk);
        req_cpu_i = 1'b0;
        */
        
        //READ MISS REPLACE
        
        /*
        #1
        req_cpu_i = 1'b1;
        adr_cpu_i = 1'b0;
        we_cpu_i = 1'b0;
        #2
        cc_hit_i = 1'b0;
        cc_valid_i = 1'b0;
        free=1'b0;
        lru_adr=1'b1;
        #2
        adr_mshr_deload_i=1'b1;
        dat_mshr_deload_i=1'b1;
        dat_mem_i=1'b1;
        adr_mshr_load_i=1'b1;
        dat_mshr_load_i=1'b1;
        repeat(20) @(posedge clk);
        req_cpu_i = 1'b0;
        
        */
        
        //WRITE MISS REPLACE
        
        /*
        
        #1
        req_cpu_i = 1'b1;
        adr_cpu_i = 1'b0;
        we_cpu_i = 1'b1;
        dat_cpu_i = 1'b0;
        #2
        cc_hit_i = 1'b0;
        cc_valid_i = 1'b0;
        free=1'b0;
        lru_adr=1'b1;
        #2
        adr_mshr_deload_i=1'b1;
        dat_mshr_deload_i=1'b1;
        dat_mem_i=1'b1;
        adr_mshr_load_i=1'b1;
        dat_mshr_load_i=1'b1;
        repeat(20) @(posedge clk);
        req_cpu_i = 1'b0;
        
        
        $finish;
        
    end
    
    cacheController cacheController (.clk(clk),
                                    .rst(rst),
                                    .state_test(state_test),
                                    .state_next_test(state_next_test),
                                    .req_cpu_i(req_cpu_i),
                                    .adr_cpu_i(adr_cpu_i),
                                    .dat_cpu_i(dat_cpu_i),
                                    .we_cpu_i(we_cpu_i),
                                    .dat_mem_i(dat_mem_i),
                                    .ack_mem_i(ack_mem_i),
                                    .cc_hit_i(cc_hit_i),
                                    .cc_dat_i(cc_dat_i),
                                    .cc_valid_i(cc_valid_i),
                                    .adr_mshr_load_i(adr_mshr_load_i),
                                    .dat_mshr_load_i(dat_mshr_load_i),
                                    .adr_mshr_deload_i(adr_mshr_deload_i),
                                    .dat_mshr_deload_i(dat_mshr_deload_i),
                                    .lru(lru),
                                    .free(free),
                                    .dat_cpu_o(dat_cpu_o),
                                    .ack_cpu_o(ack_cpu_o),
                                    .err_cpu_o(err_cpu_o),
                                    .cyc_m2s(cyc_m2s),
                                    .we_m2s(we_m2s),
                                    .adr_m2s(adr_m2s),
                                    .dat_m2s(dat_m2s),
                                    .cc_we_o(cc_we_o),
                                    .cc_adr_o(cc_adr_o),
                                    .cc_dat_o(cc_dat_o),
                                    .adr_mshr_load_o(adr_mshr_load_o),
                                    .dat_mshr_load_o(dat_mshr_load_o),
                                    .adr_mshr_deload_o(adr_mshr_deload_o),
                                    .dat_mshr_deload_o(dat_mshr_deload_o));  
endmodule
