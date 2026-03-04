  
		    // -- Support Unaligned Sw --- 
	            32'b???????_?????_?????_010_?????_0100011: begin 
		        if (store_step == 0) begin;  // read data 1
		            bus_address <= re[w_rs1] + w_imm_s; 
		            bus_read_enable <= 1; 
		            pc <= pc - 4; 
		            bubble <= 1; 
		            store_step <= 1; 
		        end if (store_step == 1) begin  // write data 1'
	                    bus_address <= re[w_rs1] + w_imm_s; 
		            case ((re[w_rs1] + w_imm_s) & 64'b11)
		                0: bus_write_data <= re[w_rs2];
		                1: bus_write_data <= {re[w_rs2][23:0], bus_read_data[7:0]};
		                2: bus_write_data <= {re[w_rs2][15:0], bus_read_data[15:0]};
		                3: bus_write_data <= {re[w_rs2][7:0], bus_read_data[23:0]};
		            endcase
		            bus_write_enable <= 1;
		            pc <= pc - 4; 
		            bubble <= 1;
		            store_step <= 2;  
		        end if (store_step == 2) begin  // read data 2
		            bus_address <= re[w_rs1] + w_imm_s + 4; 
		            bus_read_enable <= 1; 
		            pc <= pc - 4; 
		            bubble <= 1; 
		            store_step <= 3; 
		        end if (store_step == 3) begin  // write data 2'
	                    bus_address <= re[w_rs1] + w_imm_s + 4; 
		            case ((re[w_rs1] + w_imm_s) & 64'b11)
		                0: bus_write_data <= bus_read_data;
		                1: bus_write_data <= {bus_read_data[31:8], re[w_rs2][31:24]};
		                2: bus_write_data <= {bus_read_data[31:16], re[w_rs2][31:16]};
		                3: bus_write_data <= {bus_read_data[31:24], re[w_rs2][31:8]};
		            endcase
		            bus_write_enable <= 1;
		            store_step <= 0;  
		        end 
		    end // Sw 7 cycles

		    // -- Support Unaligned Lw --- 
		    32'b???????_?????_?????_010_?????_0000011: begin 
		        if (load_step == 0) begin 
		            bus_address <= re[w_rs1] + w_imm_i; 
		            bus_read_enable <= 1; 
		            pc <= pc - 4; 
		            bubble <= 1; 
		            load_step <= 1; 
		        end
	                if (load_step == 1) begin // byte_start_position in 32 bit data
		            case ((re[w_rs1] + w_imm_i) & 64'b11)
		                0: re[w_rd]<= $signed(bus_read_data[31:0]); 
		                1: re[w_rd]<= bus_read_data[31:8]; 
		                2: re[w_rd]<= bus_read_data[31:16]; 
		                3: re[w_rd]<= bus_read_data[31:24]; 
		            endcase
		            bus_address <= re[w_rs1] + w_imm_i + 4; 
		            bus_read_enable <= 1; 
		            pc <= pc - 4; 
		            bubble <= 1; 
		            load_step <= 2; 
		        end 
	                if (load_step == 2) begin 
		            case ((re[w_rs1] + w_imm_i) & 64'b11)
		                0:; // ready 
		                1: re[w_rd] <= $signed({bus_read_data[7:0],  re[w_rd][23:0]}); 
		                2: re[w_rd] <= $signed({bus_read_data[15:0], re[w_rd][15:0]}); 
		                3: re[w_rd] <= $signed({bus_read_data[23:0], re[w_rd][7:0]}); 
		            endcase
		            load_step <= 0; 
		        end 
		    end  // Lw 5 cycles

