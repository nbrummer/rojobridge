// mfp_ahb.v
// 
// January 1, 2017
//
// AHB-lite bus module with 4 slaves: boot RAM, program RAM, 
// GPIO (memory-mapped I/O: switches and LEDs from the FPGA board),
// and 7-segment LED displays.
// The module includes an address decoder and multiplexer (for 
// selecting which slave module produces HRDATA).

`include "mfp_ahb_const.vh"


module mfp_ahb
(
    input                       HCLK,
    input                       HRESETn,
    input      [ 31         :0] HADDR,
    input      [  2         :0] HBURST,
    input                       HMASTLOCK,
    input      [  3         :0] HPROT,
    input      [  2         :0] HSIZE,
    input      [  1         :0] HTRANS,
    input      [ 31         :0] HWDATA,
    input                       HWRITE,
    output     [ 31         :0] HRDATA,
    output                      HREADY,
    output                      HRESP,
    input                       SI_Endian,

// memory-mapped I/O
    input      [`MFP_N_SW-1 :0] IO_Switch,
    input      [`MFP_N_PB-1 :0] IO_PB,
    output     [`MFP_N_LED-1:0] IO_LED,    
    
// Rojobot memory-mapped I/O
    output      [7            :0] IO_BotCtrl,
    output                        IO_INT_ACK,
    input       [31           :0] IO_BotInfo,
    input                         IO_BotUpdt_Sync,
	
	output      [7            :0] IO_BotCtrl_1,
    output                        IO_INT_ACK_1,
    input       [31           :0] IO_BotInfo_1,
    input                         IO_BotUpdt_Sync_1,
    
// 7-segment LEDs
    output      [`MFP_N_SEVSEG-1:0] AN,
    output                          DP,
    output      [6:0]               CATHODES
);


  wire [31:0] HRDATA4, HRDATA3, HRDATA2, HRDATA1, HRDATA0;
  wire [ 5:0] HSEL; //NEW Added an extra bit to this for the additiona 7-segment LED peripheral
  reg  [ 5:0] HSEL_d; //NEW Same as above for delayed HSEL

  assign HREADY = 1;
  assign HRESP = 0;
	
  // Delay select signal to align for reading data
  always @(posedge HCLK)
    HSEL_d <= HSEL;

  // Module 0 - boot ram
  mfp_ahb_b_ram mfp_ahb_b_ram(HCLK, HRESETn, HADDR, HBURST, HMASTLOCK, HPROT, HSIZE,
                              HTRANS, HWDATA, HWRITE, HRDATA0, HSEL[0]);
  // Module 1 - program ram
  mfp_ahb_p_ram mfp_ahb_p_ram(HCLK, HRESETn, HADDR, HBURST, HMASTLOCK, HPROT, HSIZE,
                              HTRANS, HWDATA, HWRITE, HRDATA1, HSEL[1]);
  // Module 2 - GPIO
  mfp_ahb_gpio mfp_ahb_gpio(
                            .HCLK(HCLK), 
                            .HRESETn(HRESETn), 
                            .HADDR(HADDR[5:2]), 
                            .HTRANS(HTRANS), 
                            .HWDATA(HWDATA), 
                            .HWRITE(HWRITE), 
                            .HSEL(HSEL[2]), 
                            .HRDATA(HRDATA2), 
                            .IO_Switch(IO_Switch), 
                            .IO_PB(IO_PB), 
                            .IO_LED(IO_LED)
                            );
  // Module 3 - NEW 7-segment
  mfp_ahb_sevenseg mfp_ahb_sevenseg(HCLK, HWRITE, HRESETn, HADDR, HWDATA, HSEL[3], AN, DP, CATHODES); //NEW

  mfp_ahb_rjbot mfp_ahb_rjbot
             (  .HCLK(HCLK),
                .HRESETn(HRESETn),
                .HADDR(HADDR),
                .HTRANS(HTRANS),
                .HWDATA(HWDATA),
                .HWRITE(HWRITE),
                .HSEL(HSEL[4]),
                .HRDATA(HRDATA3),
                .IO_BotInfo(IO_BotInfo),
                .IO_BotCtrl(IO_BotCtrl),
                .IO_BotUpdt_Sync(IO_BotUpdt_Sync),
                .IO_INT_ACK(IO_INT_ACK)
              );
			  
  mfp_ahb_rjbot mfp_ahb_rjbot_1
			  (  .HCLK(HCLK),
				 .HRESETn(HRESETn),
				 .HADDR(HADDR),
				 .HTRANS(HTRANS),
				 .HWDATA(HWDATA),
				 .HWRITE(HWRITE),
				 .HSEL(HSEL[5]),
				 .HRDATA(HRDATA4),
				 .IO_BotInfo(IO_BotInfo_1),
				 .IO_BotCtrl(IO_BotCtrl_1),
				 .IO_BotUpdt_Sync(IO_BotUpdt_Sync_1),
				 .IO_INT_ACK(IO_INT_ACK_1)
			   ); 		  
  
  ahb_decoder ahb_decoder(HADDR, HSEL);
  ahb_mux ahb_mux(HCLK, HSEL_d, HRDATA2, HRDATA1, HRDATA0, HRDATA);

endmodule


module ahb_decoder
(
    input  [31:0] HADDR,
    output [ 5:0] HSEL //NEW Increased width by 1 bit
);

  // Decode based on most significant bits of the address
  assign HSEL[0] = (HADDR[28:22] == `H_RAM_RESET_ADDR_Match); // 128 KB RAM  at 0xbfc00000 (physical: 0x1fc00000)
  assign HSEL[1] = (HADDR[28]    == `H_RAM_ADDR_Match);       // 256 KB RAM at 0x80000000 (physical: 0x00000000)
  assign HSEL[2] = (HADDR[28:22] == `H_LED_ADDR_Match);       // GPIO at 0xbf800000 (physical: 0x1f800000)
  assign HSEL[3] = (HADDR[28:22] == `H_SEVSEG_ADDR_MATCH);               // 7SEG at 0xbf700000 (physical: 0x1f700000)
  assign HSEL[4] = ((HADDR[31:0] == `H_IO_BOTINFO)||(HADDR[31:0] == `H_IO_BOTCTRL)||(HADDR[31:0] == `H_IO_BOTUPDT)||(HADDR[31:0] == `H_INTACK));
  assign HSEL[5] = ((HADDR[31:0] == `H_IO_BOTINFO_1)||(HADDR[31:0] == `H_IO_BOTCTRL_1)||(HADDR[31:0] == `H_IO_BOTUPDT_1)||(HADDR[31:0] == `H_INTACK_1));
endmodule


module ahb_mux //NEW Based on the block diagram I don't think this needs to change, as the 7-segment LED has no data output to MUX
			   //Although, HSEL is now 4 bits wide in other places, this could screw up the logic in this module...
(
    input             HCLK,
    input      [ 5:0] HSEL,
    input      [31:0] HRDATA4, HRDATA3, HRDATA2, HRDATA1, HRDATA0, 
    output reg [31:0] HRDATA
);

    always @(*)
      casez (HSEL)
	      6'b?????1:    HRDATA = HRDATA0;
          6'b????10:    HRDATA = HRDATA1;
          6'b???100:    HRDATA = HRDATA2;
          6'b??1000:    HRDATA = HRDATA3;
          6'b?10000:    HRDATA = HRDATA4;
	      default:   HRDATA = HRDATA1;
      endcase
endmodule

