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

module cache_4way
#(

    parameter DATA_WIDTH = 32,
    parameter ADR_WIDTH = 32,
    parameter INDEX_WIDTH = 7,
    parameter TAG_WIDTH = 23,
    parameter WORD_OFFSET_WIDTH = 2,
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
    input mshr_load_adr_i,
    input mshr_load_dat_i,
    
    output reg mshr_victim_adr_o,
    output reg mshr_victim_dat_o,
    output reg mshr_word_o
    
);

localparam VALID_POS = 31;
localparam DIRTY_POS = 30;
localparam TAG_BEGIN = ADR_WIDTH-1;
localparam TAG_END = TAG_BEGIN-TAG_WIDTH;
localparam INDEX_BEGIN = TAG_END-1;
localparam INDEX_END = INDEX_BEGIN - INDEX_WIDTH;
localparam WORD_OFFSET_BEGIN = INDEX_END-1;
localparam WORD_OFFSET_END = WORD_OFFSET_BEGIN - WORD_OFFSET_WIDTH;
localparam VALID_WIDTH = 1;
localparam DIRTY_WIDTH = 1;

localparam IDLE=3'b000, LOOKUP=3'b001, READ=3'b010, REFILL_BLOCKED=3'b011, REFILL=3'b100;
localparam FIRST=3'b001, SECOND=3'b010, THIRD=3'b011, FOURTH=3'b100, END=3'b000;

reg [2:0] ss, ss_next;
reg [1:0] deload_ss, deload_ss_next;

reg we_tag_way0, we_tag_way1, we_tag_way2, we_tag_way3;
reg we_dat_way0, we_dat_way1, we_dat_way2, we_dat_way3;

reg [TAG_WIDTH-1:0] write_tag_way0, write_tag_way1, write_tag_way2, write_tag_way3;
reg [DATA_WIDTH-1:0] write_dat_way0, write_dat_way1, write_dat_way2, write_dat_way3;

wire [DATA_WIDTH-1:0] read_dat_way0, read_dat_way1, read_dat_way2, read_dat_way3;
wire [TAG_WIDTH+VALID_WIDTH+DIRTY_WIDTH-1:0] read_tag_way0, read_tag_way1, read_tag_way2, read_tag_way3;

wire [TAG_WIDTH-1:0] tag;
wire [INDEX_WIDTH-1:0] index;
wire [WORD_OFFSET_WIDTH-1:0] word_offset;

wire hit, hit_way0, hit_way1, hit_way2, hit_way3;
wire [1:0]way_hit;
wire valid_way0, valid_way1, valid_way2, valid_way3;
wire dirty_way0, dirty_way1, dirty_way2, dirty_way3;
wire comp_tag_way0, comp_tag_way1, comp_tag_way2, comp_tag_way3;
wire [TAG_WIDTH-1:0] tag_way0, tag_way1, tag_way2, tag_way3;

reg [1:0] lru_way;
reg [1:0] lru_value;
reg [1:0][WAY_NUM-1:0] LRU [CACHE_LINES-1:0];
reg [1:0][WAY_NUM-1:0] lru_next;

reg deload_line;
reg [WORD_OFFSET_WIDTH-1:0] word_deload;
reg [DATA_WIDTH-1:0] data_read;

