module transactions_gen_fsm (
    input            sb_clk,                   
    input            rst,                       

    input [23:0]     sb_read,                   
    input [2:0]      trans_sel,                 
    input            disconnect_sbtx,
    input            tdisconnect_tx_min,

    output reg [9:0] trans,  
    output reg [ 1 : 0 ] trans_state,                       
    output reg       crc_en,                    
    output reg       sbtx_sel,                 
    output reg       trans_sent,               
    output reg      disconnected_s            
);

// Define states
localparam DISCONNECT = 0;
localparam IDLE = 1;
localparam DLE1 = 2;
localparam LSE = 3;
localparam CLSE = 4;

localparam STX_COMMAND = 5;
localparam DATA_WRITE_COMMAND_ADDRESS = 6;
localparam DATA_WRITE_COMMAND_LENGTH = 7;
localparam DATA_WRITE_COMMAND_DATA = 8;
localparam DATA_READ_COMMAND_ADDRESS = 9;
localparam DATA_READ_COMMAND_LENGTH = 10;

localparam STX_RESPONSE = 11;
localparam DATA_WRITE_RESPONSE_ADDRESS = 12;
localparam DATA_WRITE_RESPONSE_LENGTH = 13;
localparam DATA_WRITE_RESPONSE_DATA = 14;
localparam DATA_READ_RESPONSE_ADDRESS = 15;
localparam DATA_READ_RESPONSE_LENGTH = 16;
localparam DATA_READ_RESPONSE_DATA = 17;

localparam CRC_LOW = 18;
localparam CRC_HIGH = 19;

localparam DLE2 = 20;
localparam ETX = 21;

// Local localparams
localparam DLE_SYMBOL = 8'hFE;

localparam STX_COMMAND_SYMBOL = 8'b00000101;
localparam STX_RESPONSE_SYMBOL = 8'b00000100;


localparam LSE_SYMBOL = 8'b10000000;
localparam CLSE_SYMBOL = ~LSE_SYMBOL;

localparam ETX_SYMBOL = 8'h40;

localparam DISCONNECTED_S = 2'h0,
	       IDLE_S         = 2'h1,
		   START          = 2'h2;



// State register
reg [4:0] cs, ns;

// Counter
reg [3:0] symbol_count;

//data_counter

reg [2:0] data_count;

//capture output at posedge clk

reg [9:0] trans_reg ;
reg [1:0] trans_state_reg;
reg	crc_en_reg ;
reg	sbtx_sel_reg;
reg disconnected_s_reg;

reg [2:0] trans_sel_pulse;


always @(posedge sb_clk) begin 

	
	trans <= trans_reg ;
	crc_en <= crc_en_reg ;
	sbtx_sel <= sbtx_sel_reg ;
	trans_state <= trans_state_reg ;
	disconnected_s<= disconnected_s_reg;	
	
end



// Next state logic
always @ (posedge sb_clk or negedge rst) begin
    if (!rst) begin
        cs <= DISCONNECT;
    end else begin
        cs <= ns;
    end
end

