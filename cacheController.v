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

    // CPU
    //---------------------//
    // Input
    input req_cpu_i,
    input adr_cpu_i,
    input dat_cpu_i,
    input we_cpu_i,
    
    // Output
    output reg dat_cpu_o,
    output reg ack_cpu_o,
    output reg err_cpu_o,
    
    // MEM
    //---------------------//
    // Input
    input dat_mem_i,
    input ack_mem_i,
    
    // Output
    output reg cyc_m2s,
    output reg we_m2s,
    output reg adr_m2s,
    output reg dat_m2s,
    
    // CACHE
    //---------------------//
    // Input
    input cc_hit_i,
    input cc_dat_i,
    input cc_valid_i,
    
    // Output
    output reg cc_we_o,
    output reg cc_adr_o,
    output reg cc_dat_o,
    
    // MSHR
    //---------------------//
    // Input
    input adr_mshr_load_i,
    input dat_mshr_load_i,
    input adr_mshr_deload_i,
    input dat_mshr_deload_i,
    
    // Output
    output reg adr_mshr_load_o,
    output reg dat_mshr_load_o,
    output reg adr_mshr_deload_o,
    output reg dat_mshr_deload_o,
    
    // GP signals
    input clk,
    input rst,
    
    // Inner signals CACHE (TEST)
    input lru,
    input free
    
    );
    
    reg[1:0] ss, ss_next;
    reg lru_adr;
      
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
        end
    end
    
    always@(*)
    begin
        //latch
        ss_next = ss;
        
        case(ss)
            IDLE:
            begin
            
                if(req_cpu_i)
                begin
                
                    // CACHE LOCKUP
                    //---------------------//
                    cc_adr_o = adr_cpu_i;
                    cc_dat_o = we_cpu_i ? dat_cpu_i : 1'bx;
                    cc_we_o = we_cpu_i;
                                        
                    if(cc_hit_i && cc_valid_i) // READ HIT and WRITE HIT
                    begin
                        ack_cpu_o = 1'b1;
                        dat_cpu_o = we_cpu_i ? 1'bx : dat_cpu_i;
                    end
                    
                    if(~cc_hit_i || ~cc_valid_i) //READ MISS and WRITE MISS
                    begin
                    
                        if(free) // AVAILABLE SPACE IN CACHE
                        begin
                        
                            // READ/WRITE IN MEMORY
                            //---------------------//
                            cyc_m2s = 1'b1;
                            we_m2s = we_cpu_i;
                            adr_m2s = adr_cpu_i;
                            if(we_cpu_i) // WRITE
                            begin
                                dat_m2s = dat_cpu_i;
                                ss_next = WRITE_MEM;
                             end
                             else //READ
                             begin
                                dat_m2s = 1'bx;
                                ss_next = READ_MEM;
                             end
                             
                        end
                        else // NO SPACE AVAILABLE IN CACHE
                        begin
                              
                            // CACHE LOOKUP (LRU)
                            //---------------------//
                            cc_adr_o = lru_adr;
                            cc_dat_o = 1'bx;
                            cc_we_o = 1'b0;
                        
                            // SAVE LRU IN MSHR
                            //---------------------//
                            adr_mshr_deload_o = cc_adr_o;
                            dat_mshr_deload_o = cc_dat_i;
                            
                            // REQUEST TO MEMORY
                            //---------------------//   
                            cyc_m2s = 1'b1;
                            adr_m2s = adr_cpu_i;
                            we_m2s = we_cpu_i;
                            dat_m2s = we_cpu_i ? dat_cpu_i : 1'bx;
                            ss_next = REPLACE;  
                            
                        end
                    end
                end
            end
            READ_MEM:
            begin
                if(ack_mem_i)
                begin
                    // ALLOCATE IN CACHE
                    //---------------------//
                    cc_adr_o = adr_cpu_i;
                    cc_dat_o = dat_mem_i;
                    cc_we_o = 1'b1; 
                    
                    // GEN. OUTPUT TO CPU
                    //---------------------//
                    dat_cpu_o = dat_mem_i;
                    ack_cpu_o = 1'b1;
                end
            end
            WRITE_MEM:
            begin
                if(ack_mem_i)
                begin
                    // ALLOCATE IN CACHE
                    //---------------------//
                    cc_adr_o = adr_cpu_i;
                    cc_dat_o = dat_mem_i;
                    cc_we_o = 1'b1;
                    
                    // GEN. OUTPUT TO CPU
                    //---------------------// 
                    ack_cpu_o = 1'b1;
                end
            end
            REPLACE:
            begin
                if(ack_mem_i)
                begin
                
                    // STORE LRU IN MEMORY
                    //---------------------//
                    cyc_m2s = 1'b1;
                    adr_m2s = adr_mshr_deload_i;
                    dat_m2s = dat_mshr_deload_i;
                    we_m2s = 1'b1;
                    
                    // LOAD IN MSHR LOAD LINE
                    //---------------------//
                    adr_mshr_load_o = adr_cpu_i;
                    dat_mshr_load_o = dat_mem_i;
                    
                    // WRITE IN CACHE LOAD LINE
                    //---------------------//
                    cc_adr_o = adr_mshr_load_i;
                    cc_dat_o = dat_mshr_load_i;
                    cc_we_o = 1'b1;
                    
                    // GEN. OUTPUT TO CPU
                    //---------------------//
                    dat_cpu_o = we_cpu_i ? dat_mem_i : 1'bx;
                    ack_cpu_o = 1'b1;
                end
            end
        endcase
    end
    
    MSHR mshr_0 (.clk(clk), 
                .rst(rst), 
                .cache_adr_i(adr_mshr_deload_o), 
                .cache_dat_i(dat_mshr_deload_o),
                .mem_adr_i(adr_mshr_load_o),
                .mem_dat_i(dat_mshr_load_o),
                .cache_adr_i(adr_mshr_deload_i), 
                .cache_dat_i(dat_mshr_deload_i),
                .mem_adr_i(adr_mshr_load_i),
                .mem_dat_i(dat_mshr_load_i)
                );
    
endmodule
