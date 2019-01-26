`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.01.2019 18:19:45
// Design Name: 
// Module Name: d_cache
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


module d_cache

#(
    parameter WAY_NUMBER = 2, //Per ora inutile
    parameter ADR_LENGTH = 32,
    parameter INDEX_LENGTH = 7,
    parameter TAG_LENGTH = 22, //da sistemare
    parameter DATA_LENGTH = 32,
    parameter CACHE_LINES = 128
    
    )
(

    input cc_req_i,
    input [ADR_LENGTH-1:0] cc_adr_i,
    input cc_dat_i,
    input cc_we_i,
    output wire cc_hit_o,
    output cc_valid_o,
    output cc_dat_o

    );
    
reg [CACHE_LINES-1:0]LRU;

localparam INDEX_BEGIN = ADR_LENGTH-1;
localparam INDEX_END = INDEX_BEGIN - INDEX_LENGTH;
localparam TAG_BEGIN = INDEX_END-1;
localparam TAG_END = TAG_BEGIN-TAG_LENGTH;

wire index; 
wire tag;

assign index = cc_adr_i[INDEX_BEGIN:INDEX_END];
assign tag = cc_adr_i[TAG_BEGIN:TAG_END];

reg [TAG_LENGTH-1:0] tag_way0;
reg [TAG_LENGTH-1:0] tag_way1;
reg [DATA_LENGTH-1:0] data_way0;
reg [DATA_LENGTH-1:0] data_way1;
reg valid_way0;
reg valid_way1;

tagRam tagRam_way0 (.index_i(index), .tag_i(tag), .we_i(cc_we_i), .tag_o(tag_way0));
tagRam tagRam_way1 (.index_i(index), .tag_i(tag), .we_i(cc_we_i), .tag_o(tag_way1));
dataRam dataRam_way0 (.index_i(index), .data_i(cc_dat_i), .we_i(cc_we_i), .data_o(data_way0));
dataRam dataRam_way1 (.index_i(index), .data_i(cc_dat_i), .we_i(cc_we_i), .data_o(data_way1));
validRam validRam_way0 (.index_i(index), .we_i(cc_we_i), .valid_o(valid_way0));
validRam validRam_way1 (.index_i(index), .we_i(cc_we_i), .valid_o(valid_way1));

wire hit0,hit1;
wire comp0,comp1;

comparator comp_way0 (.a(tag_way0), .b(tag), .eq(comp0));
comparator comp_way1 (.a(tag_way1), .b(tag), .eq(comp1));

always@(posedge cc_req_i)
begin
    LRU[index] = 0 ? (comp0 && ~comp1) : 1 ? (comp1 && ~comp0) : 1'bx;
end

and a0(hit0,valid_way0,comp0);
and a1(hit1,valid_way1,comp1);

and a(cc_hit_o,hit0,hit1);

mux2to1 datamux (.a(data_way0), .b(data_way1), .out(cc_dat_o), .sel1(hit0), .sel2(hit1));
    
endmodule
