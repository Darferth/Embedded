`timescale 1ns / 1ps
module cacheController_tb();
	
	reg clk, rst, lru, free,req_cpu_i, we_cpu_i, adr_cpu_i, dat_cpu_i, ack_mem, dat_mem, cc_hit_i,
	cc_valid_i,cc_dat_i,adr_mshr_load_i, dat_mshr_load_i,adr_mshr_deload_i,dat_mshr_deload_i;
	wire dat_cpu_o, ack_cpu_o, err_cpu_o, adr_m2s, dat_m2s, cyc_m2s, we_m2s,cc_we_o, cc_adr_o,
	cc_dat_o, adr_mshr_load_o, dat_mshr_load_o, adr_mshr_deload_o,dat_mshr_deload_o;
	
		cacheController cachePuzzona(.clk(clk), .rst(rst), .lru(lru), .free(free),
		.req_cpu_i(req_cpu_i), .we_cpu_i(we_cpu_i), .adr_cpu_i(adr_cpu_i), 
		.dat_cpu_i(dat_cpu_i), .ack_mem(ack_mem), .dat_mem(dat_mem), .cc_hit_i(cc_hit_i), 
		.cc_valid_i(cc_valid_i),.cc_dat_i(cc_dat_i),.adr_mshr_load_i(adr_mshr_load_i), 
		.dat_mshr_load_i(dat_mshr_load_i),.adr_mshr_deload_i(adr_mshr_deload_i),
		.dat_mshr_deload_i(dat_mshr_deload_i),.dat_cpu_o(dat_cpu_o), .ack_cpu_o(ack_cpu_o),
		.err_cpu_o(err_cpu_o), .adr_m2s(adr_m2s), .dat_m2s(dat_m2s), .cyc_m2s(cyc_m2s),
		.we_m2s(we_m2s),.cc_we_o(cc_we_o), .cc_adr_o(cc_adr_o),.cc_dat_o(cc_dat_o),
		.adr_mshr_load_o(adr_mshr_load_o), .dat_mshr_load_o(dat_mshr_load_o), 
		.adr_mshr_deload_o(adr_mshr_deload_o),.dat_mshr_deload_o(dat_mshr_deload_o));
		
		initial
		begin
			$monitor("clk%d %d%d%d%d->%d%d%d%d%d%d%d%d%d%d%d%d",clk, req_cpu_i, adr_cpu_i,
			 dat_cpu_i, we_cpu_i, cc_adr_o, cc_dat_o, cc_we_o, dat_cpu_o, ack_cpu_o, 
			 err_cpu_o, cyc_m2s, we_m2s, adr_m2s,dat_m2s,adr_mshr_deload_o,dat_mshr_deload_o );
			 
			clk=0;
			
			//read hit
			
			dat_cpu_i=1;req_cpu_i=1; adr_cpu_i=1; we_cpu_i=0; cc_hit_i=1;cc_valid_i=1;
			repeat(2) @(posedge clk);
			
			//write hit
			
			#10 dat_cpu_i=1;req_cpu_i=1; adr_cpu_i=1; we_cpu_i=1; cc_hit_i=1;cc_valid_i=1;
			repeat(2) @(posedge clk);
			
			//read miss with free cache
			
			#10 dat_cpu_i=1;req_cpu_i=1; adr_cpu_i=1; we_cpu_i=0; cc_hit_i=0;cc_valid_i=0;free=1;ack_mem_i=1; dat_mem_i=1;
			repeat(2) @(posedge clk)
			
			//write miss with free cache
			
			#10 dat_cpu_i=1;req_cpu_i=1; adr_cpu_i=1; we_cpu_i=1; cc_hit_i=0;cc_valid_i=0;free=1; ack_mem_i=1;dat_mem_i=1;
			repeat(2) @(posedge clk)
			
			//read miss with no free cache
			
			#10 dat_cpu_i=1;req_cpu_i=1; adr_cpu_i=1; we_cpu_i=0; cc_hit_i=0;cc_valid_i=0;free=0; ack_mem_i=1;dat_mem_i=1;lru_adr=1;adr_mshr_load_i=1; dat_mshr_load_i=1;
			repeat(2) @(posedge clk)
			
			//write miss with no free cache
			
			
		end
			
		
endmodule
			