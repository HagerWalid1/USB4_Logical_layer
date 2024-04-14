class phase3 extends primary_steps;

        extentions  extention;
        int_packet i_transaction ;      // internal transaction
        mem        m_transaction;   // memory transaction
        mailbox #(int_packet) int_ag ;
        mailbox #(mem)    mem_ag ;      // internal memory agent


        function new(  mailbox  #(elec_layer_tr)  elec_ag_Tx , mailbox  #(elec_layer_tr)  elec_ag_Rx , mailbox #(mem) mem_ag ,
                                 mailbox #(int_packet) int_ag , mailbox #(config_transaction) config_ag_Rx);
            this.elec_ag_Rx = elec_ag_Rx;
            this.mem_ag = mem_ag;
            this.int_ag = int_ag;
            this.config_ag_Rx = config_ag_Rx ;
            this.elec_ag_Tx = elec_ag_Tx;
            
            

        // link with the extentions agent class
            extention = new(int_ag , elec_ag_Tx );


             i_transaction = new();
            m_transaction = new();
        //extentions.new(this.int_ag);
        endfunction



        // task to get transactions from the mailboxes
        task  get_transactions();
            elec_ag_Rx.get(E_transaction);
            config_ag_Rx.try_get(C_transaction);
            $display ("in phase3 E_transaction = %p",E_transaction);
            //$display ("in phase3 C_transaction = %p",C_transaction);
        endtask

        // task to handle phase 3 and error checking
        task  handle_phase_and_error();
            if (E_transaction.phase==3 && (E_transaction.transaction_type[2:1]==2'b01))  // we have an command or response
            fork
                handle_command();
                handle_response();
            join
            
            else
            begin
                i_transaction.sb_en = 0;        // turn off sideband
            end
        //i_transaction.mem_gen = 1;       //  sb work as a genrator
        int_ag.put(i_transaction) ;         // socend put in the mailbox 
        i_transaction = new();
        endtask
 
 
        // task to handle command
        task  handle_command();
            if ((E_transaction.transaction_type=='b010 ) && (E_transaction.read_write==0) )     // we have a command  . out responce from sideband
            begin
                ////$display ("in handle_command");
                    i_transaction.sb_en    = 1;
                    i_transaction.tran_en = 1;                  
                    i_transaction.At_sel   = 1;         // out response 
                    i_transaction.sb_add   = E_transaction.address ;     //address to read from sideband
                    i_transaction.read_write = 0;       //read from sideband
                    i_transaction.gen_res = 1;          //  genrate response
                    
                end
               /* else if ((E_transaction.transaction_type=='b010 ) && (E_transaction.read_write==1))   //write a responce to sideband from giving pareameter
                    begin
                        i_transaction.sb_en         = 1;
                        i_transaction.tran_en      = 1;
                        i_transaction.At_sel        = 1;
                        i_transaction.read_write = 1;                               //WRITE in sideband
                        i_transaction.sb_add      = E_transaction.address ;       //address 
                        i_transaction.sb_data_in = E_transaction.cmd_rsp_data ;
                        
                end */ //! i think that will not be needed

        endtask

        // task to handle response
        task  handle_response();
            if ((E_transaction.transaction_type=='b011 ) && (E_transaction.read_write==1))   // we have a response
            begin
                i_transaction.gen_res = 0;          //  not genrate response
                
                if ((E_transaction.cmd_rsp_data[5]==1)  && (E_transaction.cmd_rsp_data[10]==0) && (E_transaction.gen_speed == 1) )
                    m_transaction.gen = 3;
                else if ((E_transaction.cmd_rsp_data[5]==0)  && (E_transaction.cmd_rsp_data[10]==1) && (E_transaction.gen_speed == 2))
                    m_transaction.gen = 4;
                else if ((E_transaction.cmd_rsp_data[10]==0) && (E_transaction.cmd_rsp_data[5]==0)  && (E_transaction.gen_speed == 0))
                    m_transaction.gen = 2;
                else 
                    m_transaction.gen = 0;          //* error in the response
            end 

            //$display ("we are gen  %0d",m_transaction.gen);
            mem_ag.put(m_transaction);
            m_transaction = new();
        endtask



        // task to send command
        task send_command ;
        begin
            if (E_transaction.phase==3 )
            begin
                i_transaction.sb_en    = 1;
                i_transaction.tran_en = 1;                  
                i_transaction.At_sel   = 0;         // out command
                i_transaction.sb_add   = E_transaction.address ;     //address to read from sideband
                i_transaction.read_write = 0;       //read from sideband
                i_transaction.gen_res=0;           // generate 
            end
            else 
            begin
                i_transaction.sb_en = 0;
            end

            int_ag.put(i_transaction) ;         // first put in the mailbox 
            i_transaction = new();
            ////$display ("send_command done . i_transaction = %p",i_transaction);
        end
        endtask //send_command




        // AT task now calls the smaller tasks
        task run_phase3() ;
            begin
                create_transactions();
                //$display ("done creat transactions ");
                get_transactions();


                // ----------------------- handle actions ----------------------
                if(!E_transaction.sbrx)      
                begin
                    $display ("we are in sbrx =0 case action");
                    // E_transaction.phase = 1;         //! should we go to phase 1 or 2 
                    E_transaction.sbtx = 0;         
                    elec_ag_Tx.put(E_transaction) ;
                    E_transaction = new();
                end
                else if (C_transaction.lane_disable && (E_transaction.phase == 3) ) 
                begin       
                    $display ("we are in lane disable case action");
                   E_transaction.sbtx  = 0;
                   elec_ag_Tx.put(E_transaction) ;
                   E_transaction = new();

                 end


                 // ----------------------- run main task ----------------------
                else 
                    begin
                
                    send_command ();
                    handle_phase_and_error();
                
               extention.get_values ();

                end

            end
        endtask 

    endclass