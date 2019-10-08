//单片机通过fsmc发送数据到write_ram中
//发送完成，fpga读取write_ram中的数据并通过识别标志判断到来的包

module arm_write_ram
(
input clk_50m,
input rst_n,
input WRn,
input CSn,
input [15:0]data,
input [25:0]addr,

input clk_25m,//write_ram读时钟
input arm_to_fpga,

output reg para_confi_acq_flag, //参数配置 应答标志 脉冲式信号
output reg data_upload_acq_flag, //数据上传打开关闭 应答标志 脉冲式信号
output reg [127:0]data_buffer/*synthesis noprune*/
);

wire wr = (CSn | WRn);
reg wr_clk;
always @(posedge clk_50m or negedge rst_n)
begin
	if(!rst_n)
		wr_clk<=1'b1;
	else
		wr_clk<=wr;
end

wire [15:0]q;
reg [4:0]rdaddr;

write_ram U1
(
.data(data),
.rdaddress(rdaddr),
.rdclock(clk_25m),
.wraddress(addr[4:0]),
.wrclock(!wr_clk),
.wren(!wr),
.q(q)
);

/******判断arm_to_fpga下降沿，读出write_ram数据，判断帧头做出相应应答********/
reg arm_to_fpga_reg;
reg arm_to_fpga_fall;	
always@(posedge clk_25m )
begin
	arm_to_fpga_reg<=arm_to_fpga;
	arm_to_fpga_fall<=arm_to_fpga_reg&(!arm_to_fpga);
end

reg [3:0]state;
reg [2:0]delay;




parameter idle=4'd0,read0=4'd1,read1=4'd2,read2=4'd3,read3=4'd4,
          read4=4'd5,read5=4'd6,read6=4'd7,read7=4'd8,reco=4'd9;

always@(posedge clk_25m or negedge rst_n)
begin
	if(!rst_n)
		begin
			state<=idle;
			delay<=3'd0;
			para_confi_acq_flag<=1'b0;
			data_upload_acq_flag<=1'b0;
		end
	else
		case(state)
		idle: begin
		         para_confi_acq_flag<=1'b0;
					data_upload_acq_flag<=1'b0;
				   if(arm_to_fpga_fall)
						state<=read0;										
					else
						state<=idle;
				end
	  read0: begin
					rdaddr<=5'd0;
					if(delay==3'd4)
						begin
							state<=read1;
							delay<=3'd0;
							data_buffer[127:112]<=q;	            				
						end
					else
						delay<=delay+1'b1;
				end
	  read1: begin
					rdaddr<=5'd1;
					if(delay==3'd4)
						begin
							state<=read2;
							delay<=3'd0;
							data_buffer[111:96]<=q;
						end
					else
						delay<=delay+1'b1;
				end						
		read2: begin
					rdaddr<=5'd2;
					if(delay==3'd4)
						begin
							state<=read3;
							delay<=3'd0;
							data_buffer[95:80]<=q;
						end
					else
					   delay<=delay+1'b1;
			  	 end
		read3: begin
					rdaddr<=5'd3;
					if(delay==3'd4)
						begin
							state<=read4;
							delay<=3'd0;
							data_buffer[79:64]<=q;
						end
					else
					   delay<=delay+1'b1;
			 	 end
		read4: begin
					rdaddr<=5'd4;
					if(delay==3'd4)
						begin
							state<=read5;
							delay<=3'd0;
							data_buffer[63:48]<=q;
						end
					else
			   	   delay<=delay+1'b1;
				 end
		read5: begin
					rdaddr<=5'd5;
					if(delay==3'd4)
						begin
							state<=read6;
							delay<=3'd0;
							data_buffer[47:32]<=q;
						end
					else
					   delay<=delay+1'b1;
				 end
		read6: begin
					rdaddr<=5'd6;
					if(delay==3'd4)
						begin
							state<=read7;
							delay<=3'd0;
							data_buffer[31:16]<=q;
						end
					else
					   delay<=delay+1'b1;
				 end
		read7: begin
					rdaddr<=5'd7;
					if(delay==3'd4)
						begin
							state<=reco;
							delay<=3'd0;
							data_buffer[15:0]<=q;
						end
					else
					   delay<=delay+1'b1;
				 end
		 reco: begin
					if(data_buffer[127:112]==16'h1111)//参数配置 
						begin
							para_confi_acq_flag<=1'b1;
							state<=idle;
						end
					else if(data_buffer[127:112]==16'h7777)//数据上传打开关闭
						begin
							data_upload_acq_flag<=1'b1;
							state<=idle;
						end
					else
						begin
							para_confi_acq_flag<=1'b0;
			            data_upload_acq_flag<=1'b0;
							state<=idle;
						end							
				 end
			default state<=idle;
			endcase
end	

endmodule