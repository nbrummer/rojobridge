// mfp_ahb_gpio.v
//
// General-purpose I/O module for Altera's DE2-115 and 
// Digilent's (Xilinx) Nexys4-DDR board


`include "mfp_ahb_const.vh"

module mfp_ahb_sevenseg(
    input                        HCLK,
	input                        HWRITE,
	input						 HRESETn,
    input      [ 31          :0] HADDR,
    input      [ 31          :0] HWDATA, //NEW AND VERY MUCH INCOMPLETE, RAN OUT OF TIME TONIGHT
    input                        HSEL,
	output 	[`MFP_N_SEVSEG-1:0]  AN,
	output						 DP,
	output  [6:0]                CATHODES
);

// Commenting out the lines below; don't think they are needed
// memory-mapped I/O
//    input      [`MFP_N_SW-1  :0] IO_Switch,
//   input      [`MFP_N_PB-1  :0] IO_PB,
//    output reg [`MFP_N_LED-1 :0] IO_LED
//);

  reg  [31:0]  HADDR_d;
  reg         HWRITE_d;
  reg         HSEL_d;
  wire        we;            // write enable
  reg  [`MFP_N_SEVSEG-1:0]  SEVSEG_ENABLE;
  reg  [`MFP_N_SEVSEG-1:0]  SEVSEG_DP;
  reg  [63:0]               SEVSEG_DIGITS;
  reg  [31:0]			    SEVSEG_DIGITS_L;
  reg  [31:0]   			SEVSEG_DIGITS_H;

  // delay HADDR, HWRITE, HSEL to align with HWDATA for writing
  always @ (posedge HCLK) 
  begin
    HADDR_d  <= HADDR;
	HWRITE_d <= HWRITE;
	HSEL_d   <= HSEL;
  end
  
  // overall write enable signal  DO WE NEED THIS?  HTRANS NOT SPECIFIED IN THE PROJECT DOCUMENT!
  //assign we = (HTRANS_d != `HTRANS_IDLE) & HSEL_d & HWRITE_d;

mfp_ahb_sevensegtimer mfp_ahb_sevensegtimer(
                                            .clk(HCLK), 
                                            .resetn(HRESETn), 
                                            .EN(SEVSEG_ENABLE), 
                                            .DIGITS(SEVSEG_DIGITS), 
                                            .dp(SEVSEG_DP), 
                                            .DISPENOUT(AN), 
                                            .DISPOUT({DP,CATHODES})
                                            );
                                            
    always @(posedge HCLK)
    begin
       case (HADDR_d)
       
//        `H_SEVSEG_EN_ADDR: 
//        begin
//           SEVSEG_ENABLE <= HWDATA[`MFP_N_SEVSEG-1:0];
//           SEVSEG_DIGITS_H <= HWDATA[31:0];
//           SEVSEG_DIGITS_L <= HWDATA[31-1:0];
//           SEVSEG_DP <= HWDATA[`MFP_N_SEVSEG-1:0];
//        end
        `H_SEVSEG_EN_ADDR: SEVSEG_ENABLE <= HWDATA[`MFP_N_SEVSEG-1:0];         
		`H_SEVSEG_VAL_7_4_ADDR: SEVSEG_DIGITS_H <= HWDATA[31:0];
		`H_SEVSEG_VAL_3_0_ADDR: SEVSEG_DIGITS_L <= HWDATA[31-1:0];
		`H_SEVSEG_DEC_ADDR:	SEVSEG_DP <= HWDATA[`MFP_N_SEVSEG-1:0];
	   endcase
		
		SEVSEG_DIGITS <= {SEVSEG_DIGITS_H,SEVSEG_DIGITS_L};
	end
       
       
       
       
     
        
    
//	always @(posedge HCLK or negedge HRESETn)
//       if (~HRESETn)
//         HRDATA <= 32'h0;
//       else
//	     case (HADDR)
//           `H_SW_IONUM: HRDATA <= { {32 - `MFP_N_SW {1'b0}}, IO_Switch };
//           `H_PB_IONUM: HRDATA <= { {32 - `MFP_N_PB {1'b0}}, IO_PB };
//            default:    HRDATA <= 32'h00000000;
//         endcase
		 
endmodule

