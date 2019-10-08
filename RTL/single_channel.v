///模块说明//////////////
//单通道整体实现模块
//功能：1、将所有模块例化到该文件，实现一个通道AD峰值数据采集

//////////////////////////

module single_channel( clk_in, //50m
							  clk_from_com_FPGA, //25m
							  clk_to_AD, 
							  rst_n,
							  data_from_AD,
							  data_to_com_FPGA,
							  rdreq,
							  fifo_full,
							  cycle_value_flag,//input 1/128周期计数标志 ，脉冲式信号
							  normal_signal
							  );
							  
input clk_in;							//系统模块工作时钟
input rst_n;						//系统复位信号
input clk_from_com_FPGA;		//来自communication FPGA的时钟，用到读FIFO模块
input[11:0]data_from_AD;		//从AD过来的数据
input rdreq;						//从communication FPGA输入的读使能
input normal_signal;
input cycle_value_flag;//input 1/128周期计数标志 ，脉冲式信号

output clk_to_AD;					//给AD的时钟
output fifo_full;					//FIFO满标志，输出到communication FPGA用来做通道轮询
output[15:0]data_to_com_FPGA;	//输出到FPGA的峰值数据



//wire clk;
wire[15:0]data_to_signal_peak;
wire[15:0]data_to_fifo_wr_rd;
wire data_valid_flag;


//pll u1(.inclk0(clk_in),
//		 .c0(clk));
wire wrreq_1, wrreq_2;
wire rdreq_1,rdreq_2;
wire wrfull_1,wrfull_2;
wire rdfull_1,rdfull_2;
wire wrempty_1,wrempty_2;
wire rdempty_1,rdempty_2;
wire[15:0] rd_data_1,rd_data_2;
wire[15:0]wr_data;



AD_ctrl u2(.clk(clk_in),
			  .rst_n(rst_n),
			  .clk_to_AD(clk_to_AD),
			  .data_from_AD(data_from_AD),
			  .data_out(data_to_signal_peak)
			  );
			  
			  
signal_peak u3(.clk(clk_in),
					.rst_n(rst_n),
					.normal_signal(normal_signal),
					.data_from_ad_ctrl(data_to_signal_peak),
					.cycle_value_flag(cycle_value_flag),       //1/128周期计数标志 ，脉冲式信号
					.data_out(data_to_fifo_wr_rd),
					.data_valid_flag(data_valid_flag),
					.total_count()
					);



write_fifo write_fifo( .clk(clk_in),
							  .rst_n(rst_n),
							  .wrreq_1(wrreq_1),
							  .wrreq_2(wrreq_2),
							   .data_from_signal_peak(data_to_fifo_wr_rd),
							  .data_out(wr_data),
							  .wrfull_1(wrfull_1),
							  .wrfull_2(wrfull_2),
							  .wrempty_1(wrempty_1),
							  .wrempty_2(wrempty_2),
							  .data_valid_flag(data_valid_flag)
							  );
				  
fifo_for_peak_data fifo_1(	 .wrclk(clk_in),
									 .rdclk(clk_from_com_FPGA),
									 .wrreq(wrreq_1),
									 .rdreq(rdreq_1),
									 .wrempty(wrempty_1),
									 .rdempty(rdempty_1),
									 .wrfull(wrfull_1),
									 .rdfull(rdfull_1),	
									 .data(wr_data),
									 .q(rd_data_1)
									 );
							 
fifo_for_peak_data fifo_2(  .wrclk(clk_in),
									 .rdclk(clk_from_com_FPGA),
									 .wrreq(wrreq_2),
									 .rdreq(rdreq_2),
									 .wrempty(wrempty_2),
									 .rdempty(rdempty_2),
									 .wrfull(wrfull_2),
									 .rdfull(rdfull_2),	
									 .data(wr_data),
									 .q(rd_data_2)
									 );
									 
read_fifo read_fifo(  .clk_in(clk_from_com_FPGA),
							 .rst_n(rst_n),
							 .data_from_fifo_1(rd_data_1),
							 .data_from_fifo_2(rd_data_2),
							 .data_out(data_to_com_FPGA),
							 .rdfull_1(rdfull_1),
							 .rdfull_2(rdfull_2),
							 .rdempty_1(rdempty_1),
							 .rdempty_2(rdempty_2),
							 .rdreq_1(rdreq_1),
							 .rdreq_2(rdreq_2),
							 .rdfull(fifo_full),
							 .rdreq(rdreq)
							 );
				  
endmodule