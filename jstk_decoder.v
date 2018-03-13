//	jstk_decoder.v - Decoder to move rojobridge pixel with Pmod JSTK2
//	
//	Version:		1.0	
//	Author:			Noah Brummer
//	Last Modified:	8-March-2018
//	
//	 Revision History
//	 ----------------
//	 8-March-2018		Created
//
//	Description:
//	------------
//	 Takes 10-bit x and y data from the JSTK2 and converts them into movement for the
//	 Rojobridge pixel on a 128 x 128 worldmap grid
//	
//	 Inputs:
//          clock
//          reset_n
//			jstk_x        
//			jstk_y   
//	 Outputs:
//			pixel_x
//			pixel_y
//						
//////////

`include "mfp_ahb_const.vh"

module jstk_decoder(
    input               clock,
    input               reset_n,
    input       [9:0]   jstk_x,
    input       [9:0]   jstk_y,
	output		[6:0]   pixel_x, 
    output      [6:0]   pixel_y
    );

    reg        [33:0]   x_counter;
	reg        [33:0]   y_counter;
	
    parameter 	x_nom = 10'd512, // nominal x-position when joystick is neutral
			    y_nom = 10'd512, // nominal y-position when joystick is neutral
			    delta = 10'd100, // threshold for joystick biasing; same for x and y axis
			    count_delta = 18, // value to increment/decrement counter
			
			    // dead-reckoned threshold values for movement
			    mov_r = x_nom + delta, 
				mov_l = x_nom - delta, 
				mov_u = y_nom - delta, 
				mov_d = y_nom + delta, 
				
				// 128-pixel world map start location, shifted up to counter init value
				x_start = 7'd1 << 27, 
				y_start = 7'd1 << 27; 
			
	// We take only the 7 MSB from the counter so that the pixel will update roughly 1 pixel/second
	assign pixel_x = x_counter[33:27];
	assign pixel_y = y_counter[33:27];
	
	always @(posedge clock or negedge reset_n)
	begin        
		if (~reset_n)
		    x_counter <= x_start;
		else if (jstk_x > mov_r)
			x_counter <= x_counter + count_delta;
		else if (jstk_x < mov_l)
			x_counter <= x_counter - count_delta;			
	end
	
	// Y movement seems reversed because DTG scans from top down as row number increases
	always @(posedge clock or negedge reset_n)
	begin
		if (~reset_n)
		    y_counter <= y_start;
		else if (jstk_y > mov_d)
			y_counter <= y_counter - count_delta;
		else if (jstk_y < mov_u)
			y_counter <= y_counter + count_delta;
	end
	
endmodule