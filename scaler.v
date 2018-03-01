//	scaler.v - Scales the output of the DTG block down so that a 128 x 128 grid fits into a 768 x 768 screen
//	
//	Version:		1.0	
//	Author:			Noah Brummer
//	Last Modified:	11-Feb-2018
//	
//	 Revision History
//	 ----------------
//	 10-Feb-18		Created
//
//	Description:
//	------------
//	 Combinational logic to scale the DTG output for the world map input.
//   Arithmetic divide operation is difficult to synthesize, so an approximation is done
//   by integer multiplication and a shift-right operation.
//	
//	 Inputs:
//			pixel_column
//          pixel_row
//	 Outputs:
//			scaled_column
//          scaled_row
//////////

`include "mfp_ahb_const.vh"

module scaler(
    input       [11:0]                  pixel_column,
    input       [11:0]                  pixel_row,
    output      [6:0]                   scaled_column,
    output      [6:0]                   scaled_row
    );
    
    wire [11:0] temp_column; 
    wire [21:0] temp_row;
    
    // Division by 6 is done using an approximation of 1/6 which has a power-of-2 denominator
    // This was done to preempt any issues the synthesizer may have with an arithmetic divide-by-6
    // Approximation chosen was 171/1024 = 1.6699.  Error is 0.03% of 1/6.
    parameter
        SCALE_NUMERATOR   = 171, // Multiply by 171
        R_SHIFT_VALUE     = 10, // Divide by 1024
        C_SHIFT_VALUE     = 3; // Scale 128 to by dividing by 8 1024       
       
    assign temp_column = pixel_column  >> C_SHIFT_VALUE;
    assign temp_row = (pixel_row * SCALE_NUMERATOR) >> R_SHIFT_VALUE;
    assign scaled_column = temp_column[6:0];
    assign scaled_row = temp_row[6:0];
    
 endmodule    