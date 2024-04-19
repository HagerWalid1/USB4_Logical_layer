	class upper_layer_driver;

		// Event Signals
		event UL_gen_drv_done;

		//Transaction
		upper_layer_tr UL_tr;

		// Virtual Interface
		virtual upper_layer_if v_if;

		// Mailboxes
		mailbox #(upper_layer_tr) UL_gen_drv; // connects Stimulus generator to the driver inside the agent


		function new(input virtual upper_layer_if v_if, mailbox #(upper_layer_tr) UL_gen_drv, event UL_gen_drv_done);

			//Interface Connections
			this.v_if = v_if;

			// Mailbox connections between (Driver) and (UL Agent)
			this.UL_gen_drv = UL_gen_drv;
			
			// Event Signals Connections
			this.UL_gen_drv_done = UL_gen_drv_done;
				
		endfunction : new

		task run;
			forever begin

				//////////////////////////////////////////////////
				/////RECEIVING TEST STIMULUS FROM generator //////
				//////////////////////////////////////////////////

				UL_tr = new();
				UL_gen_drv.get(UL_tr);
				v_if.phase = UL_tr.phase;
				v_if.generation_speed = UL_tr.gen_speed;

				//////////////////////////////////////////////////
				//////////////PIN LEVEL ASSIGNMENT ///////////////
				//////////////////////////////////////////////////



				// case (UL_tr.gen_speed)

				// 	gen2:
				// 	begin
				// 		Send_gen2_encoded();
				// 	end

				// 	gen3:
				// 	begin
				// 		Send_gen3_encoded();
				// 	end

				// 	gen4:
				// 	begin
				// 		Send_gen4_encoded();
				// 	end


				// endcase
				

				
				wait_negedge(UL_tr.gen_speed); 
				begin
					v_if.transport_layer_data_in = UL_tr.T_Data;
					-> UL_gen_drv_done; // Triggering Event to notify stimulus generator
				end
				


			end
			

		endtask : run

		task wait_negedge (input GEN generation);
			if (generation == gen2)
			begin
				@(negedge v_if.gen2_fsm_clk);
			end
			else if (generation == gen3)
			begin
				@(negedge v_if.gen3_fsm_clk);
			end
			else if (generation == gen4)
			begin
				@(negedge v_if.gen4_fsm_clk);
			end
		endtask


		

		task Send_gen2_encoded(); // 128/132 encoding

			wait_negedge(UL_tr.gen_speed);
			v_if.transport_layer_data_in = {4'b0101,UL_tr.T_Data[3:0]};
			UL_tr.T_Data = UL_tr.T_Data >> 4;
			repeat(7)
			begin
				wait_negedge(UL_tr.gen_speed);	
			end

			for (int i = 0 ; i<16; i++)
				begin
					wait_negedge(UL_tr.gen_speed);
					v_if.transport_layer_data_in = UL_tr.T_Data[7:0];
					UL_tr.T_Data = UL_tr.T_Data >> 8;

					repeat(7)
					begin
						wait_negedge(UL_tr.gen_speed);	
					end
				end
		endtask

		task Send_gen3_encoded(); // 64/66 encoding

			wait_negedge(UL_tr.gen_speed);
			v_if.transport_layer_data_in = {2'b01,UL_tr.T_Data[5:0]};
			UL_tr.T_Data = UL_tr.T_Data >> 6;
			repeat(7)
			begin
				wait_negedge(UL_tr.gen_speed);	
			end

			for (int i = 0 ; i<16; i++)
				begin
					wait_negedge(UL_tr.gen_speed);
					v_if.transport_layer_data_in = UL_tr.T_Data[7:0];
					UL_tr.T_Data = UL_tr.T_Data >> 8;

					repeat(7)
					begin
						wait_negedge(UL_tr.gen_speed);	
					end
				end
		endtask

		task Send_gen4_encoded(); // 8/11 encoding

			
			wait_negedge(UL_tr.gen_speed);
			v_if.transport_layer_data_in = {4'b0101,UL_tr.T_Data[3:0]};
			UL_tr.T_Data = UL_tr.T_Data >> 4;
			repeat(7)
			begin
				wait_negedge(UL_tr.gen_speed);	
			end

			for (int i = 0 ; i<16; i++)
				begin
					wait_negedge(UL_tr.gen_speed);
					v_if.transport_layer_data_in = UL_tr.T_Data[7:0];
					UL_tr.T_Data = UL_tr.T_Data >> 8;

					repeat(7)
					begin
						wait_negedge(UL_tr.gen_speed);	
					end
				end
		endtask

		
	endclass : upper_layer_driver