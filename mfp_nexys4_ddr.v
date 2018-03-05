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
  wire [3:0] icon_w;  // Wire to plumb icon bits from icon.v to colorizer.v
  
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
  
  // Worldmap interconnects
  wire [13         :0] worldmap_addr;
  wire [1          :0] worldmap_data;
  wire [1          :0] world_pixel;
  
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
                    .IO_LED(LED),
                    .IO_BotCtrl(IO_BotCtrl), // PROJ2: routes rojobot IO down through existing AHB GPIO module
                    .IO_INT_ACK(IO_INT_ACK), // PROJ2: routes rojobot IO down through existing AHB GPIO module
                    .IO_BotInfo(IO_BotInfo), // PROJ2: routes rojobot IO down through existing AHB GPIO module
                    .IO_BotUpdt_Sync(IO_BotUpdt_Sync), // PROJ2: routes rojobot IO down through existing AHB GPIO module
                    .AN(AN),
                    .DP(DP),
                    .CATHODES({CA, CB, CC, CD, CE, CF, CG}),
                    .UART_RX(UART_TXD_IN));
    
    // PROJ2: rojobot module instantiation      
    // module has active-high reset          
    rojobot31_0 rojobot_inst_playerA (
                      .MotCtl_in(IO_BotCtrl),            // input wire [7 : 0] MotCtl_in
                      .LocX_reg(IO_BotInfo[31:24]),              // output wire [7 : 0] LocX_reg
                      .LocY_reg(IO_BotInfo[23:16]),              // output wire [7 : 0] LocY_reg
                      .Sensors_reg(IO_BotInfo[15:8]),        // output wire [7 : 0] Sensors_reg
                      .BotInfo_reg(IO_BotInfo[7:0]),        // output wire [7 : 0] BotInfo_reg
                      //.worldmap_addr(worldmap_addr),    // output wire [13 : 0] worldmap_addr
                      .worldmap_data(worldmap_data),    // input wire [1 : 0] worldmap_data
                      .clk_in(clk_out75),                 //input wire clk_in
                      .reset(reset_P),                    // input wire reset
                      .upd_sysregs(IO_BotUpdt),        // output wire upd_sysregs
                      .Bot_Config_reg(SW_db[7:0])  // input wire [7 : 0] Bot_Config_reg
                    );
    
    // PROJ2: scales 128 x 128 world map grid to 1024 x 768 VGA display
    scaler scaler_inst0(
                      .pixel_column(pixel_column),
                      .pixel_row(pixel_row),
                      .scaled_column(scaled_column),
                      .scaled_row(scaled_row)
                      );
    
    // PROJ2: world map instantiation                              
    world_map world_map_inst0(
                      .clka(clk_out75),
                      .clkb(clk_out75), 
                      //.addra(worldmap_addr),
                      .addrb({scaled_row, scaled_column}),
                      .douta(worldmap_data),
                      .doutb(world_pixel)
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
    
    // PROJ2: display colorizer instantiation                 
    colorizer colorizer_inst0(
                      .clock(clk_out75),
                      .reset_n(CPU_RESETN_db),
                      .video_on(video_on),
                      .world_pixel(world_pixel),
                      .icon(icon_w),
                      .VGA({VGA_R, VGA_G, VGA_B})
                      );
    
    // PROJ2: rojobot icon lookup instantiation                 
    icon icon_inst_playerA(
                      .clock(clk_out75),
                      .botNum(1'b0),
                      .reset_n(CPU_RESETN_db),
                      .pixel_row(pixel_row),
                      .pixel_column(pixel_column),
                      .BotInfo_reg(IO_BotInfo),
                      .LocX_reg(IO_BotInfo[31:24]),
                      .LocY_reg(IO_BotInfo[23:16]),
                      .icon(icon_w)
                      );
                      
                      
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
          
endmodule


