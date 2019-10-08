///模块说明//////////////
//读FIFO模块
//功能： 1、将每个FIFO中一帧完整的数据读出来，送到communication FPGA，一个通道2个FIFO，分别用来读写
//		  2、将满信号作为标志，用来通知communication FPGA读取数据
//		  3、为了使信号同步，读FIFO模块的时钟由communication FPGA来给，同时读使能信号也由communication FPGA给
//////////////////////////

module read_fifo(clk_in,
						rst_n,
						data_from_fifo_1,
						data_from_fifo_2,
						data_out,
						rdfull_1,
						rdfull_2,
						rdempty_1,
						rdempty_2,
						rdreq_1,
						rdreq_2,
						rdfull,
						rdreq
						);
						
input clk_in;					//模块时钟信号，由communication FPGA提供
input rst_n;					//系统复位信号
input[15:0]data_from_fifo_1;	//来自FIFO的数据
input[15:0]data_from_fifo_2;	//来自FIFO的数据
input rdfull_1;				//FIFO_1的满标志
input rdfull_2;				//FIFO_2的满标志
input rdempty_1;				//FIFO_1的读空标志
input rdempty_2;				//FIFO_2的读空标志
input rdreq;					//从communication FPGA来的读请求

output reg rdreq_1;			//输出给FIFO_1的读请求
output reg rdreq_2;			//输出给FIFO_2的读请求
output reg[15:0]data_out;	//输出给communication FPGA的峰值数据
output reg rdfull;			//输出给communication FPGA的FIFO满标志

initial
begin
rdfull<=1'b0;
end

reg [1:0]state;						//状态控制
parameter IDLE=2'd0;			//空闲状态
parameter READ=2'd1;			//读状态
parameter delay=2'd2;			//等待
reg i;
reg rd_fifo_1_time;			//读FIFO_1的时间
reg rd_fifo_2_time;			//读FIFO_2的时间

always@(posedge clk_in or negedge rst_n)
begin
	if(!rst_n)
	  rd_fifo_1_time<=1'b0;
	else if(rdfull_1==1'b1)
	  rd_fifo_1_time<=1'b1;
	else if(rdempty_1==1'b1)
	  rd_fifo_1_time<=1'b0;
	 else
		rd_fifo_1_time<=rd_fifo_1_time;
end

always@(posedge clk_in or negedge rst_n)
begin
	if(!rst_n)
	  rd_fifo_2_time<=1'b0;
	else if(rdfull_2==1'b1)
	  rd_fifo_2_time<=1'b1;
	else if(rdempty_2==1'b1)
	  rd_fifo_2_time<=1'b0;
	 else
		rd_fifo_2_time<=rd_fifo_2_time;
end

always@(posedge clk_in or negedge rst_n)
begin
	if(!rst_n)
	  begin
		  data_out<=16'd0;//改成高阻态
		  rdfull<=1'b0;
		  rdreq_1<=1'b0;
		  rdreq_2<=1'b0;
	  end
	else
	 begin
	   case(state)
		 IDLE:begin
					if((rdfull_1==1'b1) || (rdfull_2==1'b1))//如果两个FIFO至少有一个满了,则开始读状态
					 begin
					 i<=1'b0;
					 state<=READ;
					 rdfull<=1'b1;
					 end
				end
		 READ:begin
					if((rdempty_1==1'b1)&&(rdempty_2==1'b1))//如果两个FIFO都空了，则跳至空闲状态
					  begin
							state<=IDLE;
							rdreq_1<=1'b0;
							rdreq_2<=1'b0;
							rdfull<=1'b0;
							data_out<=16'd0;//高阻态
					  end
					else if((rd_fifo_1_time==1'b0)&&(rd_fifo_2_time==1'b1))//如果FIFO_1空了，FIFO_2没空，则读FIFO_2
						begin
							if(rdempty_2==0)
								rdreq_2<=rdreq;
							else
								rdreq_2<=1'b0;
								
							rdreq_1<=1'b0;
							rdfull<=1'b1;
							if((rdreq_2==1) && (rdempty_2==0))
								data_out<=data_from_fifo_2;
							else
								data_out<=16'd0;
						end
						
					else if((rd_fifo_1_time==1'b1)&&(rd_fifo_2_time==1'b0))//如果FIFO_1在读，FIFO_2在写，则读FIFO_1
						begin
						   
							if(rdempty_1==0)
								rdreq_1<=rdreq;
							else
								rdreq_1<=1'b0;
							rdreq_2<=1'b0;
							rdfull<=1'b1;
							if((rdreq_1==1) && (rdempty_1==0))
								data_out<=data_from_fifo_1;
							else
								data_out<=16'd0;
						end
					else if((rd_fifo_1_time==1'b1)&&(rd_fifo_2_time==1'b1))
					   begin
						   if(rdempty_1==0)							
							    rdreq_1<=rdreq;
							else
					         state<=delay;		
							rdfull<=1'b1;
							if((rdreq_1==1) && (rdempty_1==0))
							   data_out<=data_from_fifo_1;
							else
								begin
								data_out<=16'd0;
								
						      end		
						 end    	
					 else														//如果两个FIFO都非空
						begin
							rdreq_1<=1'b0;
							rdreq_2<=1'b0;
							rdfull<=1'b0;
							data_out<=16'd0;
						end
				 end
		 delay: begin
		          case(i)
					  1'b0:begin rdfull<=1'b0; i<=i+1'b1; end
				     1'b1:begin rdfull<=1'b0; state<=IDLE; end
					 endcase
				  end	 
					 
		default:state<=IDLE;
	  endcase
	 end
end
endmodule
