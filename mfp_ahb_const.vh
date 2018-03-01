// 
// mfp_ahb_const.vh
//
// Verilog include file with AHB definitions
// 

//---------------------------------------------------
// Physical bit-width of memory-mapped I/O interfaces
//---------------------------------------------------
`define MFP_N_LED             16
`define MFP_N_SW              16
`define MFP_N_PB              5
`define MFP_N_SEVSEG	      8
`define MFP_N_BOTCTRL         8
`define MFP_N_INTACK          1
`define MFP_N_VGA             4
`define MFP_N_VGAC            12

//---------------------------------------------------
// Memory-mapped I/O addresses
//---------------------------------------------------
`define H_LED_ADDR    			(32'h1f800000)
//`define H_LED_ADDR              (32'h1f800014) //DEBUG; remove when done
`define H_SW_ADDR   			(32'h1f800004)
`define H_PB_ADDR   			(32'h1f800008)

`define H_IO_BOTINFO            (32'h1f80000C) //Rojobot IO_BotInfo
//`define H_IO_BOTINFO            (32'h1f800000) //DEBUG Rojobot IO_BotInfo
`define H_IO_BOTCTRL            (32'h1f800010) //Rojobot IO_BotCtrl
//`define H_IO_BOTCTRL            (32'h1f800000) //DEBUG Rojobot IO_BotCtrl
`define H_IO_BOTUPDT            (32'h1f800014) //Rojobot IO_BotUpdt_Sync
//`define H_IO_BOTUPDT            (32'h1f800000) //DEBUG Rojobot IO_BotUpdt_Sync
`define H_INTACK                (32'h1f800018) //Rojobot IO_INT_ACK
//`define H_INTACK                (32'h1f800000) //DEBUG Rojobot IO_INT_ACK

`define H_SEVSEG_EN_ADDR		(32'h1f700000) //NEW
`define H_SEVSEG_VAL_7_4_ADDR	(32'h1f700004) //NEW I don't think we need these addresses for Project 1 but may as well put them in now
`define H_SEVSEG_VAL_3_0_ADDR	(32'h1f700008) //NEW
`define H_SEVSEG_DEC_ADDR		(32'h1f70000C) //NEW

`define H_LED_IONUM   			(4'h0) //DEBUG: set to 0 when done
`define H_SW_IONUM  			(4'h1)
`define H_PB_IONUM  			(4'h2)
`define H_BOTINFO_IONUM         (4'h3) //NEW FOR PROJECT 2 
`define H_BOTCTRL_IONUM         (4'h4) //NEW FOR PROJECT 2 
`define H_BOTUPDSYNC_IONUM      (4'h5) //NEW FOR PROJECT 2 DEBUG: set to 5 when done!
`define H_BOTINTACK_IONUM       (4'h6) //NEW FOR PROJECT 2 

//---------------------------------------------------
// RAM addresses
//---------------------------------------------------
`define H_RAM_RESET_ADDR 		(32'h1fc?????)
`define H_RAM_ADDR	 		    (32'h0???????)
`define H_RAM_RESET_ADDR_WIDTH  (8) 
`define H_RAM_ADDR_WIDTH		(16) 

`define H_RAM_RESET_ADDR_Match  (7'h7f)
`define H_RAM_ADDR_Match 		(1'b0)
`define H_LED_ADDR_Match		(7'h7e)
`define H_SEVSEG_ADDR_MATCH		(7'h7d)  //NEW address bytes for comparing in address decoder

//---------------------------------------------------
// AHB-Lite values used by MIPSfpga core
//---------------------------------------------------

`define HTRANS_IDLE    2'b00
`define HTRANS_NONSEQ  2'b10
`define HTRANS_SEQ     2'b11

`define HBURST_SINGLE  3'b000
`define HBURST_WRAP4   3'b010

`define HSIZE_1        3'b000
`define HSIZE_2        3'b001
`define HSIZE_4        3'b010
