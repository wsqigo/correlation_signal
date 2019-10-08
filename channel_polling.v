//通过控制各通道的开关将各通道数据轮询输出
module channel_polling
(
input clk_25m,
input rst_n,
input para_cofi_flag,
input [7:0]channel1,  //通道选择 
input [15:0]data_from_data_collection, //data_collection出来的数据
input fifo_full1,
output reg rdreq1,
output reg [15:0]data_out,
output reg data_flag,
output reg [3:0]channel_number
);

reg [6:0]count;
reg para_cofi_flag_reg;

initial
begin
  count<=7'd20;
end


//寄存channel1、channel2、channel3
reg [7:0]channel1_reg;

reg [7:0]channel1_rr;

always@(posedge clk_25m or negedge rst_n)
begin
  if(!rst_n)
    begin
	   channel1_reg<=8'h0;
	 end
  else if((para_cofi_flag_reg)&&(count==7'd20))//保证在数据间隙将通道号赋值上去 避免数据混乱
    begin
	   channel1_reg<=channel1_rr;
	 end
end


always@(posedge clk_25m or negedge rst_n)  //寄存来到的para_cofi_flag信号,
begin
if(!rst_n)
  begin
  para_cofi_flag_reg<=1'b0;
  channel1_rr<=8'h0;
  end
else if(para_cofi_flag)
  begin
  para_cofi_flag_reg<=1'b1;   //置1后永久不变，只是等待count=20时 将通道号寄存上去
  channel1_rr<=channel1;
  end
end


reg [1:0]state;
parameter read1=2'd0,read2=2'd1,read3=2'd2;
always@(posedge clk_25m or negedge rst_n)
begin
  if(!rst_n)
    begin
	   rdreq1<=1'b0;
		channel_number<=4'h0;
		data_flag<=0;
		data_out<=16'h0;
	 end
  else 
    case(state)
	 read1: begin
	          if(channel1_reg==8'h01)
				   begin
					  if(fifo_full1==1'b1)
					    begin
						 data_flag<=1'b1;
					    rdreq1<=1'b1;
						 count<=0;
						 channel_number<=4'd1;
						 data_out<=data_from_data_collection;
						 end
					  else
					    begin
						   data_flag<=1'b0;
					      data_out<=16'h0;
					      rdreq1<=1'b0;
							if(count<7'd100)   //wait 10us
					        count<=count+1'b1;
					      else 
			              begin state<=read2;  count<=7'd0; end 
						 end 
					end
				 else if(channel1_reg==8'h00)
				   begin
				     state<=read1;
					  data_flag<=1'b0;
					  data_out<=16'h0;
					  rdreq1<=1'b0;
					end
				end
		default: state<=read1;
		endcase						  
end


endmodule

