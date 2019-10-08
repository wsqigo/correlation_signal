`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    volt_cal 
//////////////////////////////////////////////////////////////////////////////////
module volt_cal(
   input        ad_clk,                  //
	
	input [11:0] ad_ch1,              //AD第1通道的数据

  
	output reg [15:0] data_out

    );

reg [31:0] ch1_data_reg;

reg [12:0] ch1_reg;




//AD 电压换算
always @(posedge ad_clk)
begin
    if(ad_ch1[11]==1'b1) begin                     //如果CH1是负电压
	    ch1_reg<=12'hfff - ad_ch1 + 1'b1;
		 data_out<={1'b1,ch1_data_reg[26:12]};
	 end
	 else begin
       ch1_reg<=ad_ch1;
		 data_out<={1'b0,ch1_data_reg[26:12]};
	 end	 		 	 
end 		 



//AD 电压换算(1 LSB = 5V / 2048 = 2.44mV
always @(posedge ad_clk)
begin
	ch1_data_reg<=ch1_reg * 5000;						
end	



endmodule