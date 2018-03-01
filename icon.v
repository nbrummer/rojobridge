//	icon.v - Icon bitmap programmer
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
//	 Compares DTG location with rojobot location to determine appropriate bitmap assignment.  
//   Different orientations are handled by loading different arrays of register values from
//   text files into ROMs.  Symmetric orientations handled by reading in values starting with
//   either MSB or LSB first.
//	
//	 Inputs:
//          clock
//          reset_n
//			pixel_row        
//			pixel_column     
//          BotInfo_reg
//          LocX_reg
//          LocY_reg
//	 Outputs:
//			icon
//						
//////////

`include "mfp_ahb_const.vh"

module icon(
    input               clock,
    input               reset_n,
    input      [11:0]   pixel_row,
    input      [11:0]   pixel_column,
    input       [7:0]   BotInfo_reg,
    input       [7:0]   LocX_reg,
    input       [7:0]   LocY_reg,
    output  reg [1:0]   icon
    );
    
    // Dynamically updating the pointers to memory locations handled by the following wires and
    // combinational logic
    wire [11:0]         hiresX;     
    wire [11:0]         hiresY;
    wire [12:0]         hires2X;
    wire [12:0]         hiresoffset;
    
    // ROMS for the orientation-specific icon
    reg  [0:31]         iconmemEast[0:15];
	reg  [31:0]			iconmemWest[0:15];
	reg  [0:31]			iconmemNorthEast[0:15];
	reg	 [31:0]		    iconmemNorthWest[0:15];
	reg  [0:31]			iconmemNorth[0:15];
	reg  [0:31]			iconmemSouth[0:15];
	reg  [31:0]			iconmemSouthEast[0:15];
	reg  [0:31]			iconmemSouthWest[0:15];
    
    
    parameter
        NORTH       = 3'b000,
        NORTHEAST   = 3'b001,
        EAST        = 3'b010,
        SOUTHEAST   = 3'b011,
        SOUTH       = 3'b100,
        SOUTHWEST   = 3'b101,
        WEST        = 3'b110,
        NORTHWEST   = 3'b111;
     
    // text files for icons read below   
    initial begin
        $readmemb("C:/Users/fabuf/OneDrive/Documents/School/ECE_540/project2/rtl_up/hdl_part2/chickenBot.txt", iconmemEast);
		$readmemb("C:/Users/fabuf/OneDrive/Documents/School/ECE_540/project2/rtl_up/hdl_part2/chickenBot.txt", iconmemWest);
		$readmemb("C:/Users/fabuf/OneDrive/Documents/School/ECE_540/project2/rtl_up/hdl_part2/chickenBotNE.txt", iconmemNorthEast);
		$readmemb("C:/Users/fabuf/OneDrive/Documents/School/ECE_540/project2/rtl_up/hdl_part2/chickenBotNE.txt", iconmemNorthWest);
		$readmemb("C:/Users/fabuf/OneDrive/Documents/School/ECE_540/project2/rtl_up/hdl_part2/chickenBotN.txt", iconmemNorth);
		$readmemb("C:/Users/fabuf/OneDrive/Documents/School/ECE_540/project2/rtl_up/hdl_part2/chickenBotS.txt", iconmemSouth);
		$readmemb("C:/Users/fabuf/OneDrive/Documents/School/ECE_540/project2/rtl_up/hdl_part2/chickenBotSW.txt", iconmemSouthEast);
		$readmemb("C:/Users/fabuf/OneDrive/Documents/School/ECE_540/project2/rtl_up/hdl_part2/chickenBotSW.txt", iconmemSouthWest);
    end
    
    // Combinational logic for translating DTG counters to rojobot location-relative counters
    
    assign hiresX = pixel_column - LocX_reg * 8 + 8;
    assign hiresY = pixel_row    - LocY_reg * 6 + 8;
    assign hires2X = hiresX * 2;
    assign hiresoffset = hires2X + 1;
    
         
    always @(posedge clock) begin
        // Make icon transparent on reset
        if (~reset_n) begin
            icon <= 2'b0;
        end
        
        // Comparator to determine when DTG is scanning the rojobot's location
        if (hiresY >=0 && hiresY < 16) begin
            if (hiresX >= 0 && hiresX < 16) begin
                case(BotInfo_reg[2:0])
					NORTH: 		icon <= {iconmemNorth[hiresY][hiresoffset],iconmemNorth[hiresY][hires2X]};
					NORTHEAST:	icon <= {iconmemNorthEast[hiresY][hiresoffset],iconmemNorthEast[hiresY][hires2X]};
					EAST:		icon <= {iconmemEast[hiresY][hiresoffset],iconmemEast[hiresY][hires2X]};
					SOUTHEAST:	icon <= {iconmemSouthEast[hiresY][hiresoffset],iconmemSouthEast[hiresY][hires2X]};
					SOUTH:		icon <= {iconmemSouth[hiresY][hiresoffset],iconmemSouth[hiresY][hires2X]};
					SOUTHWEST:	icon <= {iconmemSouthWest[hiresY][hiresoffset],iconmemSouthWest[hiresY][hires2X]};
					WEST:		icon <= {iconmemWest[hiresY][hiresoffset],iconmemWest[hiresY][hires2X]};
					NORTHWEST:	icon <= {iconmemNorthWest[hiresY][hiresoffset],iconmemNorthWest[hiresY][hires2X]};
					default:    icon <= 2'b0;
				endcase
				
            end
            else
                icon <= 2'b0;
        end
        
        // icon is transparent for the majority of the world map grid    
        else begin
            icon <= 2'b0;
        end
    end   
    
endmodule