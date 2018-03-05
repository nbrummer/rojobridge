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
    input       [3:0]                   icon,
    output  reg [`MFP_N_VGA*3-1:0]      VGA
    );
    
    parameter  
        // variable names for case statement
        BACKGROUND      = 6'b000000, 
        BLACKLINE       = 6'b010000,
        OBSTRUCTION     = 6'b100000, 
        RESERVED        = 6'b110000,
        ICON_1          = 6'bxx0001, 
        ICON_2          = 6'bxx0010, 
        ICON_3          = 6'bxx0011,
        ICON_4          = 6'bxx0100,
        ICON_5          = 6'bxx0101,
        ICON_6          = 6'bxx0110,
        ICON_7          = 6'bxx0111, 
        
        // color selections
        BLACK           = 12'h000,
        WHITE           = 12'hFFF,
        RED             = 12'hF00,
        BLUE            = 12'h0F0,
        GREEN           = 12'h00F,
        GREY            = 12'hBBB,        
        ORANGE          = 12'hF51,
        PURPLE          = 12'hE07, //R=223, G=7, B=114
        YELLOW          = 12'hBF0, //R=175, G=255, B=0
        EGGSHELL        = 12'hFFE,
        DARK_GREY       = 12'h444,
        BROWN           = 12'h3A6;
                        
    always @(posedge clock) begin
    
        // Handles active low reset OR video_on == 0 => set all colors to 0x00
        if (~reset_n | ~video_on) begin
            VGA <= 12'h000;
        end
        
        else
        casex({world_pixel, icon}) 
            BACKGROUND:     VGA <= GREY; 
            BLACKLINE:      VGA <= BLACK; 
            OBSTRUCTION:    VGA <= ORANGE; 
            RESERVED:       VGA <= WHITE; 
            ICON_1:         VGA <= BLACK;
            ICON_2:         VGA <= GREEN; 
            ICON_3:         VGA <= RED; 
            ICON_4:         VGA <= BROWN;
            ICON_5:         VGA <= ORANGE;
            ICON_6:         VGA <= DARK_GREY;
            default:        VGA <= BLACK; // black
        endcase
    end //endalways
 endmodule
        