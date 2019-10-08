//连续模式 打开关闭
module contin_mode_openclose
(
input clk_25m,
input rst_n,
input [15:0]datain,
input fifo_full1_in,
output reg [15:0]dataout,
output reg fifo_full1_out
);

reg contin_mode_open_reg;
always@(posedge clk_25m or negedge rst_n)
begin
 if(!rst_n)
  begin
   contin_mode_open_reg<=0;
  end
 else if((datain==0)&&(fifo_full1_in==1))
  begin
   contin_mode_open_reg<=1;
  end
 else if((datain==0)&&(fifo_full1_in==0))
   contin_mode_open_reg<=0;
end

always@(posedge clk_25m or negedge rst_n)
begin
	if(!rst_n)
		begin
			fifo_full1_out<=0;
		end
	else if(contin_mode_open_reg==1'b1)
		begin
			fifo_full1_out<=fifo_full1_in;
			dataout<=datain;
		end
	else if(contin_mode_open_reg==1'b0)
		begin
			fifo_full1_out<=0;
			dataout<=0;
		end
end


endmodule
