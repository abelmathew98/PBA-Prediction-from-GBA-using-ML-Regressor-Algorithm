`timescale 1ns/100ps
//----------------------------------------
//This is the input buffer used in the NoC
//using synchronous FIFO with a depth of 4
//----------------------------------------
//
module sync_fifo (in,out,clk,rst,is_full,is_empty,rd_en,wr_en,x_dest,y_dest);
	parameter depth=4, data_width=8,nbit=(1>>depth),addr_width=3;
	input [(data_width+2*addr_width)-1:0] in;
	output [addr_width-1:0] x_dest;
	output [addr_width-1:0] y_dest;
	output logic [(data_width+2*addr_width)-1:0] out;
	input clk;
	input rst;
	output logic is_full;
	output logic is_empty;
	input rd_en;
	input wr_en;

//internal
	reg [depth-1:0] [(data_width+2*addr_width)-1:0] mem;
	reg [depth-1:0] count;
	reg [nbit-1:0] head;
	reg [nbit-1:0] tail;

	assign x_dest = mem[tail][data_width+addr_width-1:data_width];
	assign y_dest = mem[tail][data_width+2*addr_width-1: data_width+addr_width];
	
//update output
	always @(posedge clk) begin
		if(rst) begin
			out <= '{default:0};
		end
		else begin
			out <= mem[tail];
		end
	end

//update memory
	always @(posedge clk) begin
		if (rst==0) begin
			if (wr_en==1 && is_full==0)
				mem[head] <= in;
		end
	end

//update head register
	always @(posedge clk) begin
		if (rst) begin
			head <= 0;
		end
		else begin
			if (wr_en==1 && is_full==0) begin
				head <= head+1;
			end
		end
	end

//update tail register
	always @(posedge clk) begin
		if (rst) begin
			tail <= 0;
		end
		else begin
			if (rd_en==1 && is_empty==0) begin
				tail <= tail+1;
			end
		end
	end

// Update the count regsiter.
	always @(posedge clk) begin
	   if (rst) begin
	      count <= 0;
	   end
	   else begin
	      unique case ({rd_en,wr_en})
	         2'b00: count <= count;
	         2'b01: if(!is_full)
						count <= count + 1;
	         2'b10: if(!is_empty)
						count <= count - 1;
	         2'b11: count <= count;
	      endcase
	   end
	end
	
//Update the flags
	//empty flag
	always @(count) begin
	  	if (count == 0)
			is_empty = 1'b1;
		else
			is_empty = 1'b0;
	end
	
	//full flag
	always @(count) begin
		if (count < depth)
			is_full = 1'b0;
		else	
			is_full = 1'b1;
	end

endmodule

module fifo (in,out,clk,rst,rd_en,wr_en,is_full,is_empty,x_dest,y_dest);
	parameter n_input=5, data_width=8, addr_width=3;
	input [data_width+2*addr_width-1:0] in [n_input-1:0];
	input [n_input-1:0] rd_en;
	input [n_input-1:0] wr_en;
	input clk;
	input rst;
	output [data_width+2*addr_width-1:0] out [n_input-1:0];
	output [n_input-1:0] is_full;
	output [n_input-1:0] is_empty;
	output [addr_width-1:0] x_dest [n_input-1:0];
	output [addr_width-1:0] y_dest [n_input-1:0];
//	genvar i;
//	generate
//		for(i=0;i<n_input;i++) begin
//			sync_fifo fifo[i] (.in(in[i]),.out(out[i]),.clk(clk),.rst(rst),.is_full(is_full[i]),.is_empty(is_empty[i]),.rd_en(rd_en[i]),.wr_en(wr_en[i]),.x_dest(x_dest[i]),.y_dest(y_dest[i]));
//		end
//	endgenerate

	sync_fifo fifo_0 (.in(in[0]),.out(out[0]),.clk(clk),.rst(rst),.is_full(is_full[0]),.is_empty(is_empty[0]),.rd_en(rd_en[0]),.wr_en(wr_en[0]),.x_dest(x_dest[0]),.y_dest(y_dest[0]));
	sync_fifo fifo_1 (.in(in[1]),.out(out[1]),.clk(clk),.rst(rst),.is_full(is_full[1]),.is_empty(is_empty[1]),.rd_en(rd_en[1]),.wr_en(wr_en[1]),.x_dest(x_dest[1]),.y_dest(y_dest[1]));
	sync_fifo fifo_2 (.in(in[2]),.out(out[2]),.clk(clk),.rst(rst),.is_full(is_full[2]),.is_empty(is_empty[2]),.rd_en(rd_en[2]),.wr_en(wr_en[2]),.x_dest(x_dest[2]),.y_dest(y_dest[2]));
	sync_fifo fifo_3 (.in(in[3]),.out(out[3]),.clk(clk),.rst(rst),.is_full(is_full[3]),.is_empty(is_empty[3]),.rd_en(rd_en[3]),.wr_en(wr_en[3]),.x_dest(x_dest[3]),.y_dest(y_dest[3]));
	sync_fifo fifo_4 (.in(in[4]),.out(out[4]),.clk(clk),.rst(rst),.is_full(is_full[4]),.is_empty(is_empty[4]),.rd_en(rd_en[4]),.wr_en(wr_en[4]),.x_dest(x_dest[4]),.y_dest(y_dest[4]));

endmodule

