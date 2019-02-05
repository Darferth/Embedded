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
    input cpu_dat_i,
    input cpu_rdwr_i,
    
    output reg cpu_ack_o,
    output reg cpu_dat_o,

    // MEM
    //-------------------------//
    output reg mem_req_o,
    output reg mem_adr_o,  
    output reg mem_dat_o, //<-- serve?
    output reg mem_rdwr_o, //<-- serve?
    
    input mem_ack_i,
    input mem_dat_i, //<-- serve?  

    // MSHR
    //-------------------------//
    input mshr_load_dat_i,
    
    output reg mshr_victim_dat_o,
    output reg mshr_victim_word_o
    
);

localparam LRU_WIDTH = 2;
localparam LRU_BEGIN = 93;
localparam LRU_END = 92;

localparam VALID_POS = 31;
localparam DIRTY_POS = 30;

localparam VALID_OFFSET = 22;
localparam DIRTY_OFFSET = 21;

localparam TAG_BEGIN = 20;
localparam TAG_END = TAG_BEGIN-TAG_WIDTH;

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
localparam TAGMEM_WIDTH = LRU_WIDTH + (TAGWAY_WIDTH*WAY_NUM);

localparam DATAMEM_WIDTH = (WORD_WIDTH*WORD_NUM);

 /*
* Tag memory layout
*            +------------------------------------------------------------------------------------+
* (index) -> | LRU | wayN valid | wayN dirty | wayN tag |... | way0 valid | way0 dirty | way0 tag |
*            +------------------------------------------------------------------------------------+
*
* Data memory layout (SET)
*
*            +-----------------------------------+
*    Way0    | Word 0 | Word 1 | Word 2 | Word 3 |
*            +-----------------------------------+
*    Way1    | Word 0 | Word 1 | Word 2 | Word 3 |
*            +-----------------------------------+
*    Way2    | Word 0 | Word 1 | Word 2 | Word 3 |
*            +-----------------------------------+
*    Way3    | Word 0 | Word 1 | Word 2 | Word 3 |
*            +-----------------------------------+
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

reg [1:0][WAY_NUM-1:0] lru_next;

reg deload_line;
reg [WORD_OFFSET_WIDTH-1:0] word_deload;
reg [WORD_WIDTH-1:0] data_read;

reg [TAGMEM_WIDTH-1:0] tagMem [CACHE_LINES-1:0];
reg [DATAMEM_WIDTH-1:0] dataMem [WAY_NUM-1:0][CACHE_LINES-1:0];

reg [TAGMEM_WIDTH-1:0] readTag, writeTag;
reg [DATAMEM_WIDTH-1:0] readData, writeData;
reg we_tag, we_data;
reg sel;

assign tag = cpu_adr_i[ADR_TAG_BEGIN : ADR_TAG_END];
assign index = cpu_adr_i[ADR_INDEX_BEGIN : ADR_INDEX_END];
assign word_offset = (deload_line==1'b0) ? cpu_adr_i[ADR_WORD_OFFSET_BEGIN : ADR_WORD_OFFSET_END] : word_deload;
assign byte_offset = cpu_adr_i[ADR_BYTE_OFFSET_BEGIN : ADR_BYTE_OFFSET_END];

assign valid_way0 = readTag[VALID_OFFSET];
assign valid_way1 = readTag[VALID_OFFSET*2];
assign valid_way2 = readTag[VALID_OFFSET*3];
assign valid_way3 = readTag[VALID_OFFSET*4];

assign dirty_way0 = readTag[DIRTY_OFFSET];
assign dirty_way1 = readTag[DIRTY_OFFSET*2];
assign dirty_way2 = readTag[DIRTY_OFFSET*3];
assign dirty_way3 = readTag[DIRTY_OFFSET*4];

// DA SISTEMARE
assign tag_way0 = readTag[TAG_BEGIN:TAG_END];
assign tag_way1 = readTag[TAG_BEGIN*2:TAG_END*2];
assign tag_way2 = readTag[TAG_BEGIN*3:TAG_END*3];
assign tag_way3 = readTag[TAG_BEGIN*4:TAG_END*4];

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
        if(cpu_req_i)
        begin
            readTag <= tagMem[index];
            readData <= dataMem[index][sel];
        end
        if(we_tag) tagMem[index] <= writeTag;
        if(we_data) dataMem[index][sel][word_offset] <= writeData; // SISTEMARE!
   
        ss <= ss_next;
        cnt_fetch <= cnt_fetch_next; 
        cnt_deload <= cnt_deload_next;
        
        /*
        for(i=0; i<WAY_NUM; i=i+1)
        begin
            LRU[index][i] <= lru_next[i];
        end
        */
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
                cpu_ack_o = 1'b1;
                
             end
             else // MISS
             begin
                 ss_next = REFILL_BLOCKED;
                 
                 //Forward request toward the memory
                 //---------------------------------//
                 mem_req_o = 1'b1;
                 mem_adr_o = {cpu_adr_i[31:4],word_offset,2'b00};
                 
                 //select victim line
                 
                 deload_line=1'b1;
                 word_deload=cnt_deload;
                 sel = lru_way;
                 
                 //Data read contiene già la prima word scaricata
                 mshr_victim_dat_o = readData[WORD_BEGIN:WORD_END]; // SISTEMARE
                 mshr_victim_word_o = word_offset;
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
            
            if()
            
            case(deload_ss)
            FIRST:
                begin
                    deload_ss_next=SECOND;
                    word_deload = 2'b01;
                    
                    // Reset richiesta di caricamento dalla memoria
                    // Basta un ciclo di durata?
                    mem_req_o = 1'b1;
                    mem_adr_o = cpu_adr_i;
                end
            SECOND: 
                begin
                    deload_ss_next=THIRD;
                    word_deload = 2'b10;
                end 
            THIRD:
                begin
                    deload_ss_next=END;
                    word_deload = 2'b11;
                end
            endcase
        
            if(deload_line==1'b1)
            begin
                case(lru_way)
                2'b00: data_read =  read_dat_way0;
                2'b01: data_read =  read_dat_way1;
                2'b10: data_read =  read_dat_way2;
                2'b11: data_read =  read_dat_way3;
                endcase
                
                //mshr_victim_adr_o = cpu_adr_i; 
                mshr_victim_dat_o = data_read;
                mshr_word_o = word_deload;
            end                
            
            if(deload_ss == END) // DELOAD COMPLETED
            begin
                deload_line=1'b0;
                if(mem_ack_i)
                begin
                    // START LOAD IN CACHE
                    mshr_word_o = word_offset;
                    deload_ss_next = FIRST;
                    ss_next = REFILL;
                    deload_line=1'b1;
                end
            end
            
        end
    REFILL:
        begin
        
            case(lru_way)
            2'b00:
                begin
                    we_tag_way0 = 1'b1;
                    we_dat_way0 = 1'b1;
                    write_dat_way0 = mshr_load_dat_i;
                    write_tag_way0 = tag;                    
                end
            2'b01:
                begin
                    we_tag_way1 = 1'b1;
                    we_dat_way1 = 1'b1;
                    write_dat_way1 = mshr_load_dat_i;
                    write_tag_way1 = tag;
                end
            2'b10:
                begin
                    we_tag_way2 = 1'b1;
                    we_dat_way2 = 1'b1;
                    write_dat_way2 = mshr_load_dat_i;
                    write_tag_way2 = tag;
                end
            2'b11:
                begin
                    we_tag_way3 = 1'b1;
                    we_dat_way3 = 1'b1;
                    write_dat_way3 = mshr_load_dat_i;
                    write_tag_way3 = tag;
                end
            endcase
            
            case(deload_ss)
            FIRST:
            begin
                cpu_ack_o = 1'b1;
                if(cpu_rdwr_i==1'b0)
                    cpu_dat_o = mshr_load_dat_i;
                else
                    case(lru_way)
                    2'b00: write_dat_way0 = cpu_dat_i;
                    2'b01: write_dat_way1 = cpu_dat_i;
                    2'b10: write_dat_way2 = cpu_dat_i;
                    2'b11: write_dat_way3 = cpu_dat_i;
                    endcase
                
                mshr_word_o = mshr_word_o+1;
                deload_ss_next = SECOND;
            end     
            SECOND:
            begin
                mshr_word_o = mshr_word_o+1;
                deload_ss_next = THIRD;
            end 
            THIRD:
            begin
                mshr_word_o = mshr_word_o+1;
                deload_ss_next = END;
                ss_next = IDLE;
                
            end
            endcase
            
            word_deload = mshr_word_o;
            
        end
    endcase
end

always@(hit)
begin
    for(i=0; i<WAY_NUM; i=i+1)
    begin
        if(LRU[index][i]==LRU[index][way_hit])
            lru_next[i] = 2'b00;
        else if(LRU[index][way_hit] < LRU[index][i])
            lru_next[i] = LRU[index][i] + 2'b01; 
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