assign tag = cpu_adr_i[TAG_BEGIN:TAG_END];
assign index = cpu_adr_i[INDEX_BEGIN:INDEX_END];
assign word_offset = (deload_line==1'b0) ? cpu_adr_i[WORD_OFFSET_BEGIN:WORD_OFFSET_END] : word_deload;

assign valid_way0 = read_tag_way0[VALID_POS];
assign valid_way1 = read_tag_way1[VALID_POS];
assign valid_way2 = read_tag_way2[VALID_POS];
assign valid_way3 = read_tag_way3[VALID_POS];

assign dirty_way0 = read_tag_way0[DIRTY_POS];
assign dirty_way1 = read_tag_way1[DIRTY_POS];
assign dirty_way2 = read_tag_way2[DIRTY_POS];
assign dirty_way3 = read_tag_way3[DIRTY_POS];

assign tag_way0 = read_tag_way0[TAG_BEGIN:TAG_END];
assign tag_way1 = read_tag_way1[TAG_BEGIN:TAG_END];
assign tag_way2 = read_tag_way2[TAG_BEGIN:TAG_END];
assign tag_way3 = read_tag_way3[TAG_BEGIN:TAG_END];

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
        deload_ss <= END;
    end
    else
    begin
        ss <= ss_next;
        deload_ss <= deload_ss_next;
        for(i=0; i<WAY_NUM; i=i+1)
        begin
            LRU[index][i] <= lru_next[i];
        end
    end
end

always@(*)
begin
    
    case(ss)
    IDLE:
        begin
        
            // mettere qui il reset
            we_dat_way0 = 1'b0;
            we_dat_way1 = 1'b0;
            we_dat_way2 = 1'b0;
            we_dat_way3 = 1'b0;
            
            we_tag_way0 = 1'b0;
            we_tag_way1 = 1'b0;
            we_tag_way2 = 1'b0;
            we_tag_way3 = 1'b0;
            
            deload_line = 1'b0;
        
            if(cpu_req_i==1'b1)
            begin
                ss_next = LOOKUP;
            end
        end
    LOOKUP:
        begin
            if(hit)
            begin
            
                ss_next = IDLE;
                cpu_ack_o = 1'b1;
                
                if(cpu_rdwr_i == 1'b0) // READ HIT
                begin
                    case(way_hit)
                    2'b00: cpu_dat_o = read_dat_way0;
                    2'b01: cpu_dat_o = read_dat_way1;
                    2'b10: cpu_dat_o = read_dat_way2;
                    2'b11: cpu_dat_o = read_dat_way3;
                    endcase
                    /*
                    if(hit_way0 == 1'b1)
                        cpu_dat_o = read_dat_way0;
                    else if(hit_way1 == 1'b1)
                        cpu_dat_o = read_dat_way1;
                    else if(hit_way2 == 1'b1) 
                        cpu_dat_o = read_dat_way2;
                    else if(hit_way3 == 1'b1)
                        cpu_dat_o = read_dat_way3;
                   */
                end
                else // WRITE HIT
                begin
                    case(way_hit)
                    2'b00: 
                        begin
                            write_dat_way0 = cpu_dat_i;
                            we_dat_way0 =  1'b1;
                        end
                    2'b01: 
                        begin
                            write_dat_way1 = cpu_dat_i;
                            we_dat_way1 =  1'b1;
                        end
                    2'b10:
                        begin
                            write_dat_way2 = cpu_dat_i;
                            we_dat_way2 =  1'b1;
                        end
                    2'b11: 
                        begin
                            write_dat_way3 = cpu_dat_i;
                            we_dat_way3 =  1'b1;
                        end
                    endcase
                    /*
                    if(hit_way0 == 1'b1)
                    begin
                        write_dat_way0 = cpu_dat_i;
                        we_dat_way0 =  1'b1;
                    end
                    else if(hit_way1 == 1'b1)
                    begin
                        write_dat_way1 = cpu_dat_i;
                        we_dat_way1 =  1'b1;
                    end
                    else if(hit_way2 == 1'b1)
                    begin 
                        write_dat_way2 = cpu_dat_i;
                        we_dat_way2 =  1'b1;
                    end
                    else if(hit_way3 == 1'b1)
                    begin
                        write_dat_way3 = cpu_dat_i;
                        we_dat_way3 =  1'b1;
                    end
                    */
                end
             end
             else // MISS
             begin
                 ss_next = REFILL_BLOCKED;
                 
                 //Forward request toward the memory
                 //---------------------------------//
                 mem_req_o = 1'b1;
                 mem_adr_o = cpu_adr_i;
                 
                 //select victim line
                 
                 deload_line=1'b1;
                 word_deload = 2'b00;
                 deload_ss_next = FIRST;
                 
             end
        end     
    REFILL_BLOCKED:
        begin
        
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

tagRam tagRam_way0 (.clk(clk), .index(index), .data_in(write_tag_way0), .we(we_tag_way0), .data_out(read_tag_way0));
tagRam tagRam_way1 (.clk(clk), .index(index), .data_in(write_tag_way1), .we(we_tag_way1), .data_out(read_tag_way1));
tagRam tagRam_way2 (.clk(clk), .index(index), .data_in(write_tag_way2), .we(we_tag_way2), .data_out(read_tag_way2));
tagRam tagRam_way3 (.clk(clk), .index(index), .data_in(write_tag_way3), .we(we_tag_way3), .data_out(read_tag_way3));

dataRam dataRam_way0 (.clk(clk), .index(index), .offset(word_offset), .data_in(write_dat_way0), .we(we_dat_way0), .data_out(read_dat_way0));
dataRam dataRam_way1 (.clk(clk), .index(index), .offset(word_offset), .data_in(write_dat_way1), .we(we_dat_way1), .data_out(read_dat_way1));
dataRam dataRam_way2 (.clk(clk), .index(index), .offset(word_offset), .data_in(write_dat_way2), .we(we_dat_way2), .data_out(read_dat_way2));
dataRam dataRam_way3 (.clk(clk), .index(index), .offset(word_offset), .data_in(write_dat_way3), .we(we_dat_way3), .data_out(read_dat_way3));


endmodule
