///模块说明//////////////
//顶层文件
//功能：1、将所有模块例化到该文件，实现6个通道AD峰值数据采集
//		
//////////////////////////
module data_collection(
                       clk,   //input50m                      
							  rst_n, //input
							  clk_from_com_FPGA, //input				  						  						  
							  data_from_AD1,//input
							  clk_to_all_AD,//output	
							  data_to_com_FPGA,//output
							  rdreq_ch_1,//input
							  fifo_full_ch_1//output							  
							);
							
input clk;
input rst_n;
input[11:0]data_from_AD1;

input rdreq_ch_1;

input normal_signal;
input clk_from_com_FPGA;

input cycle_value_flag;
input[15:0]cycle_value;

output fifo_full_ch_1;

output[15:0]data_to_com_FPGA;
output clk_to_all_AD;
wire rdreq_1;

wire fifo_full_1;

wire[15:0]data_from_ch_1;


		 
single_channel signal_ch1( .clk_in(clk),
									.clk_from_com_FPGA(clk_from_com_FPGA),
									.clk_to_AD(clk_to_all_AD),//output
									.rst_n(rst_n),
									.data_from_AD(data_from_AD1),
									.data_to_com_FPGA(data_from_ch_1),
									.rdreq(rdreq_1),
									.fifo_full(fifo_full_1),
									.normal_signal(normal_signal),
									.cycle_value_flag(cycle_value_flag),//1/128周期计数标志 ，脉冲式信号
                           .cycle_value(cycle_value)           //1/128周期计数
									);
							
													
	
channel_gather channel_gather( .clk_in(clk_from_com_FPGA),
										 .rst_n(rst_n),
										 .data_from_ch_1(data_from_ch_1),
										 .data_from_ch_2(data_from_ch_2),
										 .data_from_ch_3(data_from_ch_3),
										 .fifo_full1(fifo_full_1),
										 .fifo_full2(fifo_full_2),
										 .fifo_full3(fifo_full_3),
										 .rdreq_1(rdreq_1),
										 .rdreq_2(rdreq_2),
										 .rdreq_3(rdreq_3),									 
										 .rdreq_ch_1(rdreq_ch_1),
										 .rdreq_ch_2(rdreq_ch_2),
										 .rdreq_ch_3(rdreq_ch_3),									 
										 .fifo_full_ch_1(fifo_full_ch_1),
										 .fifo_full_ch_2(fifo_full_ch_2),
										 .fifo_full_ch_3(fifo_full_ch_3),
										 .data_out(data_to_com_FPGA)
										 );

endmodule