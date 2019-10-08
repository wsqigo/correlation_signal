///模块说明//////////////
//通道汇总模块
//功能：1、将6个通道的数据汇总
//		 2、通过fifo_full标志判断哪个通道的fifo满了，从而使能communication_fpga。
//		 3、通过接收rdreq信号，将3个通道的数据读出
//////////////////////////

module channel_gather(clk_in,
							 rst_n,
							 data_from_ch_1,					 
						 
							 fifo_full1,						 
							 
							 rdreq_ch_1,
						 							 
							 fifo_full_ch_1,

							 rdreq_1,

							 data_out							 							 
							 );
							 
input clk_in;					//模块时钟信号
input rst_n;					//模块复位信号
input[15:0]data_from_ch_1;	//来自通道1的数据

input fifo_full1;


input rdreq_ch_1;				//通道1读请求


output reg fifo_full_ch_1;	//通道1 fifo满标志


output reg rdreq_1;


output reg[15:0]data_out;	//数据输出


reg[7:0]data_cnt1;//一帧数据个数计数，用来拉低读使能信号

reg[1:0]data_dly_cnt1;

////////////////////////////通道1
always@(posedge clk_in or negedge rst_n)
begin
	if(!rst_n)
		data_dly_cnt1<=2'd0;
	else if(rdreq_1==1'b1)
		begin
			if(data_dly_cnt1>=2'd2)
				data_dly_cnt1<=data_dly_cnt1;
			else
				data_dly_cnt1<=data_dly_cnt1+1'b1;
		end
	else 
	  data_dly_cnt1<=2'd0;
end

//////////////////////////////////////////////////////////////////////
////////////////////////通道1
always@(posedge clk_in or negedge rst_n)
begin
	if(!rst_n)
		data_cnt1<=2'd0;
	else if(rdreq_ch_1==1'b1)
		begin
			if(data_dly_cnt1>=2'd2)
				 data_cnt1<=data_cnt1+1'b1;
			else
				 data_cnt1<=data_cnt1;
		end
	 else
		data_cnt1<=8'd0;
end

//////////////////////////////////////////////////////////////////////

always@(posedge clk_in or negedge rst_n)
begin
	if(!rst_n)
		begin
			
			rdreq_1<=1'b0;

		end
	else if(rdreq_ch_1==1'b1)
		begin
		  if(data_cnt1<=8'd127)
			rdreq_1<=1'b1;
			else
			rdreq_1<=1'b0;
		end
	else
		begin	
			rdreq_1<=1'b0;
		end
end
//////////////////////////////////////////////////////////////////////
always@(posedge clk_in or negedge rst_n)
begin
	if(!rst_n)
		begin
			 fifo_full_ch_1<=1'b0;
		 end
	 else
		 begin
			 fifo_full_ch_1<=fifo_full1;
		 end
end

//////////////////////////////////////////////////////////////////////
always@(posedge clk_in or negedge rst_n)
begin
	if(!rst_n)
		begin
			data_out<=16'd0;
			
		end
	else if(rdreq_1==1'b1)
		begin
			if(data_dly_cnt1>=2'd2&&data_cnt1<=8'd127)
				begin					
					data_out<=data_from_ch_1;
				end
			else
				begin
					data_out<=16'd0;					
				end
		//data_out<=data_from_ch_1;		
		end
	else
		begin
			data_out<=16'd0;			
		end
end


endmodule
