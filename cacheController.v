`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/01/2019 12:41:28 PM
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
    parameter WORD_WIDTH        = 32,
    parameter ADR_WIDTH         = 32,
    parameter INDEX_WIDTH       = 7,
    parameter TAG_WIDTH         = 21,
    parameter BYTE_OFFSET_WIDTH = 2,
    parameter WORD_OFFSET_WIDTH = 2,
    parameter DATAMEM_WIDTH     = 128,
    parameter VALID_WIDTH       = 1,
    parameter DIRTY_WIDTH       = 1,
    parameter WORD_NUM          = 4,
    parameter CACHE_LINES       = 128,
    parameter WAY_NUM           = 4
)
(

    input clk,
    input rst,

    // CPU
    //-------------------------//
    input                       req_cpu2cc,
    input      [ADR_WIDTH-1:0]  adr_cpu2cc,
    input      [WORD_WIDTH-1:0] dat_cpu2cc,
    input                       rdwr_cpu2cc,
    output reg                  ack_cc2cpu,
    output reg [WORD_WIDTH-1:0] dat_cc2cpu,

    // MEM
    //-------------------------//
    input                        ack_mem2cc,
    input      [WORD_WIDTH-1:0]  dat_mem2cc,
    output reg                   req_cc2mem,
    output reg [ADR_WIDTH-1:0]   adr_cc2mem,
    
    // MSHR
    //-------------------------//
    output reg  [WORD_WIDTH-1:0]         dat_mem2mshr,
    output reg  [DATAMEM_WIDTH-1:0]      dat_cc2mshr,
    output wire [WORD_OFFSET_WIDTH-1:0]  word_mem2mshr
    
);

//---------------------------------------------------------//
// LOCAL PARAMETER DEFINITION
//---------------------------------------------------------//

// WIDTH
localparam LRU_WIDTH             = 2;
localparam TAGWAY_WIDTH          = VALID_WIDTH+DIRTY_WIDTH+TAG_WIDTH;
localparam TAGMEM_WIDTH          = TAGWAY_WIDTH*WAY_NUM+LRU_WIDTH;
localparam INDEX_WAY             = INDEX_WIDTH+2;

// ADR OFFSET
localparam LRU_BEGIN             = 93;
localparam LRU_END               = 92;
localparam ADR_TAG_BEGIN         = 11;
localparam ADR_TAG_END           = 31;
localparam ADR_INDEX_BEGIN       = 4; 
localparam ADR_INDEX_END         = 10;
localparam ADR_WORD_OFFSET_BEGIN = 2;
localparam ADR_WORD_OFFSET_END   = 3;
localparam ADR_BYTE_OFFSET_BEGIN = 0;
localparam ADR_BYTE_OFFSET_END   = 1;
localparam WORD_BEGIN            = 32;
localparam WORD_END              = 1;

// FSM STATES
localparam  IDLE=3'b000, 
            LOOKUP=3'b001, 
            HIT=3'b010, 
            REFILL_BLOCKED=3'b011, 
            REFILL=3'b100;

 /*
* Tag memory layout
*            +----------------------------------------------------------------------------------------+
* (index) -> | lru_way | wayN valid | wayN dirty | wayN tag |... | way0 valid | way0 dirty | way0 tag |
*            +----------------------------------------------------------------------------------------+
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

//---------------------------------------------------------//
// REGISTER / WIRE DEFINITION
//---------------------------------------------------------//

reg [2:0]                       ss;
reg [2:0]                       ss_next;
reg [1:0]                       cnt_fetch; 
reg [1:0]                       cnt_fetch_next;

reg [TAGMEM_WIDTH-1:0]          readTag;
reg [TAG_WIDTH-1:0]             writeTag;
reg [DATAMEM_WIDTH-1:0]         readData;
reg [WORD_WIDTH-1:0]            writeData;

reg                             writeDirty;
reg                             we_tag;
reg                             we_data;
reg                             cache_req;
reg                             fetch_line;

reg [TAGMEM_WIDTH-1:0]          tagMem          [CACHE_LINES-1:0];
reg [DATAMEM_WIDTH-1:0]         dataMem         [(WAY_NUM*CACHE_LINES)-1:0];
reg [(LRU_WIDTH*WAY_NUM)-1:0]   lruMem          [CACHE_LINES-1:0];

reg [LRU_WIDTH-1:0]             lru_next        [WAY_NUM-1:0];
reg [(LRU_WIDTH*WAY_NUM)-1:0]   lru_read;
reg [1:0]                       lru_value;
reg                             update_lru;
reg [1:0]                       write_lru;
reg [1:0]                       lru_index;

wire [TAG_WIDTH-1:0]            tag;
wire [INDEX_WIDTH-1:0]          index;
wire [WORD_OFFSET_WIDTH-1:0]    word_offset;
wire [BYTE_OFFSET_WIDTH-1:0]    byte_offset;

wire [1:0]                      lru_way;
wire [1:0]                      way_hit;
wire                            hit;
wire                            hit_way0;
wire                            hit_way1;
wire                            hit_way2;
wire                            hit_way3;
wire [1:0]                      way;

wire [1:0]                      lru_way0;
wire [1:0]                      lru_way1;
wire [1:0]                      lru_way2;
wire [1:0]                      lru_way3;

wire                            valid_way0;
wire                            valid_way1;
wire                            valid_way2;
wire                            valid_way3;

wire                            dirty_way0;
wire                            dirty_way1;
wire                            dirty_way2;
wire                            dirty_way3;

wire                            comp_tag_way0;
wire                            comp_tag_way1;
wire                            comp_tag_way2;
wire                            comp_tag_way3;

wire [TAG_WIDTH-1:0]            tag_way0;
wire [TAG_WIDTH-1:0]            tag_way1;
wire [TAG_WIDTH-1:0]            tag_way2;
wire [TAG_WIDTH-1:0]            tag_way3;

wire [INDEX_WAY-1:0]            data_index;

integer i, j;

//---------------------------------------------------------//
// CONTINUOUS ASSIGNMENTS
//---------------------------------------------------------//

assign tag           = adr_cpu2cc[ADR_TAG_END : ADR_TAG_BEGIN];
assign index         = adr_cpu2cc[ADR_INDEX_END : ADR_INDEX_BEGIN];
assign word_offset   = (fetch_line==1'b0) ? adr_cpu2cc[ADR_WORD_OFFSET_END : ADR_WORD_OFFSET_BEGIN] : cnt_fetch;
assign byte_offset   = adr_cpu2cc[ADR_BYTE_OFFSET_END : ADR_BYTE_OFFSET_BEGIN]; //00
assign data_index    = {index,way};

assign lru_way0     = lru_read[1:0];
assign lru_way1     = lru_read[3:2];
assign lru_way2     = lru_read[5:4];
assign lru_way3     = lru_read[7:6];

assign valid_way0    = readTag[22];
assign valid_way1    = readTag[45];
assign valid_way2    = readTag[68];
assign valid_way3    = readTag[91];

assign dirty_way0    = readTag[21];
assign dirty_way1    = readTag[44];
assign dirty_way2    = readTag[67];
assign dirty_way3    = readTag[90];

assign tag_way0      = readTag[20:0];
assign tag_way1      = readTag[43:23];
assign tag_way2      = readTag[66:46];
assign tag_way3      = readTag[89:69];

assign lru_way       = readTag[93:92];

assign comp_tag_way0 = (tag_way0 == tag);
assign comp_tag_way1 = (tag_way1 == tag);
assign comp_tag_way2 = (tag_way2 == tag);
assign comp_tag_way3 = (tag_way3 == tag);

assign hit_way0      = comp_tag_way0 & valid_way0;
assign hit_way1      = comp_tag_way1 & valid_way1;
assign hit_way2      = comp_tag_way2 & valid_way2;
assign hit_way3      = comp_tag_way3 & valid_way3;

assign way           = (hit==1'b1) ? way_hit 
                     : lru_way;
                     
assign hit           = hit_way0 | hit_way1 | hit_way2 | hit_way3;

assign way_hit       = (hit_way0==1'b1) ? 2'b00 
                     : (hit_way1==1'b1) ? 2'b01 
                     : (hit_way2==1'b1) ? 2'b10 
                     : (hit_way3==1'b1) ? 2'b11 
                     : lru_way; 

assign word_mem2mshr = cnt_fetch;

//---------------------------------------------------------//
// INITIAL BLOCK
//---------------------------------------------------------// 
initial 
begin

    write_lru = 2'b00;
    
    $readmemb("C:/lru_mem.txt",lruMem);
    $readmemb("C:/data_mem.txt",dataMem);
    $readmemb("C:/tag_mem.txt",tagMem);
          
end

always@(posedge clk)
begin

    if(rst)
    begin
        ss          <= IDLE;
        cnt_fetch   <= 2'b00;
        
        
    end
    else
    begin
    
        begin
                 
            if(we_tag == 1'b0)              readTag                       <= tagMem[index];
            else 
            begin
                if(way_hit == 2'b00)        tagMem[index][22:0]           <= {1'b1,writeDirty,writeTag};
                else if(way_hit == 2'b01)   tagMem[index][45:23]          <= {1'b1,writeDirty,writeTag};
                else if(way_hit == 2'b10)   tagMem[index][68:46]          <= {1'b1,writeDirty,writeTag};
                else if(way_hit == 2'b11)   tagMem[index][91:69]          <= {1'b1,writeDirty,writeTag};
                
                tagMem[index][93:92] <= write_lru;
            
            end
                
            if(we_data == 1'b0)           readData                      <= dataMem[data_index];
            else if(word_offset == 2'b00) dataMem[data_index][31 : 0]   <= writeData;
            else if(word_offset == 2'b01) dataMem[data_index][63 : 32]  <= writeData;
            else if(word_offset == 2'b10) dataMem[data_index][95 : 64]  <= writeData;
            else if(word_offset == 2'b11) dataMem[data_index][127 : 96] <= writeData;
        
        end
        
        ss          <= ss_next;
        cnt_fetch   <= cnt_fetch_next;      
        
        lru_read    <= lruMem[index];
        
        if(we_tag)
        begin
            lruMem[index] <= {lru_next[3],lru_next[2],lru_next[1],lru_next[0]};
        end
    end
end

always@(*)
begin

    ss_next         = ss;
    cnt_fetch_next  = cnt_fetch;
    writeDirty      = 1'b0;
    cache_req       = 1'b1;
    we_data         = 1'b0;
    we_tag          = 1'b0;
    ack_cc2cpu      = 1'b0;
    fetch_line      = 1'b0;
    req_cc2mem      = 1'b0;
    adr_cc2mem      = {ADR_WIDTH{1'b0}};
    dat_cc2mshr     = {DATAMEM_WIDTH{1'b0}};
    dat_cc2cpu      = {WORD_WIDTH{1'b0}};
    writeData       = {WORD_WIDTH{1'b0}};
    dat_mem2mshr    = {WORD_WIDTH{1'b0}};
    writeTag        = {TAG_WIDTH{1'b0}};
    //update_lru      = 1'b0;
    write_lru       = 2'b00;
    lru_value       = 2'b00;
    lru_index       = 2'b00;
    
    for(i=0;i<WAY_NUM;i=i+1)
    begin
        lru_next[i] = 2'b00;
    end
    
    
    case(ss)
    IDLE:
        begin
        
            if(req_cpu2cc == 1'b1)
            begin
                ss_next     = LOOKUP;
            end
            
        end
    LOOKUP:
        begin
           
            if(hit)
            begin
            
                ss_next     = HIT;
                
             end
             else // MISS REPLACE
             begin
                 ss_next        = REFILL_BLOCKED;
                 
                 //Forward request toward the memory
                 //---------------------------------//
                 req_cc2mem     = 1'b1;
                 adr_cc2mem     = adr_cpu2cc;
                 cnt_fetch_next = word_offset; 
                 
                 
             end
             
        end     
    HIT:
        begin
            //update_lru = 1'b1;
            we_tag      = 1'b1;
            writeTag    = tag;
            if(rdwr_cpu2cc == 1'b0) 
            begin
            case(word_offset)
                2'b00: dat_cc2cpu  = readData[31:0];
                2'b01: dat_cc2cpu  = readData[63:32];
                2'b10: dat_cc2cpu  = readData[95:64];
                2'b11: dat_cc2cpu  = readData[127:96];
                endcase
            end
            else 
            begin
                we_data     = 1'b1;
                writeData   = dat_cpu2cc;
                //we_tag      = 1'b1;
                //writeTag    = tag;
                writeDirty  = 1'b1;     
            end
            
            ack_cc2cpu      = 1'b1;
            ss_next         = IDLE;
            
        end
    REFILL_BLOCKED:
        begin
            
            //Deload
            dat_cc2mshr    = readData;
        
            if(ack_mem2cc == 1'b1)
            begin
                
                fetch_line      = 1'b1;
                dat_mem2mshr    = dat_mem2cc;
                cnt_fetch_next  = cnt_fetch + 2'b01;
                
                writeData       = dat_mem2cc;
                we_data         = 1'b1;
                we_tag          = 1'b1;
                //update_lru = 1'b1;
                writeDirty      = 1'b0;
                writeTag        = tag;
                
                // WRITE/HIT MISS HANDLE
                if(rdwr_cpu2cc == 1'b0)
                    dat_cc2cpu  = dat_mem2cc;
                else
                begin
                    writeData   = dat_cpu2cc;
                    writeDirty  = 1'b1;
                end
                
                ack_cc2cpu      = 1'b1;
                
                //nuova richiesta    
                adr_cc2mem      = {adr_cpu2cc[31:4],cnt_fetch_next,2'b00};
                ss_next         = REFILL;
            
            end
        end
    REFILL:
        begin
        
            if(cnt_fetch != adr_cpu2cc[ADR_WORD_OFFSET_END : ADR_WORD_OFFSET_BEGIN])
            begin
                if(ack_mem2cc == 1'b1)
                begin
                    fetch_line      = 1'b1;
                    dat_mem2mshr    = dat_mem2cc;
                    cnt_fetch_next  = cnt_fetch + 2'b01;
                    writeData       = dat_mem2cc;
                    we_data         = 1'b1;
                    adr_cc2mem      = {adr_cpu2cc[31:4],cnt_fetch_next,2'b00};
                end
             end
             else
             begin
                ss_next = IDLE;
             end
        end
    default:
        begin
        end
    endcase
    
    if(we_tag)
    begin
    
        lru_next[0] = (way_hit==2'b00) ? 2'b00 : (lru_way0 < 2'b11) ? lru_way0+2'b01 : lru_way0; 
        lru_next[1] = (way_hit==2'b01) ? 2'b00 : (lru_way1 < 2'b11) ? lru_way1+2'b01 : lru_way1; 
        lru_next[2] = (way_hit==2'b10) ? 2'b00 : (lru_way2 < 2'b11) ? lru_way2+2'b01 : lru_way2; 
        lru_next[3] = (way_hit==2'b11) ? 2'b00 : (lru_way3 < 2'b11) ? lru_way3+2'b01 : lru_way3;
           
        lru_value = 2'b00;
        
        for(i=0; i<WAY_NUM; i=i+1)
        begin
            if(lru_value < lru_next[i])
            begin
                lru_value = lru_next[i];
                write_lru = i;
                //we_tag    = 1'b1;
                writeTag = tag;
            end
        end
        
    end
    
end

endmodule
