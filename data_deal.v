//数据处理模块  通过噪声阈值和脉冲阈值来处理传来的数据 
//在数据段前加上通道号 在数据段后加上峰值计数
module data_deal
(
input clk_25m,
input rst_n,
input para_cofi_flag,     
input [15:0] noise_threshold,  //噪声阈值
//input [15:0] pulse_threshold,  //脉冲阈值
input [15:0] data_in,
input  data_flag,
input [3:0]  channel_number,
output reg[15:0] data_out,
output reg  wr_ram_flag
);

reg [2:0] i;
reg [7:0] count;       //脉冲计数
reg [7:0] count_all;   //总计数

reg [15:0] noise_threshold_reg; 

always@(posedge clk_25m or negedge rst_n)
begin
 if(!rst_n)
   begin 
	   noise_threshold_reg<=16'h0;
	end		
  else if(para_cofi_flag)
	 begin
	   noise_threshold_reg<=noise_threshold;
	 end
end


always@(posedge clk_25m or negedge rst_n)
begin 
  if(!rst_n)
       begin
       data_out<=16'h0;
       count<=8'b0;
       count_all<=8'b0;
		 i<=0;
		 wr_ram_flag<=0;
       end 
  else if((data_flag)&&(count_all<8'd134))
       
	          begin
                 count_all<=count_all+1'b1;
                 case(i)
                 3'd0: begin data_out<=16'h0; i<=i+1'b1; end
                 3'd1: begin data_out<=16'h0; i<=i+1'b1; end
                 3'd2: begin data_out<=16'h0; i<=i+1'b1; end
					  3'd3: begin data_out<=16'h0; i<=i+1'b1; end
					  //存在contin_mode_openclose模块 多延时一个周期 待验证
					  3'd4: begin data_out<=16'h0; i<=i+1'b1; end
	              3'd5: begin data_out<={12'h0,channel_number}; i<=i+1'b1; wr_ram_flag<=1;end
	              3'd6: begin 
			           if(data_in>=noise_threshold_reg)
			                 begin data_out<=data_in; count<=count+1'b1;end  
		              else data_out<=16'h0;
					     end
					  endcase	  
				 end	  
  else if(count_all==8'd134)
      begin  data_out<={8'b0,count};
		      count_all<=count_all+1'b1;  end
        
  else 
     begin data_out<=data_in; count<=8'd0;count_all<=8'd0;i<=0;wr_ram_flag<=0; end

end
endmodule

