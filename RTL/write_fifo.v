///模块说明//////////////
//写FIFO模块
//功能： 1、存储峰值采集模块传输过来的峰值数据，存储容量刚好为20ms的数据，即一帧，数据位宽为16bit
//		  2、例化2个FIFO，用来乒乓操作
//////////////////////////

module write_fifo(clk,
						rst_n,
						wrreq_1,
						wrreq_2,
						data_from_signal_peak,
						data_out,
						wrfull_1,
						wrfull_2,
						wrempty_1,
						wrempty_2,
						data_valid_flag
						
);

input clk;								//	系统时钟50MHz
input rst_n;							//系统复位信号
input wrempty_1;						//FIFO_1空标志
input wrempty_2;						//FIFO_2空标志
input wrfull_1;						//FIFO_1满标志
input wrfull_2;						//fifo_2满标志
input data_valid_flag;				//输入数据有效标志，保证不将0存储起来

input[15:0]data_from_signal_peak;//从峰值采集模块过来的峰值数据

output reg[15:0]data_out;			//FIFO数据总线
output reg wrreq_1;					//FIFO_1写请求，active_high
output reg wrreq_2;					//FIFO_2写请求，active_high

reg state;								//状态控制
parameter IDLE=1'b0;					//空闲状态
parameter WRITE=1'b1;				//写状态

reg rd_fifo_1_flag;					//保证在FIFO_1读空之前不再往里面写数据
reg rd_fifo_2_flag;					//保证在FIFO_2读空之前不再往里面写数据

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		rd_fifo_1_flag<=1'b0;
	else if(wrfull_1==1'b1)
		rd_fifo_1_flag<=1'b1;
	else if(wrempty_1==1'b1)
		rd_fifo_1_flag<=1'b0;
	else
		rd_fifo_1_flag<=rd_fifo_1_flag;
end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		rd_fifo_2_flag<=1'b0;
	else if(wrfull_2==1'b1)
		rd_fifo_2_flag<=1'b1;
	else if(wrempty_2==1'b1)
		rd_fifo_2_flag<=1'b0;
	else
		rd_fifo_2_flag<=rd_fifo_2_flag;
end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		 begin
		   data_out<=16'd0;
			wrreq_1<=1'b0;
			wrreq_2<=1'b0;
			state<=IDLE;
		 end
   else 
	begin
	case(state)
	IDLE:begin
			if((wrempty_1==1'b1) || (wrempty_2==1'b1))//如果两个FIFO至少有一个为空
				begin
					state<=WRITE;
				end
			end
	 WRITE:begin
	 
				if((rd_fifo_1_flag==1'b1) &&(rd_fifo_2_flag==1'b1))//如果两个FIFO都满了
					begin
						wrreq_1<=1'b0;
						wrreq_2<=1'b0;
						state<=IDLE;
					end
				
				else if((rd_fifo_1_flag==1'b1)&& (rd_fifo_2_flag==1'b0))//如果FIFO_1在读，FIFO_2在写
					begin
						if(data_valid_flag==1)
							begin
								wrreq_1<=1'b0;
								wrreq_2<=1'b1;
							end
						else
						  begin
						  	wrreq_1<=1'b0;
							wrreq_2<=1'b0;
						  end
						data_out<=data_from_signal_peak;
					end
				else if((rd_fifo_1_flag==1'b0)&&(rd_fifo_2_flag==1'b1))//如果FIFO_2在读，FIFO_1在写
					begin
						if(data_valid_flag==1)
							begin
								wrreq_1<=1'b1;
								wrreq_2<=1'b0;
							end
						else
						  begin
						  	wrreq_1<=1'b0;
							wrreq_2<=1'b0;
						  end
						data_out<=data_from_signal_peak;
					end
				else													//
					begin
					 if((wrempty_1==1'b1)&&(wrempty_2==1'b1))//两个FIFO都是空的，先写FIFO_1
						begin
						 if(data_valid_flag==1)
							begin
								wrreq_1<=1'b1;
								wrreq_2<=1'b0;
							end
						 else
							begin
								wrreq_1<=1'b0;
								wrreq_2<=1'b0;
							end
								data_out<=data_from_signal_peak;
						end
				else if((wrempty_1==1'b0)&&(wrempty_2==1'b1))//如果FIFO_1非空，FIFO_2为空
					begin
						if(data_valid_flag==1)
							begin
								wrreq_1<=1'b1;
								wrreq_2<=1'b0;
							end
						else
							begin
							  wrreq_1<=1'b0;
							  wrreq_2<=1'b0;
							end
						data_out<=data_from_signal_peak;
					end
				else if((wrempty_1==1'b1)&&(wrempty_2==1'b0))
					begin
						if(data_valid_flag==1)
							begin
								wrreq_1<=1'b0;
								wrreq_2<=1'b1;
							end
						else
							begin
							  wrreq_1<=1'b0;
							  wrreq_2<=1'b0;
							end
						data_out<=data_from_signal_peak;
					end
			   else
				  begin
				   if(data_valid_flag==1)
							begin
								wrreq_1<=wrreq_1;
								wrreq_2<=wrreq_2;
							end
						else
							begin
							  wrreq_1<=1'b0;
							  wrreq_2<=1'b0;
							end
						data_out<=data_from_signal_peak;
				  end
				end
		end
			
					
		default:state<=IDLE;
		endcase
	end
end

endmodule


