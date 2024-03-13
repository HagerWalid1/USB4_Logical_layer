	class virtual_sequence;

		// Virtual Stimulus generators
		config_space_stimulus_generator v_config_space_stim;
		elec_layer_generator v_elec_layer_generator;
		upper_layer_generator v_upper_layer_generator;


		//Basic Flow 1
		task run;

			// Phase 1
			v_elec_layer_generator.phase_force(1);
			//v_config_space_stim.execute("capability");

			//v_config_space_stim.execute("generation");
			v_config_space_stim.execute;



			//Phase 2
			v_elec_layer_generator.sbrx_high("Host");

			//$stop;

			// Phase 3
			// v_elec_layer_generator.send_transaction(AT_cmd,3,0,8'h0A,7'h1,24'h000001); // testing AT command 

			
			// v_elec_layer_generator.send_transaction(LT_fall);  // Testing LT Fall 

			//v_elec_layer_generator.send_transaction(AT_rsp,3,1,8'h0B,7'h3,24'h123456); // testing AT response 

			// // @(EVENTT) from monitor after receiving AT CMND to respond with AT_rsp to continue phase 3
			
			// // Phase 4
			// v_elec_layer_generator.send_ordered_sets(SLOS1,gen2);
			// v_elec_layer_generator.send_ordered_sets(SLOS1,gen2);
			// v_elec_layer_generator.send_ordered_sets(SLOS1,gen3);
			// v_elec_layer_generator.send_ordered_sets(SLOS2,gen2);
			// v_elec_layer_generator.send_ordered_sets(SLOS2,gen3);

			// v_elec_layer_generator.send_ordered_sets(TS1_gen2_3,gen2);
			// v_elec_layer_generator.send_ordered_sets(TS2_gen2_3,gen3);

			// //$stop();
			// //v_elec_layer_generator.phase_force(4);
			// //v_elec_layer_generator.send_ordered_sets(TS1_gen4,gen4);

			// v_elec_layer_generator.send_ordered_sets(TS1_gen4,gen4);

			// v_elec_layer_generator.send_ordered_sets(TS2_gen4,gen4);
			
			// v_elec_layer_generator.send_ordered_sets(TS3,gen4);
			// //#(tTrainingError); //To test tTrainingError
			// v_elec_layer_generator.send_ordered_sets(TS4,gen4);
		
	
			
			// // // Phase 5
			// // // fork join for electrical_to_transport layer data and vice versa
			// // v_elec_layer_generator.phase_force(5);
			// repeat (20)
			// begin
			// 	v_upper_layer_generator.send_transport_data(gen4);	
			//end
			
			// disable
			//$stop();

		endtask : run


	endclass : virtual_sequence