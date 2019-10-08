//三选一组合逻辑电路，保证数据输出没有寄存器延时  有待仿真验证
module output_select 
( 
input [15:0]return3_data,
input return3_data_flag,
input [15:0]pingpang_ram_data,
input pingpang_ram_data_flag,
output  reg[15:0]data_to_arm,
output  reg fpga_to_arm
);

always@(return3_data_flag or pingpang_ram_data_flag or 
        return3_data or pingpang_ram_data)
begin
case({return3_data_flag,pingpang_ram_data_flag})
 2'b10: begin 
         data_to_arm<=return3_data; 
			fpga_to_arm<=return3_data_flag;
			end
 2'b01: begin 
         data_to_arm<=pingpang_ram_data; 
			fpga_to_arm<=pingpang_ram_data_flag;
			end
 default:begin data_to_arm<=return3_data; 
			      fpga_to_arm<=return3_data_flag;
			end
endcase		
end	
			
endmodule

			
			