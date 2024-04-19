//% this code generated by Ai "github cobilot" ^-^

class up_monitor;

        virtual upper_layer_if vif;
        upper_layer_tr tr;
        mailbox #(upper_layer_tr) mb_mon_scr;

        ///////// Constructor \\\\\\\\\\
        function new(virtual upper_layer_if vif, mailbox #(upper_layer_tr) mb_mon_scr);
            this.vif = vif;
            this.mb_mon_scr = mb_mon_scr;
        endfunction
    

        ///////// Main Task \\\\\\\\\\
        task run();
            forever begin
                wait_for_negedge(vif.gen_speed);
                if (vif.data_valid_out == 1) begin   //! we should tell design team to add that 
                        tr = new; 
                        tr.T_Data = vif.transport_layer_data_in; 
                        mb_mon_scr.put(tr); 
                end
        end
        endtask

                // Task to wait for the negative edge of a specific clock
        task wait_for_negedge( input GEN gen_speed );
        case (gen_speed)
        gen2: @(negedge  vif.gen2_fsm_clk );
        gen3: @(negedge  vif.gen3_fsm_clk);
        gen4: @(negedge  vif.gen4_fsm_clk);
        
        endcase
        endtask
endclass