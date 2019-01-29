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

module cacheController
#(  
    parameter ADR_LENGTH = 32,
    parameter DATA_LENGTH = 32
)
(

    // CPU
    //---------------------//
    // Input
    input req_cpu_i,
    input [ADR_LENGTH-1:0] adr_cpu_i,
    input [DATA_LENGTH-1:0] dat_cpu_i,
    input we_cpu_i,
    
    // Output
    output reg [DATA_LENGTH-1:0] dat_cpu_o,
    output reg ack_cpu_o,
    output reg err_cpu_o,
    
    // MEM
    //---------------------//
    // Input
    input [DATA_LENGTH-1:0] dat_mem_i,
    input ack_mem_i,
    
    // Output
    output reg cyc_m2s,
    output reg we_m2s,
    output reg [ADR_LENGTH-1:0] adr_m2s,
    output reg [DATA_LENGTH-1:0] dat_m2s,
    
    // CACHE
    //---------------------//
    // Input
    input cc_hit_i,
    input [DATA_LENGTH-1:0] cc_dat_i,
    input cc_free_i,
    
    // Output
    output reg cc_we_o,
    output reg [ADR_LENGTH-1:0] cc_adr_o,
    output reg [DATA_LENGTH-1:0] cc_dat_o,
    output reg cc_deload_o,
    output reg cc_req_o,
    
    // MSHR
    //---------------------//
    // Input
    input [ADR_LENGTH-1:0] adr_mshr_load_i,
    input [DATA_LENGTH-1:0] dat_mshr_load_i,
    input [ADR_LENGTH-1:0] adr_mshr_deload_i,
    input [DATA_LENGTH-1:0] dat_mshr_deload_i,
    
    // Output
    output reg [ADR_LENGTH-1:0] adr_mshr_load_o,
    output reg [DATA_LENGTH-1:0] dat_mshr_load_o,
    output reg [ADR_LENGTH-1:0] adr_mshr_deload_o,
    output reg [DATA_LENGTH-1:0] dat_mshr_deload_o,
    
    // GP signals
    input clk,
    input rst
    
    );
    
    reg[1:0] ss, ss_next;
      
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
    
        ss_next = ss;
        
        // Reset controls to CPU
        //---------------------//
        ack_cpu_o = 1'b0;
        dat_cpu_o = {DATA_LENGTH{1'bx}};
        err_cpu_o = 1'bx;
        
        // Reset controls to MEM
        //---------------------//
        cyc_m2s = 1'b0;
        adr_m2s = {ADR_LENGTH{1'bx}};
        dat_m2s = {DATA_LENGTH{1'bx}};
        we_m2s = 1'bx;
        
        // Reset controls to CACHE
        //---------------------//
        cc_adr_o = {ADR_LENGTH{1'bx}};
        cc_dat_o = {DATA_LENGTH{1'bx}};
        cc_we_o = 1'bx;
        cc_deload_o =1'bx;
        cc_req_o = 1'bx;
        
        // Reset controls to MSHR
        //---------------------//
        /*
        adr_mshr_load_o = 1'b0;
        dat_mshr_load_o = 1'b0;
        adr_mshr_deload_o = 1'b0;
        dat_mshr_deload_o = 1'b0;
        */
        
        case(ss)
            IDLE:
            begin
            
                if(req_cpu_i)
                begin
                
                    // CACHE LOCKUP
                    //---------------------//
                    cc_req_o = 1'b1;
                    cc_adr_o = adr_cpu_i;
                    cc_dat_o = we_cpu_i ? dat_cpu_i : 32'bx;
                    cc_we_o = we_cpu_i;
                    
                    // da valutare l'aggiunta di un ack proveniente dalla cache 
                    // per indicare la fine del lookup
                    // if(end_cache_lookup) ...
                    
                                        
                    if(cc_hit_i == 1'b1) // READ HIT and WRITE HIT
                    begin
                        ack_cpu_o = 1'b1;
                        dat_cpu_o = we_cpu_i ? 1'bx : cc_dat_i; // potremmo restituire anche se è una write
                        
                        // reset cache lookup req
                        /*cc_adr_o = 1'bx;
                        cc_dat_o = 1'bx;
                        cc_we_o = 1'bx;*/
                    end
                    else if(cc_hit_i == 1'b0) //READ MISS and WRITE MISS
                    begin
                    
                        if(cc_free_i) // AVAILABLE SPACE IN CACHE
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
                            cc_req_o = 1'b0;
                            cc_deload_o = 1'b1;
                            cc_adr_o = adr_cpu_i; //adr_cpu_i
                            cc_dat_o = 1'bx;
                            cc_we_o = 1'b0;
                            cc_req_o = 1'b1;
                        
                            // SAVE LRU IN MSHR
                            //---------------------//
                            //if(end_cache_lookup)
                            //...
                            adr_mshr_deload_o = adr_cpu_i;
                            dat_mshr_deload_o = cc_dat_i;
                            
                            // REQUEST TO MEMORY
                            //---------------------//   
                            adr_m2s = adr_cpu_i;
                            we_m2s = we_cpu_i;
                            dat_m2s = we_cpu_i ? dat_cpu_i : 1'bx;
                            cyc_m2s = 1'b1;
                            
                            ss_next = REPLACE;  
                            
                        end
                    end
                end
                
                //reset output signals ?
                
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
                    cc_req_o = 1'b1;
                    
                    // GEN. OUTPUT TO CPU
                    //---------------------//
                    dat_cpu_o = dat_mem_i;
                    ack_cpu_o = 1'b1;
                    
                    ss_next = IDLE;
                    
                    //reset memory lookup req
                    /*
                    cyc_m2s = 1'bx;
                    we_m2s = 1'bx;
                    adr_m2s = 1'bx;
                    */
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
                    cc_req_o = 1'b1;
                    
                    // GEN. OUTPUT TO CPU
                    //---------------------// 
                    ack_cpu_o = 1'b1;
                    
                    ss_next = IDLE;
                    
                    //reset memory lookup req
                    /*
                    cyc_m2s = 1'bx;
                    we_m2s = 1'bx;
                    adr_m2s = 1'bx;
                    dat_m2s = 1'bx;
                    */
                end
            end
            REPLACE:
            begin
                if(ack_mem_i)
                begin
                
                    // STORE LRU IN MEMORY
                    //---------------------//
                    adr_m2s = adr_mshr_deload_i;
                    dat_m2s = dat_mshr_deload_i;
                    we_m2s = 1'b1;
                    cyc_m2s = 1'b1;
                    
                    // LOAD IN MSHR LOAD LINE
                    //---------------------//
                    adr_mshr_load_o = adr_cpu_i;
                    dat_mshr_load_o = dat_mem_i;
                    
                    // WRITE IN CACHE LOAD LINE
                    //---------------------//
                    cc_adr_o = adr_mshr_load_i;
                    cc_dat_o = dat_mshr_load_i;
                    cc_we_o = 1'b1;
                    cc_req_o = 1'b1;
                    
                    // GEN. OUTPUT TO CPU
                    //---------------------//
                    dat_cpu_o = we_cpu_i ? 1'bx : dat_mem_i;
                    ack_cpu_o = 1'b1;
                    
                    ss_next = IDLE;
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
                .cache_adr_o(adr_mshr_deload_i), 
                .cache_dat_o(dat_mshr_deload_i),
                .mem_adr_o(adr_mshr_load_i),
                .mem_dat_o(dat_mshr_load_i)
                );
     
     /*dcache data_cache (.rst(rst), 
                        .cc_req_i(cc_req_o), 
                        .cc_we_i(cc_we_o),
                        .cc_dat_i(cc_dat_o),
                        .cc_adr_i(cc_adr_o),
                        .cc_deload_i(cc_deload_o),
                        .cache_dat_o(cc_dat_i),
                        .cache_hit_o(cc_hit_i),
                        .cache_free_o(cc_free_i)
                        );
    */
endmodule
