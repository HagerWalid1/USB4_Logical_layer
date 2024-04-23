module serializer #(
    parameter DATA_WIDTH = 8  // Define the width of the parallel data input
)(
    input wire clk,                    // Clock input
    input wire rst,                  // Active low reset
    input wire [1:0] trans_state,    // transaction_gen_fsm state
    input wire [DATA_WIDTH-1:0] parallel_data, // Parallel data input
    output reg serial_out             // Serial data output
);

    // Internal variables
    reg [DATA_WIDTH-1:0] shift_reg;    // Shift register for the data being serialized
    reg [$clog2(DATA_WIDTH)-1:0] counter; // Extended counter size for synchronization
	
	localparam DISCONNECTED_S = 2'h0,
	           IDLE_S         = 2'h1,
			   START          = 2'h2;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // Reset logic
            shift_reg <= 0;
            counter <= 0;
            serial_out <= 1'b0;
        end else begin
            case (trans_state)
			    DISCONNECTED_S: begin
			        serial_out <= 0;
			    end
			    IDLE_S: begin      
			        serial_out <= 1;
			    end
			    START: begin
			        if (counter == 0) begin
                        // Load new data into shift register every DATA_WIDTH cycles
                        shift_reg <= parallel_data;
                        serial_out <= parallel_data[0];
                        counter <= DATA_WIDTH-1;
                    end else begin
                        // Serialize the data, shifting right each clock cycle
                        shift_reg <= shift_reg >> 1;
                        serial_out <= shift_reg[1]; // Output the next bit
                        counter <= counter - 1'b1;
                    end
			    end
			endcase
        end 
    end
	
endmodule

`default_nettype none
`resetall