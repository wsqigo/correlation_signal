//参数包 数据解析并作出相应指令
module para_analysis
(
input clk_25m,
input rst_n,
input para_confi_acq_flag,
input data_upload_acq_flag,
input [127:0]data_buffer,
output reg para_cofi_flag, //参数发送到其他模块的标志信号 脉冲式信号
output reg[7:0]channel1,            //通道选择 
output reg[15:0]noise_threshold,    
output reg[15:0]cycle_value,				//周期值
output reg contin_mode_open //非脉冲式信号 1打开 0 关闭
);


always@(posedge clk_25m or negedge rst_n)
begin
  if(!rst_n)
    begin
	   channel1<=8'h0;
		cycle_value<=16'h0;
		para_cofi_flag<=1'b0;
		noise_threshold<=16'h0;
	 end
  else if(para_confi_acq_flag)
    begin
	   para_cofi_flag<=1'b1;
	   channel1<=data_buffer[111:104];
		noise_threshold<=data_buffer[79:64];
		cycle_value<=data_buffer[15:0];
	 end
  else if(data_upload_acq_flag)  
    begin
		if(data_buffer[111:104]==8'h01)
			begin
				contin_mode_open<=1'b1;
			end
		else if(data_buffer[111:104]==8'h00)
			begin
				contin_mode_open<=1'b0;
			end
	 end

end

endmodule

