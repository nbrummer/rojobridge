// mfp_nexys4_ddr.v
// January 1, 2017
//
// Instantiate the mipsfpga system and rename signals to
// match the GPIO, LEDs and switches on Digilent's (Xilinx)
// Nexys4 DDR board

// Outputs:
// 16 LEDs (IO_LED) 
// Inputs:
// 16 Slide switches (IO_Switch),
// 5 Pushbuttons (IO_PB): {BTNU, BTND, BTNL, BTNC, BTNR}
//

`include "mfp_ahb_const.vh"

module mfp_nexys4_ddr( 
                        input                       CLK100MHZ,
                        input                       CPU_RESETN,
                        input                       BTNU, BTND, BTNL, BTNC, BTNR, 
                        input  [`MFP_N_SW-1     :0] SW,
                        output [`MFP_N_LED-1    :0] LED,
                        output [`MFP_N_SEVSEG-1 :0] AN,
                        output                      DP,
                        output                      CA, CB, CC, CD, CE, CF, CG,
                        inout  [ 8              :1] JA,
                        inout  [ 8              :1] JB,
                        input                       UART_TXD_IN,
                        
                        //Project 2 VGA pins uncommented in constraints file.  
                        output [`MFP_N_VGA-1    :0] VGA_R,                      
                        output [`MFP_N_VGA-1    :0] VGA_G,
                        output [`MFP_N_VGA-1    :0] VGA_B,
                        output                      VGA_HS, VGA_VS
                        );
                        

  // Clocks
  wire clk_out; 
  wire clk_out75;  // Wire to plumb new 75MHz clock output for Project 2 modules
  
  wire tck_in, tck;
  wire [3:0] icon_a, icon_b, icon_w;  // Wire to plumb icon bits from icon.v to colorizer.v
  
  // Debounced buttons/switches
  wire BTNU_db, BTND_db, BTNL_db, BTNC_db, BTNR_db, CPU_RESETN_db;  //these wires will carry the debounced button press signals
  wire [`MFP_N_SW-1:0] SW_db; //NEW this bus carries the debounced switch signals
  wire reset_P; //inverted reset, already debounced
  
  // Rojobot interconnects
  wire [7          :0] IO_BotCtrl;
  wire                 IO_INT_ACK;
  wire [31         :0] IO_BotInfo;
  reg                  IO_BotUpdt_Sync;
  wire                 IO_BotUpdt;
  
  // Second rojobot interconnects
  wire  [31 :0] IO_BotInfo_1;
  wire  [7:0]   IO_BotCtrl_1;
  reg           IO_BotUpdt_Sync_1;
  wire          IO_INT_ACK_1;
  wire          IO_BotUpdt_1;
  
  // Worldmap interconnects
  wire [13         :0] worldmap_addr;
  wire [1          :0] worldmap_data;
  wire [1          :0] world_pixel;
  reg  [1          :0] world_pixel_mux;
  
  // Second rojobot world map interconnects
  wire [13 : 0] worldmap_addr_a_1;
  wire [1 : 0]  worldmap_data_a_1;
  
  // Pmod JSTK2 interconnects
  reg [6          :0] CATHODES_dummy; //dummy wire for mfp_sys to connect to
  reg [`MFP_N_SEVSEG-1 :0] AN_dummy; // dummy wire for mfp_sys to connect to
  reg                 DP_dummy;      // dummy wire for mfp_sys to connect to
  wire                 transfer;
  wire [7          :0] sndData;
  wire [39         :0] jstk_dout;
  wire [6          :0] bridge_x;
  wire [6          :0] bridge_y;  
  reg  [`MFP_N_LED-1:0] LED_dummy;
  wire [`MFP_N_LED-1:0] LED;
  wire [9          :0] posData;
  
  // Display timing generator interconnects
  wire [11         :0] pixel_row;
  wire [11         :0] pixel_column;
  wire                 video_on;
  wire [6          :0] scaled_row;
  wire [6          :0] scaled_column;
  
  // Clock wizard now has 50MHz and 75MHz clocks
  clk_wiz_0 clk_wiz_0(.clk_in1(CLK100MHZ), .clk_out1(clk_out), .clk_out2(clk_out75));
  
  IBUF IBUF1(.O(tck_in),.I(JB[4]));
  BUFG BUFG1(.O(tck), .I(tck_in));
  
  // Inverter to handle active-high resets
  assign reset_P = ~CPU_RESETN_db; 
  
  // Module to debounce physical buttons and switches on Nexys board
  debounce debounce_inst0(
					.clk(clk_out), 
					.pbtn_in({BTNU, BTND, BTNL, BTNC, BTNR, CPU_RESETN}), 
					.switch_in(SW),
					.pbtn_db({BTNU_db, BTND_db, BTNL_db, BTNC_db, BTNR_db, CPU_RESETN_db}),
					.swtch_db(SW_db)
					); 

  mfp_sys mfp_sys_inst0(
			        .SI_Reset_N(CPU_RESETN_db), // PROJ1: passing debounced Reset button press
                    .SI_ClkIn(clk_out),
                    .HADDR(),
                    .HRDATA(),
                    .HWDATA(),
                    .HWRITE(),
					.HSIZE(),
                    .EJ_TRST_N_probe(JB[7]),
                    .EJ_TDI(JB[2]),
                    .EJ_TDO(JB[3]),
                    .EJ_TMS(JB[1]),
                    .EJ_TCK(tck),
                    .SI_ColdReset_N(JB[8]),
                    .EJ_DINT(1'b0),
                    .IO_Switch(SW_db), // PROJ1: passing debounced switch signals now
                    .IO_PB({BTNC_db, BTNL_db, BTNU_db, BTNR_db, BTND_db}), // PROJ1: passing debounced button press signals now
                    .IO_LED(LED),  //DEBUG: dummy net
                    .IO_BotCtrl(IO_BotCtrl), // PROJ2: routes rojobot IO down through existing AHB GPIO module
                    .IO_INT_ACK(IO_INT_ACK), // PROJ2: routes rojobot IO down through existing AHB GPIO module
                    .IO_BotInfo(IO_BotInfo), // PROJ2: routes rojobot IO down through existing AHB GPIO module
                    .IO_BotUpdt_Sync(IO_BotUpdt_Sync), // PROJ2: routes rojobot IO down through existing AHB GPIO module
                    .IO_BotCtrl_1(IO_BotCtrl_1), // PROJ2: routes rojobot IO down through existing AHB GPIO module
                    .IO_INT_ACK_1(IO_INT_ACK_1), // PROJ2: routes rojobot IO down through existing AHB GPIO module
                    .IO_BotInfo_1(IO_BotInfo_1), // PROJ2: routes rojobot IO down through existing AHB GPIO module
                    .IO_BotUpdt_Sync_1(IO_BotUpdt_Sync_1), // PROJ2: routes rojobot IO down through existing AHB GPIO module
					.AN(AN), //DEBUG: dummy net
                    .DP(DP), //DEBUG: dummy net
                    .CATHODES({CA, CB, CC, CD, CE, CF, CG}), //DEBUG: dummy net
                    .UART_RX(UART_TXD_IN));
    
    // PROJ2: rojobot module instantiation      
    // module has active-high reset          
    rojobot31_upper_left_0 rojobot_inst_playerA (
                      .MotCtl_in(IO_BotCtrl),            // input wire [7 : 0] MotCtl_in
                      .LocX_reg(IO_BotInfo[31:24]),              // output wire [7 : 0] LocX_reg
                      .LocY_reg(IO_BotInfo[23:16]),              // output wire [7 : 0] LocY_reg
                      .Sensors_reg(IO_BotInfo[15:8]),        // output wire [7 : 0] Sensors_reg
                      .BotInfo_reg(IO_BotInfo[7:0]),        // output wire [7 : 0] BotInfo_reg
                      .worldmap_addr(worldmap_addr),    // output wire [13 : 0] worldmap_addr
                      .worldmap_data(worldmap_data),    // input wire [1 : 0] worldmap_data
                      .clk_in(clk_out75),                 //input wire clk_in
                      .reset(reset_P),                    // input wire reset
                      .upd_sysregs(IO_BotUpdt),        // output wire upd_sysregs
                      .Bot_Config_reg(SW_db[7:0])  // input wire [7 : 0] Bot_Config_reg
                    );
	
// Second player's rojobot	
	rojobot31_lower_left_0 rojobot_inst_playerB (
                      .MotCtl_in(IO_BotCtrl_1),            // input wire [7 : 0] MotCtl_in
                      .LocX_reg(IO_BotInfo_1[31:24]),              // output wire [7 : 0] LocX_reg
                      .LocY_reg(IO_BotInfo_1[23:16]),              // output wire [7 : 0] LocY_reg
                      .Sensors_reg(IO_BotInfo_1[15:8]),        // output wire [7 : 0] Sensors_reg
                      .BotInfo_reg(IO_BotInfo_1[7:0]),        // output wire [7 : 0] BotInfo_reg
                      .worldmap_addr(worldmap_addr_a_1),    // output wire [13 : 0] worldmap_addr
                      .worldmap_data(worldmap_data_a_1),    // input wire [1 : 0] worldmap_data
                      .clk_in(clk_out75),                 //input wire clk_in
                      .reset(reset_P),                    // input wire reset
                      .upd_sysregs(IO_BotUpdt_1),        // output wire upd_sysregs
                      .Bot_Config_reg(SW_db[7:0])  // input wire [7 : 0] Bot_Config_reg
                    );
    
    // PROJ2: scales 128 x 128 world map grid to 1024 x 768 VGA display
    scaler scaler_inst0(
                      .pixel_column(pixel_column),
                      .pixel_row(pixel_row),
                      .scaled_column(scaled_column),
                      .scaled_row(scaled_row)
                      );
    
    // PROJ2: world map instantiation for rojobot_A                            
    world_map world_map_inst0(
                      .clka(clk_out75),
                      .clkb(clk_out75), 
                      .addra(worldmap_addr),
                      .addrb({scaled_row, scaled_column}),
                      .douta(worldmap_data),
                      .doutb(world_pixel)
                    );
                    
    // PROJ2: world map instantiation for rojobot_A                            
    world_map world_map_inst1(
                      .clka(clk_out75),
                      .clkb(clk_out75), 
                      .addra(worldmap_addr_a_1),
                      .addrb({scaled_row, scaled_column}),
                      .douta(worldmap_data_a_1)
                      //.doutb() // not currently being used
                    );
    
    // PROJ2: VGA display timing generator instantiation
    // module has active-high reset
    dtg dtg_inst0 (
                      .clock(clk_out75), 
                      .rst(reset_P),
                      .horiz_sync(VGA_HS), 
                      .vert_sync(VGA_VS), 
                      .video_on(video_on),        
                      .pixel_row(pixel_row), 
                      .pixel_column(pixel_column)
                      );
    
    // FINAL PROJECT: Pmod JSTK2 5Hz sig gen
    ClkDiv_5Hz jstkSigGen_inst0(
                      .CLK(CLK100MHZ),		// 100MHz onbaord clock
                      .RST(reset_P),      // Reset
                      .CLKOUT(transfer)
                      );
    
    // FINAL PROJECT: Pmod JSTK2 interface
    PmodJSTK joystick_inst0(
                      .CLK(clk_out),
                      .RST(reset_P),
                      .sndRec(transfer),
                      .DIN(sndData),
                      .MISO(JA[3]),
                      .SS(JA[1]),
                      .SCLK(JA[4]),
                      .MOSI(JA[2]),
                      .DOUT(jstk_dout)
                      );
    
    
//    ssdCtrl DispCtrl(
//                      .CLK(CLK100MHZ),
//                      .RST(reset_P),
//                      .DIN(posData),
//                      .AN(AN),
//                      .SEG({CG, CF, CE, CD, CC, CB, CA})
//              );
    
    // FINAL PROJECT: Pmod JSTK2 data decoder
    jstk_decoder decoder_inst0(
                      .clock(clk_out),
                      .reset_n(CPU_RESETN_db),
                      .jstk_x({jstk_dout[25:24],jstk_dout[39:32]}),
                      .jstk_y({jstk_dout[9:8],jstk_dout[23:16]}),
                      .pixel_x(bridge_x),
                      .pixel_y(bridge_y)
                      );
    
    // PROJ2: display colorizer instantiation                 
    colorizer colorizer_inst0(
                      .clock(clk_out75),
                      .reset_n(CPU_RESETN_db),
                      .video_on(video_on),
                      .world_pixel(world_pixel_mux),
                      .icon(icon_w),
                      .VGA({VGA_R, VGA_G, VGA_B})
                      );
    
    // PROJ2: rojobot icon lookup instantiation                 
    icon_tort icon_inst_playerA(
                      .clock(clk_out75),
                      .reset_n(CPU_RESETN_db),
                      .pixel_row(pixel_row),
                      .pixel_column(pixel_column),
                      .BotInfo_reg(IO_BotInfo),
                      .LocX_reg(IO_BotInfo[31:24]),
                      .LocY_reg(IO_BotInfo[23:16]),
                      .icon(icon_a)
                      );
					  
	icon_hare icon_inst_playerB(
                      .clock(clk_out75),
                      .reset_n(CPU_RESETN_db),
                      .pixel_row(pixel_row),
                      .pixel_column(pixel_column),
                      .BotInfo_reg(IO_BotInfo_1),
                      .LocX_reg(IO_BotInfo_1[31:24]),
                      .LocY_reg(IO_BotInfo_1[23:16]),
                      .icon(icon_b)
                      );
                      
// Icons assumed to never be occupying the same space
assign icon_w = icon_a | icon_b;

// Use state of switch 0 to select output of X position or Y position data to SSD
//assign posData = (SW[0] == 1'b1) ? {jstk_dout[9:8], jstk_dout[23:16]} : {jstk_dout[25:24], jstk_dout[39:32]};

// Data to be sent to PmodJSTK, lower two bits will turn on leds on PmodJSTK
//assign sndData = {8'b100000, {SW[1], SW[2]}};

// Assign PmodJSTK button status to LED[2:0]
//always @(transfer or reset_P or jstk_dout) begin
//      if(reset_P == 1'b1) begin
//              LED_dummy <= 3'b000;
//      end
//      else begin
//              LED_dummy <= {jstk_dout[1], {jstk_dout[2], jstk_dout[0]}};
//      end
//end

// MUX for worldmap vs. bridge pixel
always @ (posedge clk_out) begin
    if ({bridge_x, bridge_y} == {scaled_column, scaled_row}) begin
        world_pixel_mux <= 2'b01; // User scaled DTG is at the bridge; make pixel color black
    end
    else begin
        world_pixel_mux <= world_pixel; // DTG is not at the bridge; use world_map value
    end
end
                      
// Handshake Flip-Flop Instantiation; uses 50MHz Clock            
always @ (posedge clk_out) begin
    if (IO_INT_ACK == 1'b1) begin
        IO_BotUpdt_Sync <= 1'b0;
    end
    else if (IO_BotUpdt == 1'b1) begin
        IO_BotUpdt_Sync <= 1'b1;
    end 
    else begin
        IO_BotUpdt_Sync <= IO_BotUpdt_Sync;
    end
end // always     

// Handshake Flip-Flop Instantiation; uses 50MHz Clock            
always @ (posedge clk_out) begin
    if (IO_INT_ACK_1 == 1'b1) begin
        IO_BotUpdt_Sync_1 <= 1'b0;
    end
    else if (IO_BotUpdt_1 == 1'b1) begin
        IO_BotUpdt_Sync_1 <= 1'b1;
    end 
    else begin
        IO_BotUpdt_Sync_1 <= IO_BotUpdt_Sync_1;
    end
end // always 
          
endmodule


