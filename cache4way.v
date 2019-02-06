`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/01/2019 12:41:28 PM
// Design Name: 
// Module Name: cache_4way
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

module cache4way
#(

    parameter WORD_WIDTH = 32,
    parameter ADR_WIDTH = 32,
    parameter INDEX_WIDTH = 7,
    parameter TAG_WIDTH = 21,
    parameter BYTE_OFFSET_WIDTH = 2,
    parameter WORD_OFFSET_WIDTH = 2,
    parameter VALID_WIDTH = 1,
    parameter DIRTY_WIDTH = 1,
    parameter WORD_NUM = 4,
    parameter CACHE_LINES = 128,
    parameter WAY_NUM = 4
)
(

    input clk,
    input rst,

    // CPU
    //-------------------------//
    input cpu_req_i,
    input [ADR_WIDTH-1:0] cpu_adr_i,
    input [WORD_WIDTH-1:0]cpu_dat_i,
    input cpu_rdwr_i,
    
    output reg cpu_ack_o,
    output reg [WORD_WIDTH-1:0]cpu_dat_o,

    // MEM
    //-------------------------//
    output reg mem_req_o,
    output reg [ADR_WIDTH-1:0]mem_adr_o,
    
    input mem_ack_i,
    input mem_dat_i,

    // MSHR
    //-------------------------//
    output reg mshr_load_dat_o,
    output reg mshr_load_word_o,
    output reg mshr_victim_dat_o,
    output reg mshr_victim_word_o
    
);

localparam LRU_WIDTH = 2;
localparam LRU_BEGIN = 93;
localparam LRU_END = 92;

localparam ADR_TAG_BEGIN = 11;
localparam ADR_TAG_END = 31;
localparam ADR_INDEX_BEGIN = 4; 
localparam ADR_INDEX_END = 10;
localparam ADR_WORD_OFFSET_BEGIN = 2;
localparam ADR_WORD_OFFSET_END = 3;
localparam ADR_BYTE_OFFSET_BEGIN = 0;
localparam ADR_BYTE_OFFSET_END = 1;

localparam WORD_BEGIN = 32;
localparam WORD_END = 1;

localparam TAGWAY_WIDTH = VALID_WIDTH+DIRTY_WIDTH+TAG_WIDTH;
localparam TAGMEM_WIDTH = TAGWAY_WIDTH*WAY_NUM;

localparam DATAMEM_WIDTH = (WORD_WIDTH*WORD_NUM);

 /*
* Tag memory layout
*            +------------------------------------------------------------------------------+
* (index) -> | wayN valid | wayN dirty | wayN tag |... | way0 valid | way0 dirty | way0 tag |
*            +------------------------------------------------------------------------------+
*
* Data memory layout (SET)
*
*            +-----------------------------------+     -+
*    Way0    | Word 0 | Word 1 | Word 2 | Word 3 |      |
*            +-----------------------------------+      |  
*    Way1    | Word 0 | Word 1 | Word 2 | Word 3 |      |
*            +-----------------------------------+      | SET i <- (index)
*    Way2    | Word 0 | Word 1 | Word 2 | Word 3 |      |
*            +-----------------------------------+      |
*    Way3    | Word 0 | Word 1 | Word 2 | Word 3 |      |
*            +-----------------------------------+     -+
*/

localparam IDLE=3'b000, LOOKUP=3'b001, HIT=3'b010, REFILL_BLOCKED=3'b011, REFILL=3'b100;

reg [2:0] ss, ss_next;
reg [1:0] cnt_fetch, cnt_fetch_next;
reg [1:0] cnt_deload, cnt_deload_next;

wire [TAG_WIDTH-1:0] tag;
wire [INDEX_WIDTH-1:0] index;
wire [WORD_OFFSET_WIDTH-1:0] word_offset;
wire [BYTE_OFFSET_WIDTH-1:0] byte_offset;

wire hit, hit_way0, hit_way1, hit_way2, hit_way3;
wire [1:0] way_hit;
wire valid_way0, valid_way1, valid_way2, valid_way3;
wire dirty_way0, dirty_way1, dirty_way2, dirty_way3;
wire comp_tag_way0, comp_tag_way1, comp_tag_way2, comp_tag_way3;
wire [TAG_WIDTH-1:0] tag_way0, tag_way1, tag_way2, tag_way3;

reg [1:0] lru_way;
reg [1:0] lru_value;

reg deload_line;
reg fetch_line;
reg [WORD_OFFSET_WIDTH-1:0] word_deload;
reg [WORD_WIDTH-1:0] data_read;

reg [TAGMEM_WIDTH-1:0] tagMem [CACHE_LINES-1:0];
reg [DATAMEM_WIDTH-1:0] dataMem [WAY_NUM-1:0][CACHE_LINES-1:0];
reg [LRU_WIDTH-1:0] lruMem [WAY_NUM-1:0][CACHE_LINES-1:0];
reg [LRU_WIDTH-1:0] lru_next [WAY_NUM-1:0];

reg [TAGMEM_WIDTH-1:0] readTag, writeTag;
reg [DATAMEM_WIDTH-1:0] readData, writeData;
reg we_tag, we_data;
reg sel;

assign tag = cpu_adr_i[ADR_TAG_END : ADR_TAG_BEGIN];
assign index = cpu_adr_i[ADR_INDEX_END : ADR_INDEX_BEGIN];
assign word_offset = (fetch_line==1'b0) ? cpu_adr_i[ADR_WORD_OFFSET_END : ADR_WORD_OFFSET_BEGIN] : cnt_fetch;
assign byte_offset = cpu_adr_i[ADR_BYTE_OFFSET_END : ADR_BYTE_OFFSET_BEGIN];

assign valid_way0 = readTag[22];
assign valid_way1 = readTag[45];
assign valid_way2 = readTag[68];
assign valid_way3 = readTag[91];

assign dirty_way0 = readTag[21];
assign dirty_way1 = readTag[44];
assign dirty_way2 = readTag[67];
assign dirty_way3 = readTag[90];

assign tag_way0 = readTag[20:0];
assign tag_way1 = readTag[43:23];
assign tag_way2 = readTag[66:46];
assign tag_way3 = readTag[89:69];

assign comp_tag_way0 = (tag_way0 == tag);
assign comp_tag_way1 = (tag_way1 == tag);
assign comp_tag_way2 = (tag_way2 == tag);
assign comp_tag_way3 = (tag_way3 == tag);

assign hit_way0 = comp_tag_way0 & valid_way0;
assign hit_way1 = comp_tag_way1 & valid_way1;
assign hit_way2 = comp_tag_way2 & valid_way2;
assign hit_way3 = comp_tag_way3 & valid_way3;

assign hit = hit_way0 | hit_way1 | hit_way2 | hit_way3;

assign way_hit = (hit_way0==1'b1) ? 2'b00 : (hit_way1==1'b1) ? 2'b01 : (hit_way2==1'b1) ? 2'b10 : 2'b11; 

integer i;

always@(posedge clk)
begin
    if(rst)
    begin
        ss <= IDLE;
        cnt_fetch <= 2'b00;
        cnt_deload <= 2'b00;
    end
    else
    begin
    
        if(cpu_req_i == 1'b1) //Da mettere?
        begin
            if(we_tag == 1'b0) readTag <= tagMem[index];
            else
                if(way_hit == 2'b00) tagMem[index][20:0] <= writeTag;
                else if(way_hit == 2'b01) tagMem[index][43:23] <= writeTag; 
                else if(way_hit == 2'b10) tagMem[index][66:46] <= writeTag; 
                else if(way_hit == 2'b11) tagMem[index][89:69] <= writeTag;
                
            if(we_data == 1'b0) readData <= dataMem[index][sel];
            else
                if(word_offset == 2'b00) dataMem[index][sel][31 : 0] <= writeData;
                else if(word_offset == 2'b01) dataMem[index][sel][63 : 32] <= writeData;
                else if(word_offset == 2'b10) dataMem[index][sel][95 : 64] <= writeData;
                else if(word_offset == 2'b11) dataMem[index][sel][127 : 96] <= writeData;
            
        end
   
        ss <= ss_next;
        cnt_fetch <= cnt_fetch_next; 
        cnt_deload <= cnt_deload_next;
        
        for(i=0; i<WAY_NUM; i=i+1)
        begin
            lruMem[index][i] <= lru_next[i];
        end
    end
end

always@(*)
begin
    
    case(ss)
    IDLE:
        begin
        
            we_data = 1'b0;
            we_tag = 1'b0;
            cpu_ack_o = 1'b0;
            deload_line = 1'b0;
            sel = lru_way;
        
            if(cpu_req_i==1'b1)
            begin
                ss_next = LOOKUP;
            end
        end
    LOOKUP:
        begin
            if(hit)
            begin
            
                sel = way_hit;
                ss_next = HIT;
                
             end
             else // MISS
             begin
                 ss_next = REFILL_BLOCKED;
                 
                 //Forward request toward the memory
                 //---------------------------------//
                 mem_req_o = 1'b1;
                 mem_adr_o = cpu_adr_i;
                 cnt_fetch_next = word_offset; 
                 //mem_adr_o = {cpu_adr_i[31:4],word_offset,2'b00};
                 
                 //select victim line
                 
                 deload_line=1'b1;
                 //word_deload=cnt_deload;
                 //sel = lru_way;
                 
                 //Data read contiene gi� la linea da scaricare 
                 case(word_offset)
                 2'b00: mshr_victim_dat_o = readData[95 : 64];
                 2'b01: mshr_victim_dat_o = readData[63 : 32];
                 2'b10: mshr_victim_dat_o = readData[95 : 64];
                 2'b11: mshr_victim_dat_o = readData[127 : 96];
                 endcase
                 mshr_victim_word_o = word_offset;
                 
                 cnt_deload_next = cpu_adr_i[ADR_WORD_OFFSET_END : ADR_WORD_OFFSET_BEGIN] + 2'b01;
             end
        end     
    HIT:
        begin
            if(cpu_rdwr_i == 1'b0) cpu_dat_o = readData;
            else 
            begin
                we_data = 1'b1;
                writeData = cpu_dat_i;     
            end
            cpu_ack_o = 1'b1;
            
            ss_next = IDLE;
        end
    REFILL_BLOCKED:
        begin
            if(cnt_deload != cpu_adr_i[ADR_WORD_OFFSET_END : ADR_WORD_OFFSET_BEGIN])
            begin
                case(cnt_deload)
                2'b00: mshr_victim_dat_o = readData[95 : 64];
                2'b01: mshr_victim_dat_o = readData[63 : 32];
                2'b10: mshr_victim_dat_o = readData[95 : 64];
                2'b11: mshr_victim_dat_o = readData[127 : 96];
                endcase
                mshr_victim_word_o = cnt_deload;
                cnt_deload_next = cnt_deload + 2'b01;
                deload_line = 1'b0;
            end
            
            if(deload_line == 1'b0 && mem_ack_i == 1'b1)
            begin
                fetch_line = 1'b1;
                ss_next = REFILL;
                mshr_load_dat_o = mem_dat_i;
                mshr_load_word_o = cnt_fetch;
                cnt_fetch_next = cnt_fetch + 2'b01;
                
                writeData = mem_dat_i;
                we_data = 1'b1;
                we_tag = 1'b1;
                writeTag = tag;
                
                if(cpu_rdwr_i==1'b0)
                    cpu_dat_o = mem_dat_i;
                else
                    writeData = cpu_dat_i;
                cpu_ack_o = 1'b1;
                
                //nuova richiesta    
                mem_adr_o = {cpu_adr_i[31:4],cnt_fetch_next,2'b00};
            end
        end
    REFILL:
        begin
            if(cnt_fetch != cpu_adr_i[ADR_WORD_OFFSET_END : ADR_WORD_OFFSET_BEGIN])
            begin
                if(mem_ack_i == 1'b1)
                begin
                    mshr_load_dat_o = mem_dat_i;
                    mshr_load_word_o = cnt_fetch;
                    cnt_fetch_next = cnt_fetch + 2'b01;
                    writeData = mem_dat_i;
                    we_data = 1'b1;
                    mem_adr_o = {cpu_adr_i[31:4],cnt_fetch_next,2'b00};
                end
             end
             else
             begin
                ss_next = IDLE;
             end
        end
    endcase
end


always@(posedge hit) //non sicuro del fronte di salita dell'hit
begin
    
    for(i=0; i<WAY_NUM; i=i+1)
    begin
        if(lruMem[index][i]==lruMem[index][way_hit])
                lru_next[i] = 2'b00;
            else if(lruMem[index][way_hit] < lruMem[index][i])
                lru_next[i] = lruMem[index][i] + 2'b01; 
    end
       
    lru_value=2'b00;
    lru_way=2'b00;
    
    for(i=0; i<WAY_NUM; i=i+1)
    begin
        if(lru_value < lru_next[i])
        begin
            lru_value = lru_next[i];
            lru_way = i;
        end
    end
end

endmodule
