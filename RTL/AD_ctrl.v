///模块说明////////////// 1
//AD控制模块
//功能：1、给定AD时钟
//		 2、接收AD数据
//		 3、将AD数据转换成mV电压值，转换方法是:AD_data*20000/4096 放大10倍
//     注意这里是减去了1V的基准，后期根据功能修改
//////////////////////////

module AD_ctrl
(
input clk,                  //50m
input rst_n,
input[11:0] data_from_AD,   //AD过来的数据信号
output clk_to_AD,           //输出给AD的时钟信号
output [15:0]data_out	 //输出给下一级的幅值信号
);
					

assign clk_to_AD=clk; 
reg [11 : 0] ad_ch1;

//AD CH1通道数据颠倒
always @(posedge clk)
begin
    ad_ch1[11] <= data_from_AD[0];  
    ad_ch1[10] <= data_from_AD[1];  
    ad_ch1[9] <= data_from_AD[2];  
    ad_ch1[8] <= data_from_AD[3];  
    ad_ch1[7] <= data_from_AD[4];  
    ad_ch1[6] <= data_from_AD[5];  
    ad_ch1[5] <= data_from_AD[6];  
    ad_ch1[4] <= data_from_AD[7];  
    ad_ch1[3] <= data_from_AD[8];  
    ad_ch1[2] <= data_from_AD[9];  
    ad_ch1[1] <= data_from_AD[10];  
    ad_ch1[0] <= data_from_AD[11];  	 
end 


/**********AD十六进制转十进制***********/
volt_cal u2(
		.ad_clk           		 (clk),	
		.ad_ch1            		 (ad_ch1),           //ad1 data 12bit
	
		.data_out                 (data_out)         //ad1 BCD voltage	
    );
	 
	 

endmodule