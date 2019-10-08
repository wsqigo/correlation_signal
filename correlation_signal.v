module correlation_signal(
	input clk,
	input rst,
	
	//tcd1304
	input KEY,
	output [3:0] led,
	output M,
	output ICG,
	output SH,
	
	//AD
	input [11:0]ad1_data,
	output clk_to_all_AD,//output	
	
	//fsmc
	inout [15:0]fsmc_data,//双向数据端口
	input [25:0]fsmc_addr,
	input fsmc_clk,//这里不使用
	input fsmc_nadv,//这里不使用
	input fsmc_wr,
	input fsmc_rd,
	input fsmc_cs,
	input arm_to_fpga,
	output fpga_to_arm
);


wire sys_rst_n;
wire clk_100m;
wire clk_50m;
wire clk_25m;
wire clk_10m;

system_ctrl_pll U1
(
.clk(clk),
.rst_n(rst),
.sys_rst_n(sys_rst_n),	
.clk_c0(clk_100m),		
.clk_c1(clk_25m),		
.clk_c2(clk_50m),		
.clk_c3()		
);


wire para_confi_acq_flag;
wire data_upload_acq_flag;
wire [127:0]data_buffer;
arm_write_ram U2
(
.clk_50m(clk_50m),
.rst_n(sys_rst_n),
.WRn(fsmc_wr),
.CSn(fsmc_cs),
.data(fsmc_data),
.addr(fsmc_addr),
.clk_25m(clk_25m),//write_ram读时钟
.arm_to_fpga(arm_to_fpga),
.para_confi_acq_flag(para_confi_acq_flag), //参数配置 应答标志
.data_upload_acq_flag(data_upload_acq_flag), //数据上传打开关闭 应答标志
.data_buffer(data_buffer)
);

wire [15:0]data_to_arm;
assign fsmc_data = ((!fsmc_rd)&&(!fsmc_cs)) ? data_to_arm : 16'hzzzz;//rd低电平使能 单片机读数据

wire return3_data_flag;
wire [15:0]return3_data;

arm_read_ram_return3 U3
(
.clk_25m(clk_25m),
.rst_n(sys_rst_n),
.RDn(fsmc_rd),
.CSn(fsmc_cs),
.para_confi_acq_flag(para_confi_acq_flag),
.data_upload_acq_flag(data_upload_acq_flag),
.data_buffer(data_buffer),//write_ram中的缓存数据包
.read_addr(fsmc_addr),
.data(return3_data),
.fpga_to_arm(return3_data_flag)
);


wire [15:0]data_from_data_collection;
wire fifo_full1;
wire rdreq1;
data_collection U4
(
.clk(clk_50m),   //input100m                      
.rst_n(sys_rst_n), //input
.clk_from_com_FPGA(clk_25m), //input 读data_collection fifo的时钟
.normal_signal(normal_signal),//input					  						  						  
.data_from_AD1(ad1_data),//input
.clk_to_all_AD(clk_to_all_AD),//output	
.data_to_com_FPGA(data_from_data_collection),//output
.rdreq_ch_1(rdreq1),//input
.fifo_full_ch_1(fifo_full1),//output
.cycle_value_flag(para_cofi_flag)//input 1/128周期计数标志 ，脉冲式信号						  
);

wire [7:0] channel1;
wire [15:0]noise_threshold;
para_analysis U5
(
.clk_25m(clk_25m),
.rst_n(sys_rst_n),
.para_confi_acq_flag(para_confi_acq_flag),
.data_upload_acq_flag(data_upload_acq_flag),
.data_buffer(data_buffer),
.para_cofi_flag(para_cofi_flag), //参数发送到其他模块的标志信号
.noise_threshold(noise_threshold),			//噪声阈值信号output[15:0]
.channel1(channel1),            //通道选择 
.cycle_value(cycle_value),				//周期值output[15:0]
.contin_mode_open(contin_mode_open) //非脉冲式信号 1打开 0 关闭

);

wire normal_signal;
ccd_drive  U6
(
   .clk(clk_50m),
   .rst_n(sys_rst_n),
   .key_in(KEY),
 
 // TCD1304 signal
	.M(M),
	.ICG(ICG),
	.SH(SH),
	
	// Module interface
	.signal(normal_signal),
	.led(led)
 );
 
 
 wire [15 :0] data_to_channel_polling;
 contin_mode_openclose U7
(
.clk_25m(clk_25m),
.rst_n(sys_rst_n),
.datain(data_from_data_collection),
.fifo_full1_in(fifo_full1),
.dataout(data_to_channel_polling),
.fifo_full1_out(fifo_full1_out)
);

wire [15:0]data_to_data_deal;
wire flag_to_data_deal;
wire [3:0]channel_number;
channel_polling U8
(
.clk_25m(clk_25m),
.rst_n(sys_rst_n),
.para_cofi_flag(para_cofi_flag),
.channel1(channel1),  //通道选择 
.data_from_data_collection(data_to_channel_polling), //data_collection出来的数据
.fifo_full1(fifo_full1_out),
.rdreq1(rdreq1),
.data_out(data_to_data_deal),//output[15:0]
.data_flag(flag_to_data_deal),//output
.channel_number(channel_number)//output[3:0]
);

wire wr_ram_flag;
wire [15:0]data_out_to_pingpangram;
data_deal U9
(
.clk_25m(clk_25m),
.rst_n(sys_rst_n),
.para_cofi_flag(para_cofi_flag),     
.noise_threshold(noise_threshold),  //噪声阈值
.data_in(data_to_data_deal),
.data_flag(flag_to_data_deal),
.channel_number(channel_number),
.data_out(data_out_to_pingpangram),//output[15:0]
.wr_ram_flag(wr_ram_flag)//output
);


wire pingpang_ram_data_flag;
wire [15:0]pingpang_ram_data;
arm_read_pingpang_ram U10
(
.clk_25m(clk_25m),
.clk_50m(clk_50m),
.rst_n(sys_rst_n),
.data_in_flag(wr_ram_flag),//数据标志
.data_in(data_out_to_pingpangram),//数据
.RDn(fsmc_rd),
.CSn(fsmc_cs),
.read_addr(fsmc_addr),
.data(pingpang_ram_data),//output[15:0]
.fpga_to_arm(pingpang_ram_data_flag)//output 
);

output_select U11
( 
.return3_data(return3_data),
.return3_data_flag(return3_data_flag),
.pingpang_ram_data(pingpang_ram_data),
.pingpang_ram_data_flag(pingpang_ram_data_flag),
.data_to_arm(data_to_arm),
.fpga_to_arm(fpga_to_arm)
);

endmodule