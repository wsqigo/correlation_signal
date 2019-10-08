 module ccd_drive(
   input clk,
   input rst_n,
   input key_in,
 
 // TCD1304 signal
	output reg M,
	output reg ICG,
	output reg SH,
	
	// Module interface
	output reg signal,
	output reg [3:0] led
 );
 

parameter N = 5'd25;						// 50 devider
parameter P = 20'd1000000;					// 50Hz = 50MHz / 1000000
parameter K = 20'd1000000;
parameter KEY_en = 1'b1;


reg [19:0] cnt1;							// Counter for ICG
reg [4:0] cnt2;								// Counter for M
reg [19:0] cnt3;							// Counter for SH
reg [19:0] counter;                 // counter for key_scan
reg key_scan;

always @(posedge clk or negedge rst_n)
begin
   if(~rst_n)
		begin
			counter <= 20'd0;
			key_scan <= 1'b1;
		end
	else if(counter == K - 1)
		begin
			counter <= 20'd0;
			key_scan <= key_in;
		end
	else
		begin
			counter <= counter + 20'd1;
			key_scan <= key_scan;
	end 
end

reg key_scan_r;

always @ (posedge clk or negedge rst_n)
begin
   if(~rst_n)
	begin
	   key_scan_r <= 1'b1;
	end
	else
	begin
	   key_scan_r <= key_scan;
	end
end

wire flag_key = key_scan_r & (~key_scan);



// Counter for ICG
always @(posedge clk or negedge rst_n) 
begin
	 if(!rst_n)
		cnt1 <= 20'd0;
		
	 else if(cnt1 == P - 1)			
		cnt1 <= 20'd0;
		
	 else						  
		cnt1 <= cnt1 + 20'd1;
end

// counter for M
always @(posedge clk or negedge rst_n) begin

	if(!rst_n)
	begin
		cnt2 <= 5'd0;
		M <= 1'b0;
	end
	
	else if(cnt2 == N - 1)	
	begin
		cnt2 <= 5'd0;
		M <= ~M;
	end
	
	else
	begin
		cnt2 <= cnt2 + 5'd1; 
		M <= M;
	end
end


reg [2:0] key_cnt;

reg [19:0] L;
// Counter for SH	
always @(posedge clk or negedge rst_n) 
begin
   if (!rst_n)
	begin
		key_cnt <= 0;
		L <= 20'd25000;
	end
	else
	begin
	   if(flag_key == KEY_en)
		begin
		   if(key_cnt == 3'd4)
			begin
			    key_cnt <= 3'd0;
		   end
			else  
			   key_cnt <= key_cnt + 3'd1;
	   end
	   case (key_cnt)
	   3'd0 : begin
		          L <= 20'd25000; led <= 4'b1111;
				 end
		3'd1 : begin
		          L <= 20'd50000; led <= 4'b0111;
				 end
		3'd2 : begin
		          L <= 20'd250000; led <= 4'b1011;
				 end
		3'd3 : begin 
		          L <= 20'd500000; led <= 4'b1101;
				 end
		3'd4 : begin
		          L <= 20'd1000000; led <= 4'b1110;
				 end
		default : begin
		            L <= 20'd25000; led <= 4'b1111;
					 end
		      
	   endcase	
	end
end

wire [19:0] L_r = L;
	
always @(posedge clk or negedge rst_n) begin

	if(!rst_n)
		cnt3 <= 20'd0;
	   
		
	else if(cnt3 == L_r - 1)
		cnt3 <= 20'd0;
		
	else
		cnt3 <= cnt3 + 20'd1;
end

// Generate SH
always @(posedge clk or negedge rst_n) begin

	if(!rst_n)
		SH <= 1'b0;
		
	else
		case (cnt3)
			20'd30:							// t2 typ 500ns, which count 25(6:30) at 50M
				SH <= 1'b1;
			20'd130:						// t3 >= 1us, here t3 = 2us, which count 100(31:130) at 50M
				SH <= 1'b0;
			default:
				SH <= SH;
		endcase
end
		
// Generate ICG
always @(posedge clk or negedge rst_n) begin

	if(!rst_n)
		ICG <= 1'b1;
		
	else
		case (cnt1)
			20'd5: 
				ICG <= 1'b0;
			20'd380:						// t1 typ 7.5us, which count 250(131:380) at 50M
				ICG <= 1'b1;
			default:
				ICG <= ICG;
		endcase
end
		


// Signal
always @(posedge clk or negedge rst_n) begin
	
	if(!rst_n)
		signal <= 0;
	// (32 * 4) * 50 + 375 + 5 = 6780, 375 is posedge ICG
	// ((32 + 3648) * 4) * 50 + 375 + 5 = 736380
	// start at 50 clks after
	
	else 
		case(cnt1)
			// 20'd71850:						// 70 clk offset, 325 pixel offset -> (32+325)*4*50+375+75, 375 is posedge ICG
				// signal <= 1'b1;
			// 20'd446850:						// total 1875 pixel, 71850 + 1875*4*50
				// signal <= 1'b0;
			20'd6850:							// 70 clk offset
				signal <= 1'b1;
			20'd736450: 						// 729600 clks(6826:736425)
				signal <= 1'b0;
			default:
				signal <= signal;
		endcase
end
		
endmodule