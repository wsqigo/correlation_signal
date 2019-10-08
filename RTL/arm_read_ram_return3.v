//fpga接收到参数配置包、模式选择包、数据上传打开关闭包后,模块为返回包
//首先将相应返回包数据写到read_ram中，然后fpga_to_arm置1，表示单片机可以读数据
//在单片机读完最后一个地址数据后，fpga_to_arm置0
module arm_read_ram_return3
(
input clk_25m,
input rst_n,
input RDn,
input CSn,
input para_confi_acq_flag,
input data_upload_acq_flag,
input [127:0]data_buffer,//write_ram中的缓存数据包
input [25:0]read_addr,
output [15:0]data,
output reg fpga_to_arm
);


//判断csn上升沿
reg cs_reg1;
reg cs_reg2;
reg cs_raise;	
always@(posedge clk_25m )
begin
	cs_reg1<=CSn;
	cs_reg2<=cs_reg1;
	cs_raise<=(!cs_reg2)&cs_reg1;
end

reg [3:0]state;
reg [4:0]write_addr;
reg [15:0]write_data;
reg [31:0]buffer32;//写到read_ram的临时缓存
reg [2:0]count;
reg write_en;
parameter idle=4'd0,addr0=4'd1,addr1=4'd2,read_ram=4'd3;

//读到para_confi_acq_flag信号后，写入ram数据，并发出fpga_to_arm信号给单片机读取地址
always@(posedge clk_25m or negedge rst_n)
begin
	if(!rst_n)
		begin
			state<=idle;
			write_addr<=5'd0;
			write_data<=16'h0;
			write_en<=1'b0;
			fpga_to_arm<=1'b0;
			buffer32<=32'h0;
			count<=3'd0;
		end
	else
		case(state)
			idle: begin
						write_en<=1'b0;
			         count<=3'd0;
						if(para_confi_acq_flag)
					     begin
						    state<=addr0;      //赋值是否一个周期完成 待测试
							 buffer32[31:16]<=16'h2222; 
							 buffer32[15:0]<=16'h5555; 
						  end
						if(data_upload_acq_flag)
						  begin
						    state<=addr0;
							 buffer32[31:16]<=16'h8888;
							 buffer32[15:0]<=data_buffer[111:96];
						  end
					end
	addr0: begin
						write_addr<=5'd0;
						write_data<=buffer32[31:16];
						write_en<=1'b1;
						state<=addr1;
					 end
	addr1: begin
						write_addr<=5'd1;
						write_data<=buffer32[15:0];
						write_en<=1'b1;
						state<=read_ram;
					 end
	   read_ram: begin
						write_en<=1'b0;
						fpga_to_arm<=1'b1;
						if(cs_raise==1'b1)
							begin
							  if(count==3'd3) //cs_raise第四个上升沿时，fpga_to_arm置0 待测试
							    begin
								   fpga_to_arm<=1'b0;
								   state<=idle;
									count<=3'd0;
								 end
							  else
							    begin
							      count<=count+1'b1;
									state<=read_ram;
								 end
							end
						else
							state<=read_ram;
					 end
		 default state<=idle;
		 endcase
						 						
end

wire rd = (CSn | RDn);
read_ram U1
(
.data(write_data),
.rdaddress(read_addr[4:0]),
.rdclock(!rd),
.rden(!rd),
.wraddress(write_addr),
.wrclock(clk_25m),
.wren(write_en),
.q(data)
);

endmodule
