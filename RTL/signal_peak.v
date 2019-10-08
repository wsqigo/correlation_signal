///模块说明////////////// 2
//峰值采集模块
//以工频信号上升沿为基准 连续测量出128份  的最大值
//每一份计数值由单片机算好传过来
//单片机计算过程：(周期值*1000000/(128*10))去尾 确保是整数
//////////////////////////
/***************************************************
20ms 64份 每一份0.3125ms
系统时钟100m  10ns
0.3125ms/10ns=31250(个) 计数

系统时钟分别设置为：
50m                         15625
60m   312500/1000=312.5 *60=18750
70m                     *70=21870
80m                     *80=25000
90m                     *90=28125
100m                        31250
****************************************************/

module signal_peak
(
input clk,//系统时钟信号100MHz（10ns）
input	rst_n,
input	normal_signal,          //来自communication FPGA的工频信号
input	[15:0]data_from_ad_ctrl,//来自AD_ctrl模块的数据
output reg[15:0]data_out,     //峰值数据信号
output reg data_valid_flag,   //有效数据标志
input cycle_value_flag,//input 1/128周期计数标志 ，脉冲式信号
output reg [29:0]total_count  //test工频周期长度
);
									

reg normal_signal_reg;		//工频信号寄存器

wire pos_edge;					//工频信号上升沿  
wire neg_edge;					//工频信号下降沿


////////////工频信号边沿检测////////////////////////

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	  normal_signal_reg<=1'b0;
	 else
	   normal_signal_reg<=normal_signal;
end


assign pos_edge=normal_signal &(~normal_signal_reg);
assign neg_edge=(~normal_signal)& normal_signal_reg;

reg [9:0]peak_count; //1块 计数
reg [15:0]count_3648;   //128份
reg [1:0]state;

//test工频周期长度
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	total_count<=30'd0;
	else 
	 begin
	  total_count<=total_count+1'b1;
	  if(pos_edge)
	  total_count<=30'd0;
	 end
end

parameter idle=2'd0,count_state=2'd1,last_state=2'd2;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	  begin
		peak_count<=10'd0;
		count_3648<=16'd0;
		data_out<=16'd0;
		data_valid_flag<=1'b0;
	  end
	else 
	 case(state)
	         idle :  begin
							data_valid_flag<=1'b0;
		               if(pos_edge)
							  begin
					         state<=count_state;
								peak_count<=10'd0;								
							  end
					      else 
					         state<=idle;
				        end
      count_state:  begin
		               if(count_3648==16'd3647)
							 begin
							   state<=2'd2;
							   count_3648<=16'd0;
								peak_count<=10'd0;
								data_valid_flag<=1'b0;
							 end
							else if(count_3648 < 16'd3647)
							 begin
		                 if(peak_count==10'd150)//n
							     begin
							       data_out<=data_from_ad_ctrl;
		                      data_valid_flag<=1'b1;
									 count_3648<=count_3648+1'b1;	
									 peak_count<=peak_count+1'b1;
							     end
							  else if(peak_count == 20'd199)
									 begin
										peak_count <= 10'b0;
										data_valid_flag<=1'b0;
									 end
							  else 
							       begin
							       peak_count<=peak_count+1'b0;
									 data_valid_flag<=1'b0;
							 end
							end
		last_state:    begin  //最后一块 留出余量（工频信号会有抖动）保证有数据传上来
                        if(peak_count==10'd75)  
								  begin
								   data_out<=data_from_ad_ctrl;
		                     data_valid_flag<=1'b1;
									count_3648 <= count_3648 + 1'b1;
									peak_count<=peak_count+1'b1;
								  end
								else if(peak_count==10'd100)  
								  begin
						  		   state<=idle;
									data_valid_flag<=1'b0;
									peak_count <= 1'b0;
								  end
								else 
								  begin
								    data_valid_flag<=1'b0;
							       peak_count<=peak_count+1'b1;
							     end
							end
						end
			default: state<=idle;
			endcase
end					
							   
							   

endmodule
