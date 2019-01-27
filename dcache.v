`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.01.2019 21:23:40
// Design Name: 
// Module Name: dcache
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


module dcache
#(
    parameter WAY_NUMBER = 2, //Per ora inutile
    parameter ADR_LENGTH = 32,
    parameter INDEX_LENGTH = 7,
    parameter TAG_LENGTH = 22, //da sistemare
    parameter DATA_LENGTH = 32,
    parameter CACHE_LINES = 128,
    parameter TAG_RESET_VALUE = 22'bx,
    parameter DATA_RESET_VALUE = 32'bx,
    parameter VALID_RESET_VALUE = 1'bx
)
(  
    input cc_req_i,
    input cc_we_i,
    input cc_dat_i,
    input [ADR_LENGTH-1:0] cc_adr_i,
    input cc_deload_i,
    input rst,
    
    output wire cache_dat_o,
    output wire cache_hit_o,
    output wire cache_free_o
);

localparam INDEX_BEGIN = ADR_LENGTH-1;
localparam INDEX_END = INDEX_BEGIN - INDEX_LENGTH;
localparam TAG_BEGIN = INDEX_END-1;
localparam TAG_END = TAG_BEGIN-TAG_LENGTH;

reg [INDEX_LENGTH-1:0] index;
reg [TAG_LENGTH-1:0] tag;
reg LRU[CACHE_LINES-1:0]; 
reg tag_way0_i, tag_way1_i, tag_way0_o, tag_way1_o;
reg dat_way0_i, dat_way1_i, dat_way0_o, dat_way1_o;
reg valid_way0_i, valid_way1_i, valid_way0_o, valid_way1_o;
reg index_way0_i, index_way1_i;
reg data_we;
reg compRes_way0, compRes_way1;
reg valid_way0, valid_way1;
wire hit_way0, hit_way1, hit_global;
reg free_way0, free_way1;
reg data_read;

// da sistemare:
// reset index per le way
// gestione LRU per la prima allocazione write miss
// integrazione con cc

always@(posedge cc_req_i)
begin
    index = cc_adr_i[INDEX_BEGIN:INDEX_END];
    tag = cc_adr_i[TAG_BEGIN:TAG_END];
    
    if(~cc_we_i)
    begin
        if(~cc_deload_i)
        begin
            index_way0_i = index;
            index_way1_i = index;
        end
        else
        begin
            if(LRU[index] == 1'b0)
                index_way0_i = index;
            else
                index_way1_i = index;
        end
    end
    else
    begin
    
        index_way0_i = index;
        index_way1_i = index;
        
        if(free_way0)
        begin
            tag_way0_i = tag;
            valid_way0_i = 1'b1;
            dat_way0_i = cc_dat_i;
        end
        else if(free_way1)
        begin
            tag_way1_i = tag;
            valid_way1_i = 1'b1;
            dat_way1_i = cc_dat_i;
        end
    end
    
    LRU[index] = 1'b0 ? compRes_way0 : 1'b1;
    
    if(hit_way0)
    begin
        dat_way0_i = cc_dat_i;
        valid_way0_i = 1'b0;
    end
    else if(hit_way1)
    begin
        dat_way1_i = cc_dat_i;
        valid_way1_i = 1'b0;
    end
end

comparator comp_way0 (.a(tag_way0_o), .b(tag), .eq(compRes_way0));
comparator comp_way1 (.a(tag_way1_o), .b(tag), .eq(compRes_way1));

and a0(hit_way0,valid_way0_o,compRes_way0);
and a1(hit_way1,valid_way1_o,compRes_way1);

or o0(cache_hit_o,hit_way0,hit_way1);
or o1(cache_free_o,free_way0,free_way1);

mux2to1 datamux (.a(dat_way0_o), .b(dat_way1_o), .out(data_read), .sel1(hit_way0), .sel2(hit_way1));

tagRam tagRam_way0 (.index_i(index_way0_i), .tag_i(tag_way0_i), .we_i(cc_we_i), .unload_i(cc_deload_i), .rst(rst), .tag_o(tag_way0_o), .free_o(free_way0));
tagRam tagRam_way1 (.index_i(index_way1_i), .tag_i(tag_way1_i), .we_i(cc_we_i), .unload_i(cc_deload_i), .rst(rst), .tag_o(tag_way1_o), .free_o(free_way1));
dataRam dataRam_way0 (.index_i(index_way0_i), .data_i(dat_way0_i), .we_i(cc_we_i), .unload_i(cc_deload_i), .rst(rst), .data_o(dat_way0_o));
dataRam dataRam_way1 (.index_i(index_way1_i), .data_i(dat_way1_i), .we_i(cc_we_i), .unload_i(cc_deload_i), .rst(rst), .data_o(dat_way1_o));
validRam validRam_way0 (.index_i(index_way0_i), .valid_i(valid_way0_i), .we_i(cc_we_i), .unload_i(cc_deload_i), .rst(rst), .valid_o(valid_way0_o));
validRam validRam_way1 (.index_i(index_way1_i), .valid_i(valid_way1_i), .we_i(cc_we_i), .unload_i(cc_deload_i), .rst(rst), .valid_o(valid_way1_o));

assign cache_dat_o = data_read;

endmodule
