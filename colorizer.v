//	colorizer.v - VGA color assigner for ECE 540 Project 2
//	
//	Version:		1.0	
//	Author:			Noah Brummer
//	Last Modified:	10-Feb-2018
//	
//	 Revision History
//	 ----------------
//	 10-Feb-18		Created
//
//	Description:
//	------------
//	 Programs color codes for the 3 VGA color bytes 
//	
//	 Inputs:
//			video_on        
//			world_pixel     
//          icon
//	 Outputs:
//			VGA_R
//			VGA_G
//			VGA_B
//						
//////////

`include "mfp_ahb_const.vh"

module colorizer(
    input                               clock, reset_n,
    input                               video_on,
    input       [1:0]                   world_pixel,
    input       [1:0]                   icon,
    output  reg [`MFP_N_VGA*3-1:0]      VGA
    );
    
    parameter  // variable names for case statement
        BACKGROUND      = 4'b0000, 
        BLACKLINE       = 4'b0100,
        OBSTRUCTION     = 4'b1000, 
        RESERVED        = 4'b1100,
        ICON_1          = 4'bxx01, 
        ICON_2          = 4'bxx10, 
        ICON_3          = 4'bxx11; 
        
    always @(posedge clock) begin
    
        // Handles active low reset OR video_on == 0 => set all colors to 0x00
        if (~reset_n | ~video_on) begin
            VGA <= 12'h000;
        end
        
        else
        casex({world_pixel, icon}) 
            BACKGROUND:     VGA <= 12'hBBB; // grey
            BLACKLINE:      VGA <= 12'h000; // black
            OBSTRUCTION:    VGA <= 12'hF51; // orange
            RESERVED:       VGA <= 12'hFFF; // white
            ICON_1:         VGA <= 12'h000; // black
            ICON_2:         VGA <= 12'hF00; // red
            ICON_3:         VGA <= 12'hFFE; // eggshell white
            default:        VGA <= 12'h000; // black
        endcase
    end //endalways
 endmodule
        