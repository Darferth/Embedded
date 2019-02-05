`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.02.2019 17:20:57
// Design Name: 
// Module Name: 4_way_tb
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
`define ADR_WIDTH 32
`define DATA_WIDTH 32

module cache_tb();
reg clk;
reg rst;
reg cpu_req_i;
reg [`ADR_WIDTH-1:0] cpu_adr_i;
reg [`DATA_WIDTH-1:0] cpu_dat_i;
reg cpu_rdwr_i;
wire cpu_ack_o;
wire [`DATA_WIDTH-1:0] cpu_dat_o;
wire mem_req_o;
wire [`ADR_WIDTH-1:0] mem_adr_o;
wire [`DATA_WIDTH-1:0]mem_dat_o;
wire mem_rdwr_o; 
    
reg mem_ack_i;
reg mem_dat_i;  //128 bit o 32 bit?
reg mshr_load_adr_i; //128 bit o 32 bit?
reg mshr_load_dat_i; //128 bit o 32 bit?
wire mshr_victim_adr_o;
wire mshr_victim_dat_o;
wire mshr_word_o;

always #5 clk=~clk;

initial
begin
    
    clk=0;
    rst<=1'b1;
    
    #10
    
    /*WRITE REQUEST MISS, FREE CACHE =>
     ALLOCATES IN CACHE THE LINE, THEN WRITES WORD
    MEM VALUE MISSING, NEED TO ADD IT*/
    rst<=1'b0;
    cpu_adr_i<=32'b00000000110011000011101101000011;
    cpu_dat_i<=32'b11101010100110011010100101001010;
    cpu_rdwr_i<=1'b1;
    cpu_req_i<=1'b1;
    
    #10
    
    cpu_req_i<=1'bx;
    cpu_adr_i<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
    cpu_dat_i<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
    cpu_rdwr_i<=1'bx;
    
    #10
    
    /*READ REQUEST MISS, FREE CACHE=> ASSUMING (TAG+INDEX+4bit)
    ALLOCATES IN ANOTHER WAY, SAME INDEX AS BEFORE(FIRST BIT OF TAG 0 INSTEAD OF 1)
    MEM VALUE MISSING, NEED TO ADD IT
    */
    cpu_adr_i<=32'b00000000110011000011001101000011;
    cpu_rdwr_i<=1'b0;
    cpu_req_i<=1'b1;
    
    #10
    
    cpu_req_i<=1'bx;
    cpu_adr_i<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
    cpu_dat_i<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
    cpu_rdwr_i<=1'bx;
    
    #10
    
   /*READ REQUEST HIT, READS THE WORD REQUESTED*/
    cpu_adr_i<=32'b00000000110011000011101101000011;
    cpu_rdwr_i<=1'b0;
    cpu_req_i<=1'b1;
    
    #10
    
    cpu_req_i<=1'bx;
    cpu_adr_i<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
    cpu_dat_i<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
    cpu_rdwr_i<=1'bx;
    
    #10
    
    /*FILL A 4 WAY BLOCK IN ORDER TO INDUCE A READ MISS/WRITE MISS WITH REFILL*/
    cpu_adr_i<=32'b00000000110011000010001101000011;
    cpu_rdwr_i<=1'b0;
    cpu_req_i<=1'b1;
    
    #10
    
    cpu_req_i<=1'bx;
    cpu_adr_i<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
    cpu_dat_i<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
    cpu_rdwr_i<=1'bx;
    
    #10
    
    cpu_adr_i<=32'b00000000110011000000001101000011;
    cpu_rdwr_i<=1'b0;
    cpu_req_i<=1'b1;
    
    #10
    
    cpu_req_i<=1'bx;
    cpu_adr_i<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
    cpu_dat_i<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
    cpu_rdwr_i<=1'bx;
        
    #10
    
    /*READ MISS, NO SPACE LEFT IN THE SAME INDEX=>
    REPLACE THE OLDEST LINE WITH THE ONE REQUESTED
    MEM VALUE MISSING, NEED TO ADD IT*/ 
    cpu_adr_i<=32'b00000000110011100000001101000011;
    cpu_rdwr_i<=1'b0;
    cpu_req_i<=1'b1;
    
    #10
    
    cpu_req_i<=1'bx;
    cpu_adr_i<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
    cpu_dat_i<=32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
    cpu_rdwr_i<=1'bx;
            
    #10
    
    /*WRITE MISS, NO SPACE LEFT IN THE SAME INDEX=>
    REPLACE THE OLDEST LINE WITH THE ONE IN WHICH I WRITE THE WORD
    MEM VALUE MISSING, NEED TO ADD IT*/
    cpu_adr_i<=32'b00000000100001000011101101000011;
    cpu_dat_i<=32'b11101010100110011010100101001010;
    cpu_rdwr_i<=1'b1;
    cpu_req_i<=1'b1;
    
    #10
    
    $finish;
end

 cache_4way cache_tb(.rst(rst), .cpu_req_i(cpu_req_i), .cpu_adr_i(cpu_adr_i), .cpu_dat_i(cpu_dat_i),
.cpu_rdwr_i(cpu_rdwr_i), .cpu_ack_o(cpu_ack_o), .cpu_dat_o(cpu_dat_o), .mem_req_o(mem_req_o), 
.mem_adr_o(mem_adr_o), .mem_dat_o(mem_dat_o), .mem_rdwr_o(mem_rdwr_o), .mem_ack_i(mem_ack_i),
.mem_dat_i(mem_dat_i), .mshr_load_adr_i(mshr_load_adr_i), .mshr_load_dat_i(mshr_load_dat_i), 
.mshr_victim_adr_o(mshr_victim_adr_o), .mshr_victim_dat_o(mshr_victim_dat_o), .mshr_word_o(mshr_word_o));

endmodule
