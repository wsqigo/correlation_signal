module arm_read_pingpang_ram
(
input clk_25m,
input clk_50m,
input rst_n,
input data_in_flag,//数据标志
input [15:0]data_in,//数据
input RDn,
input CSn,
input [25:0]read_addr,
output [15:0]data,
output reg fpga_to_arm
);


reg [8:0] count;
reg [8:0] write_ram1_addr;
reg [8:0] write_ram2_addr;
reg read_ram1_acq;
reg read_ram2_acq;
reg [15:0] write_ram1_data;
reg [15:0] write_ram2_data;
reg write_ram1_en;
reg write_ram2_en;
wire [15:0]q1;
wire [15:0]q2;

wire [8:0]read_addr1;
wire [8:0]read_addr2;
wire rd1;
wire rd2;

reg select;
reg [9:0]cs_count;

reg[2:0]state1;
parameter write_ram12_addr0=3'd0,prepare=3'd1,write1=3'd2,write2=3'd3;
always@(posedge clk_25m or negedge rst_n)
begin
   if(!rst_n)
	  begin
	    state1<=write_ram12_addr0;
		 count<=0;
		 read_ram1_acq<=0;
		 read_ram2_acq<=0;
		 write_ram1_addr<=0;
		 write_ram2_addr<=0;
		 write_ram1_data<=16'h0;
		 write_ram2_data<=16'h0;
		 write_ram1_en<=0;
		 write_ram2_en<=0;
	 end 
	else
	 case(state1)
  write_ram12_addr0: begin
                       write_ram1_en<=1;
	                    write_ram1_data<=16'h9999;
							  write_ram1_addr<=0;
							  write_ram2_en<=1;
	                    write_ram2_data<=16'h9999;
							  write_ram2_addr<=0;
							  state1<=prepare;
							end
	         prepare: begin
				           write_ram1_en<=0;
	                    write_ram1_data<=16'h0;
							  write_ram1_addr<=0;
							  write_ram2_en<=0;
	                    write_ram2_data<=16'h0;
							  write_ram2_addr<=0;
							  state1<=write1;
							end
	  write1: begin
	            if(count<9'd390)
					 begin
					  read_ram2_acq<=0;
				     if(data_in_flag)    //中间有没有延迟一个时钟 等待仿真验证
					   begin
					    write_ram1_en<=data_in_flag;
						 write_ram1_data<=data_in;
						 write_ram1_addr<=write_ram1_addr+1'b1;
						 count<=count+1'b1;
						end
					  else
						 begin
						 write_ram1_en<=0;
						 write_ram1_data<=data_in;
						 write_ram1_addr<=write_ram1_addr;
						 count<=count;
						 end
					 end	
					else if(count==9'd390)
			         begin
					    write_ram1_en<=0;
						 write_ram1_data<=data_in; 
						 count<=0;
						 state1<=write2;
						 read_ram1_acq<=1;
						 write_ram1_addr<=0;
				      end				
	          end
	  write2: begin
	            if(count<9'd390)
					 begin
					  read_ram1_acq<=0;
				     if(data_in_flag)
					   begin
					    write_ram2_en<=data_in_flag;
						 write_ram2_data<=data_in;
						 write_ram2_addr<=write_ram2_addr+1'b1;
						 count<=count+1'b1;
						end
					  else
						 begin
						 write_ram2_en<=0;
						 write_ram2_data<=data_in;
						 write_ram2_addr<=write_ram2_addr;
						 count<=count;
						 end	
					 end	
					else if(count==9'd390)
			         begin 
						 write_ram2_en<=0;
						 write_ram2_data<=data_in; 
						 count<=0;
						 state1<=write1;
						 read_ram2_acq<=1;
						 write_ram2_addr<=0;
				      end				
	          end
	 default:state1<=write_ram12_addr0;
	 endcase			 
end

wire rd = (CSn | RDn);
//ram1 
ram1  ram1
(
.data(write_ram1_data),
.rdaddress(read_addr1),                 
.rdclock(!rd1),
.rden(!rd1),
.wraddress(write_ram1_addr),  
.wrclock(clk_25m),
.wren(write_ram1_en),
.q(q1)
);

//ram2
ram2  ram2
(
.data(write_ram2_data),
.rdaddress(read_addr2),
.rdclock(!rd2),
.rden(!rd2),
.wraddress(write_ram2_addr),  
.wrclock(clk_25m),
.wren(write_ram2_en),
.q(q2)
);

//判断csn上升沿  50m信号判断
reg cs_reg1;
reg cs_reg2;
reg cs_raise;	
always@(posedge clk_50m or negedge rst_n)
begin
   if(!rst_n)
		begin
			cs_reg1<=1'b0;
			cs_reg2<=1'b0;
			cs_raise<=1'b0;
		end
	else
		begin
			cs_reg1<=CSn;
			cs_reg2<=cs_reg1;
			cs_raise<=cs_reg2&(!cs_reg1);//下降沿
		end
end

/*******************data_spend_flag**************************/
reg data_spend_flag;
always@(posedge clk_25m or negedge rst_n)
begin
   if(!rst_n)
	data_spend_flag<=0; 
	else if(read_ram2_acq|read_ram1_acq)
	data_spend_flag<=1;
	else
	data_spend_flag<=0;
end	


assign read_addr1=select? read_addr[8:0]:9'h0;
assign read_addr2=select? 9'h0:read_addr[8:0];
assign rd1=select? rd:1'b0;
assign rd2=select? 1'b0:rd;
assign data=select?q1:q2;

reg [2:0]state2;
parameter idle=3'd0,read=3'd1,delay=3'd2;
reg addr_count;
reg [3:0]delay_time;
//更改成50m
always@(posedge clk_50m or negedge rst_n)
begin
   if(!rst_n)
	  begin
	    state2<=idle;
		 fpga_to_arm<=1'b0;
		 cs_count<=10'd0;
		 addr_count<=1'b0;
		 delay_time<=4'd0;
	  end
	else
	  case(state2)
	  idle:  begin
	           if(data_spend_flag)
				    begin
				    fpga_to_arm<=1'b1;				 
					 state2<=read;
					 end
				  else
				    begin
					 fpga_to_arm<=1'b0;
					 state2<=idle;
					 end
				end
	  read:  begin
	           if(cs_raise==1'b1)
						begin
							if(read_addr[8:0]==9'h186)
								begin
									if(addr_count==1'b1)
										begin								
											state2<=delay;
											cs_count<=10'd0;
											addr_count<=1'b0;
										end
									else
										addr_count<=addr_count+1;
								end
						  else if(cs_count==10'd782) //cs_raise的最后一个上升沿时，fpga_to_arm置0 待测试
							 begin               //391*2
								fpga_to_arm<=1'b0;
								state2<=idle;
								cs_count<=10'd0;
								addr_count<=1'b0;
							 end
						  else
							 begin
								cs_count<=cs_count+1'b1;
								state2<=read;
							 end
						end
					else
						state2<=read;
				end
     delay: begin //fpga_to_arm;延时12个周期
					if(delay_time==4'd12)
					  begin
					  fpga_to_arm<=1'b0;
					  state2<=idle;
					  delay_time<=4'd0;
					  end
					else
					  begin
					  delay_time<=delay_time+1'b1;
					  state2<=delay;
					  end
			   end
	default:state2<=idle;
	  endcase
end



always@(posedge clk_25m or negedge rst_n)
begin
   if(!rst_n)
	select<=0;   //默认情况下 选择ram2
   else if(read_ram1_acq)
	select<=1;
	else if(read_ram2_acq)
	select<=0;
end


endmodule