// State transition and output logic
always @* begin
    case (cs)
    DISCONNECT: begin
            if (disconnect_sbtx || !tdisconnect_tx_min) begin
                ns = DISCONNECT;
                trans_reg = 10'b0000000000;
                crc_en_reg = 1'b0;
                sbtx_sel_reg = 1'b0;
                trans_state_reg = DISCONNECTED_S;
                disconnected_s_reg =1'b1;
            end else begin
                ns = IDLE; // Default next state
                trans_reg = 10'b1111111111;
                crc_en_reg = 1'b0;
                trans_state_reg = IDLE_S;
                sbtx_sel_reg = 1'b0;
                disconnected_s_reg =1'b1;
            end
        end
        
        IDLE: begin
            if (trans_sel_pulse== 3'b000) begin // If trans_sel is 0
                ns = IDLE;
                trans_reg = 10'b1111111111;
                crc_en_reg = 1'b0;
                trans_state_reg = IDLE_S;
                sbtx_sel_reg = 1'b0;
                disconnected_s_reg =1'b0;
            end else if (trans_sel_pulse == 3'b001) begin // If trans_sel is 1
                ns = DISCONNECT;
                trans_reg = 10'b0000000000;
                crc_en_reg = 1'b0;
                trans_state_reg = DISCONNECTED_S;
                sbtx_sel_reg = 1'b0;
                disconnected_s_reg =1'b0;
            end else if (trans_sel == 3'b010) begin // If trans_sel is 2
                ns = DLE1;
                trans_reg = {1'b1, DLE_SYMBOL, 1'b0};
                crc_en_reg = 1'b0;
                sbtx_sel_reg = 1'b0;
                trans_state_reg = START;
                disconnected_s_reg =1'b0;
                
            end else if (trans_sel == 3'b011) begin // If trans_sel is 3
                ns = DLE1;
                trans_reg = {1'b1, DLE_SYMBOL, 1'b0};
                crc_en_reg = 1'b0;
                sbtx_sel_reg = 1'b0;
                trans_state_reg = START;
                disconnected_s_reg =1'b0;
                
            end else if (trans_sel == 3'b100) begin // If trans_sel is 4
                ns = DLE1;
                trans_reg = {1'b1, DLE_SYMBOL, 1'b0};
                crc_en_reg = 1'b0;
                trans_state_reg = START;
                sbtx_sel_reg = 1'b0;
                disconnected_s_reg =1'b0;
            end else begin // Default case
                ns = IDLE;
                trans_reg = 10'b1111111111;
                crc_en_reg = 1'b0;
                sbtx_sel_reg = 1'b0;
                trans_state_reg = IDLE;
                disconnected_s_reg =1'b0;
            end
        end
        
        DLE1: begin
            if (symbol_count == 9) begin // If symbol_count reaches 9
                if (trans_sel_pulse == 3'b010) begin // If trans_sel is 2
                    ns = STX_COMMAND; // Transition to STX_COMMAND state
                    trans_reg = {1'b1, STX_COMMAND_SYMBOL, 1'b0}; // Set trans_reg output to STX_COMMAND_SYMBOL
                    crc_en_reg = 1'b1; // Enable CRC
                    sbtx_sel_reg = 1'b0; // Set sbtx_sel_reg to 0
                    disconnected_s_reg =1'b0;
                end else if (trans_sel_pulse == 3'b011) begin // If trans_sel is 3
                    ns = STX_RESPONSE; // Transition to STX_RESPONSE state
                    trans_reg = {1'b1, STX_RESPONSE_SYMBOL, 1'b0}; // Set trans_reg output to STX_RESPONSE_SYMBOL
                    crc_en_reg = 1'b1; // Enable CRC
                    sbtx_sel_reg = 1'b0; // Set sbtx_sel_reg to 0
                    disconnected_s_reg =1'b0;
                end else if (trans_sel_pulse == 3'b100) begin // If trans_sel is 4
                    ns = LSE; // Transition to LSE state
                    trans_reg = {1'b1, LSE_SYMBOL, 1'b0}; // Set trans_reg output to LSE_SYMBOL
                    crc_en_reg = 1'b1; // Enable CRC
                    sbtx_sel_reg = 1'b0; // Set sbtx_sel_reg to 0
                    disconnected_s_reg =1'b0;
                end
            end else begin // If symbol_count is not 9
                // Stay in DLE1 state
                ns = DLE1;
                // Hold the current value of trans_reg output
                trans_reg = trans_reg;
                // Disable CRC and sbtx_sel_reg
                crc_en_reg = 1'b0;
                sbtx_sel_reg = 1'b0;
                disconnected_s_reg =1'b0;
            end
        end
        
        LSE: begin
          crc_en_reg = 1'b1; //enable crc when enter LSE
          
            if (symbol_count == 9 && trans_sel_pulse == 3'b100) begin // If symbol_count reaches 9 and trans_sel is 4
                ns = CLSE; // Transition to CLSE state
                trans_reg = {1'b1, CLSE_SYMBOL, 1'b0}; // Set trans_reg output to CLSE_SYMBOL
                crc_en_reg = 1'b1; // Enable CRC
                sbtx_sel_reg = 1'b0; // Set sbtx_sel_reg to 0
                disconnected_s_reg =1'b0;
            end else begin // If symbol_count is not 9 or trans_sel is not 4
                // Stay in LSE state
                ns = LSE;
                // Hold the current value of trans_reg output
                trans_reg = trans_reg;
                // Disable CRC and sbtx_sel_reg
                crc_en_reg = 1'b0;
                sbtx_sel_reg = 1'b0;
                disconnected_s_reg =1'b0;
            end
        end
        CLSE: begin
            if (symbol_count == 9 && trans_sel_pulse == 3'b100) begin // If symbol_count reaches 9 and trans_sel is 4
                ns = IDLE; // Transition to IDLE state
                trans_reg = 10'b1111111111; // Set trans_reg output to all ones
                crc_en_reg = 1'b0; // Disable CRC
                sbtx_sel_reg = 1'b0; // Enable sbtx_sel_reg
                disconnected_s_reg =1'b0;
            end else begin // If symbol_count is not 9 or trans_sel is not 4
                // Stay in CLSE state
                ns = CLSE;
                // Hold the current value of trans_reg output
                trans_reg = trans_reg;
                // Disable CRC and sbtx_sel_reg
                crc_en_reg = 1'b0;
                sbtx_sel_reg = 1'b0;
                disconnected_s_reg =1'b0;
            end
        end
        
        STX_COMMAND: begin
          crc_en_reg = 1;
            if (symbol_count == 9 && trans_sel_pulse == 3'b010) begin // If symbol_count reaches 9 and trans_sel is 2
                ns = DATA_READ_COMMAND_ADDRESS; // Transition to DATA_READ_COMMAND_ADDRESS state
                trans_reg = {1'b1, 8'd78, 1'b0}; // Set trans_reg output to the address of reg 12
                crc_en_reg = 1'b1; // Enable CRC
                disconnected_s_reg =1'b0;
                sbtx_sel_reg = 1'b0; // Set sbtx_sel_reg to 0
               
            end else begin // If symbol_count is not 9 or trans_sel is not 2
                // Stay in STX_COMMAND state
                ns = STX_COMMAND;
                // Hold the current value of trans_reg output
                trans_reg = trans_reg;
                // Disable CRC and sbtx_sel_reg
                crc_en_reg = 1'b0;
                sbtx_sel_reg = 1'b0;
                disconnected_s_reg =1'b0;
            end
        end
        DATA_READ_COMMAND_ADDRESS: begin
            if (symbol_count == 9 && trans_sel_pulse == 3'b010) begin // If symbol_count is 9 and trans_sel is 2
                ns = DATA_READ_COMMAND_LENGTH; // Transition to DATA_READ_COMMAND_LENGTH state
                trans_reg = {1'b1, 7'h3, 1'b0, 1'b0}; // Set trans_reg output to the length of the command
                crc_en_reg = 1'b1; // Enable CRC
                sbtx_sel_reg = 1'b0; // Set sbtx_sel_reg to 0
                disconnected_s_reg =1'b0;
            end else begin // If symbol_count is not 9 or trans_sel is not 2
                // Stay in DATA_READ_COMMAND_ADDRESS state
                ns = DATA_READ_COMMAND_ADDRESS;
                // Hold the current value of trans_reg output
                trans_reg = trans_reg;
                // Disable CRC and sbtx_sel_reg
                crc_en_reg = 1'b0;
                sbtx_sel_reg = 1'b0;
                disconnected_s_reg =1'b0;
            end
        end
        
        
       DATA_READ_COMMAND_LENGTH: begin
            if (symbol_count == 9 && trans_sel == 3'b010) begin // If symbol_count is 9 and trans_sel is 2
                ns = CRC_LOW; // Transition to CRC_LOW state
                trans_reg = 10'b0; // Set trans_reg output to 0
                crc_en_reg = 1'b1; // Enable CRC
                sbtx_sel_reg = 1'b0; // Set sbtx_sel_reg to 0
                disconnected_s_reg =1'b0;
            end else begin // If symbol_count is not 9 or trans_sel is not 2
                // Stay in DATA_READ_COMMAND_LENGTH state
                ns = DATA_READ_COMMAND_LENGTH;
                // Hold the current value of trans_reg output
                trans_reg = trans_reg;
                // Disable CRC and sbtx_sel_reg
                crc_en_reg = 1'b0;
                sbtx_sel_reg = 1'b0;
                disconnected_s_reg =1'b0;
            end
        end
        
              STX_RESPONSE: begin
                crc_en_reg = 1;
            if (symbol_count == 9 && trans_sel_pulse == 3'b011) begin // If symbol_count is 9 and trans_sel is 3
                ns = DATA_READ_RESPONSE_ADDRESS; // Transition to DATA_READ_RESPONSE_ADDRESS state
                trans_reg = {1'b1, 8'd78, 1'b0}; // Set trans_reg output to the address of reg 12
                crc_en_reg = 1'b1; // Enable CRC
                sbtx_sel_reg = 1'b0; // Set sbtx_sel_reg to 0
                disconnected_s_reg =1'b0;
            end else begin // If symbol_count is not 9 or trans_sel is not 3
                // Stay in STX_RESPONSE state
                ns = STX_RESPONSE;
                // Hold the current value of trans_reg output
                trans_reg = trans_reg;
                // Disable CRC and sbtx_sel_reg
                crc_en_reg = 1'b0;
                sbtx_sel_reg = 1'b0;
                disconnected_s_reg =1'b0;
            end
        end
        
        DATA_READ_RESPONSE_ADDRESS: begin
            if (symbol_count == 9 && trans_sel_pulse == 3'b011) begin // If symbol_count is 9 and trans_sel is 3
                ns = DATA_READ_RESPONSE_LENGTH; // Transition to DATA_READ_RESPONSE_LENGTH state
                trans_reg = {1'b1,7'h3,1'b0,1'b0}; // Set trans_reg output to the address of reg 12
                crc_en_reg = 1'b1; // Enable CRC
                sbtx_sel_reg = 1'b0; // Set sbtx_sel_reg to 0
                disconnected_s_reg =1'b0;
            end else begin // If symbol_count is not 9 or trans_sel is not 3
                // Stay in DATA_READ_RESPONSE_ADDRESS state
                ns = DATA_READ_RESPONSE_ADDRESS;
                // Hold the current value of trans_reg output
                trans_reg = trans_reg;
                // Disable CRC and sbtx_sel_reg
                crc_en_reg = 1'b0;
                sbtx_sel_reg = 1'b0;
                disconnected_s_reg =1'b0;
            end
        end
        DATA_READ_RESPONSE_LENGTH: begin
            if (symbol_count == 9 && trans_sel_pulse == 3'b011) begin // If symbol_count is 9 and trans_sel is 3
                ns = DATA_READ_RESPONSE_DATA; // Transition to DATA_READ_RESPONSE_DATA state
                trans_reg = {1'b1, sb_read[7:0], 1'b0}; // Set trans_reg output to sb_read[9:0]
                crc_en_reg = 1'b1; // Enable CRC
                sbtx_sel_reg = 1'b0; // Set sbtx_sel_reg to 0
                disconnected_s_reg =1'b0;
            end else begin // If symbol_count is not 9 or trans_sel is not 2
                // Stay in DATA_READ_RESPONSE_LENGTH state
                ns = DATA_READ_RESPONSE_LENGTH;
                // Hold the current value of trans_reg output
                trans_reg = trans_reg;
                // Disable CRC and sbtx_sel_reg
                crc_en_reg = 1'b0;
                sbtx_sel_reg = 1'b0;
                disconnected_s_reg =1'b0;
            end
        end
        
        DATA_READ_RESPONSE_DATA: begin
            if (symbol_count == 9) begin
                if (trans_sel_pulse == 3'b011 && data_count == 3'b010) begin // If symbol_count is 9, trans_sel is 3, and data_count is 2
                    ns = CRC_LOW; // Transition to CRC_LOW state
                    trans_reg = 'b0; // Set trans_reg output to 0
                    crc_en_reg = 1'b1; // Enable CRC
                    sbtx_sel_reg = 1'b1; // Set sbtx_sel_reg to 1
                    disconnected_s_reg =1'b0;
                end else if (data_count == 3'b000) begin // If symbol_count is 9 and data_count is 1
                    ns = DATA_READ_RESPONSE_DATA; // Stay in DATA_READ_RESPONSE_DATA state
                    // Concatenate start bit = 1, end bit = 0, and the 1st 8 bits of sb_read
                    trans_reg = {1'b1, sb_read[15:8], 1'b0};
                    crc_en_reg = 1'b1; // Enable CRC
                    sbtx_sel_reg = 1'b0; // Set sbtx_sel_reg to 0
                    disconnected_s_reg =1'b0;
                end else if (data_count == 3'b001) begin // If symbol_count is 9 and data_count is 0
                    ns = DATA_READ_RESPONSE_DATA; // Stay in DATA_READ_RESPONSE_DATA state
                    // Concatenate start bit = 1, end bit = 0, and the second 8 bits of sb_read
                    trans_reg = {1'b1, sb_read[23:16], 1'b0};
                    crc_en_reg = 1'b1; // Enable CRC
                    sbtx_sel_reg = 1'b0; // Set sbtx_sel_reg to 0
                    disconnected_s_reg =1'b0;
                end else begin
                    // Stay in DATA_READ_RESPONSE_DATA state
                    ns = DATA_READ_RESPONSE_DATA;
                    // Hold the current value of trans_reg output
                    trans_reg = trans_reg;
                    // Disable CRC and sbtx_sel_reg
                    crc_en_reg = 1'b0;
                    sbtx_sel_reg = 1'b0;
                    disconnected_s_reg =1'b0;
                end
            end else begin
                // Stay in DATA_READ_RESPONSE_DATA state
                ns = DATA_READ_RESPONSE_DATA;
                // Hold the current value of trans_reg output
                trans_reg = trans_reg;
                // Disable CRC and sbtx_sel_reg
                crc_en_reg = 1'b0;
                sbtx_sel_reg = 1'b0;
                disconnected_s_reg =1'b0;
            end
        end


       DLE2: begin
         crc_en_reg = 0;
			   sbtx_sel_reg = 0;
            if (symbol_count == 9) begin
                if (trans_sel_pulse == 3'b010) begin // If symbol_count is 9 and trans_sel is 2
                    ns = ETX; // Transition to ETX state
                    trans_reg = {1'b1, ETX_SYMBOL, 1'b0}; // Set trans_reg output to ETX symbol
                    crc_en_reg = 1'b0; // Disable CRC
                    sbtx_sel_reg = 1'b0; // Set sbtx_sel_reg to 0
                    disconnected_s_reg =1'b0;
                end else if (trans_sel == 3'b011) begin // If symbol_count is 9 and trans_sel is 3
                    ns = ETX; // Transition to ETX state
                    trans_reg = {1'b1, ETX_SYMBOL, 1'b0}; // Set trans_reg output to ETX symbol
                    crc_en_reg = 1'b0; // Disable CRC
                    sbtx_sel_reg = 1'b0; // Set sbtx_sel_reg to 0
                    disconnected_s_reg =1'b0;
                end 
                 else begin
                    // Stay in DLE2 state
                    ns = DLE2;
                    // Hold the current value of trans_reg output
                    trans_reg = trans_reg;
                    // Disable CRC and sbtx_sel_reg
                    crc_en_reg = 1'b0;
                    sbtx_sel_reg = 1'b0;
                    disconnected_s_reg =1'b0;
                end
                    end
                  end
        ETX: begin
            if (symbol_count == 9) begin
                if (trans_sel_pulse == 3'b010 || trans_sel == 3'b011 || trans_sel == 3'b100) begin // If symbol_count is 9 and trans_sel is 2, 3, or 4
                    ns = IDLE; // Transition to IDLE state
                    trans_reg = 10'b1111111111; // Set trans_reg output to all ones
                    crc_en_reg = 1'b0; // Disable CRC
                    sbtx_sel_reg = 1'b0; // Set sbtx_sel_reg to 0
                    disconnected_s_reg =1'b0;
                end else begin
                    // Stay in ETX state
                    ns = ETX;
                    // Hold the current value of trans_reg output
                    trans_reg = trans_reg;
                    // Disable CRC and sbtx_sel_reg
                    crc_en_reg = 1'b0;
                    sbtx_sel_reg = 1'b0;
                    disconnected_s_reg =1'b0;
                end
            end else begin
                // Stay in ETX state
                ns = ETX;
                // Hold the current value of trans_reg output
                trans_reg = trans_reg;
                // Disable CRC and sbtx_sel_reg
                crc_en_reg = 1'b0;
                sbtx_sel_reg = 1'b0;
                disconnected_s_reg =1'b0;
            end
        end
        
        CRC_LOW: begin
          sbtx_sel_reg=1;
            if (symbol_count == 9) begin
                    ns = CRC_HIGH; // Transition to CRC_HIGH state
                    trans_reg = 10'b0; // Set trans_reg output to 0
                    crc_en_reg = 1'b1; // Enable CRC
                    sbtx_sel_reg = 1'b1; // Set sbtx_sel_reg to 1
                    disconnected_s_reg =1'b0;
                end 
              end
                
                
        CRC_HIGH: begin
            if (symbol_count == 9) begin
                    ns = DLE2; // Transition to DLE2 state
                    trans_reg = {1'b1, DLE_SYMBOL, 1'b0}; // Set trans_reg output to DLE symbol
                    crc_en_reg = 1'b1; // Disable CRC
                    sbtx_sel_reg = 1'b1; // Set sbtx_sel_reg to 0
                    disconnected_s_reg =1'b0;
                end else begin
                    // Stay in CRC_HIGH state
                    ns = CRC_HIGH;
                    // Hold the current value of trans_reg output
                    trans_reg = trans_reg;
                    // Disable CRC and set sbtx_sel_reg
                    crc_en_reg = 1'b0;
                    sbtx_sel_reg = 1'b0;
                    disconnected_s_reg =1'b0;
                end
            end 
      
        // Define state transition and output logic for other states
        // ...
        default: begin
            // Default case
            ns = IDLE;
            trans_reg = 10'b1111111111;
            crc_en_reg = 1'b0;
            sbtx_sel_reg = 1'b0;
            disconnected_s_reg =1'b0;
        end
    endcase
end

        
        
// Counter logic for data_count
always @ (posedge sb_clk or negedge rst) begin
    if (!rst) begin
        data_count <= 3'b0;
    end 
    else if ((cs == DATA_WRITE_COMMAND_DATA || cs == DATA_READ_RESPONSE_DATA) && data_count!=2 && symbol_count == 9) begin
                data_count <= data_count + 1;
            end

         else if ( cs==IDLE ) begin
            data_count <= 3'b0;
        end
      else begin
      data_count <= data_count ; //hold value in other cases
    end
       
    end




// Counter logic
always @ (posedge sb_clk or negedge rst) begin
    if (!rst) begin
        symbol_count <= 4'b0;
    end else begin
        if (cs != IDLE && cs != DISCONNECT && symbol_count < 9) begin
            // Increment counter if not in IDLE or DISCONNECT state and count is less than 9
            symbol_count <= symbol_count + 1;
        end else begin
            symbol_count <= 4'b0;
        end
    end
end

always @(posedge sb_clk or negedge rst) begin
    if (!rst) begin
        trans_sel_pulse <= 3'b0;    // Initialize to zero on reset
        trans_sent <= 1'b0;         // Initialize to zero on reset
    end else if (trans_sel_pulse != 3'b000) begin
        // Hold previous value of trans_sel_pulse unless in disconnect state
            trans_sel_pulse <= trans_sel;
            trans_sent<=1'b0;
        end 

        // Determine if transaction is sent
      else if ((cs == CLSE || cs == ETX) && symbol_count == 9) begin
            trans_sent <= 1'b1;
            trans_sel_pulse<= 1'b0; // Set trans_sent when in CLSE or ETX and symbol_count = 9
        end else begin
            trans_sent <= 1'b0; // Reset trans_sent otherwise
            trans_sel_pulse <= trans_sel_pulse;
        end
    end



endmodule
