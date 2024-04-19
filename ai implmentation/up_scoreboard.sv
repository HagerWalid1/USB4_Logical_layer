//% this code generated by Ai "github cobilot" ^-^

class up_scoreboard;
  mailbox  #(upper_layer_tr)UL_mod_scr;
  mailbox #(upper_layer_tr) UL_mon_scr;

  function new(mailbox #(upper_layer_tr) UL_mod_scr, mailbox #(upper_layer_tr) UL_mon_scr);
    this.UL_mod_scr = UL_mod_scr;
    this.UL_mon_scr = UL_mon_scr;
  endfunction: new

  task run_scr();
    upper_layer_tr mod_tr, mon_tr;

    forever begin
      UL_mod_scr.get(mod_tr);
      UL_mon_scr.get(mon_tr);

      // Display the values from mod_tr and mon_tr here
      $display("------------------------------");
      $display("[Scoreboard Upper layer ]get at time (%0t) Mod_tr: %p", $time, mod_tr);
      $display("[Scoreboard Upper layer ]get at time (%0t) mon_tr: %p", $time, mon_tr);
      
      
         // Assertion to compare the values from the two mailboxes
      assert (mod_tr.T_Data == mon_tr.T_Data) else $error("Values from the two mailboxes do not match");

        
//! we should add here more assertion if we add more var in monitor (phase , gen_speed)


    end
  endtask: run_scr
  
endclass: upper_layer_scoreboard