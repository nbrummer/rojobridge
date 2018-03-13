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

module icon_tort(
    input               clock,
    input               reset_n,
    input      [11:0]   pixel_row,
    input      [11:0]   pixel_column,
    input       [7:0]   BotInfo_reg,
    input       [7:0]   LocX_reg,
    input       [7:0]   LocY_reg,
    output  reg [3:0]   icon
    );
    
    // Dynamically updating the pointers to memory locations handled by the following wires and
    // combinational logic
    wire [11:0]         hiresX;     
    wire [11:0]         hiresY;
    wire [12:0]         hiresNX;
//    wire [12:0]         hiresoffset;
    
    // ROMS for the orientation-specific icon
    reg  [0:63]         iconmemEast[0:15];
	reg  [0:63]			iconmemWest[0:15];
//	reg  [0:31]			iconmemNorthEast[0:15];
//	reg	 [31:0]		    iconmemNorthWest[0:15];
	reg  [0:63]			iconmemNorth[0:15];
	reg  [0:63]			iconmemSouth[0:15];
//	reg  [31:0]			iconmemSouthEast[0:15];
//	reg  [0:31]			iconmemSouthWest[0:15];
    
    
    parameter
        NORTH       = 3'b000,
        NORTHEAST   = 3'b001,
        EAST        = 3'b010,
        SOUTHEAST   = 3'b011,
        SOUTH       = 3'b100,
        SOUTHWEST   = 3'b101,
        WEST        = 3'b110,
        NORTHWEST   = 3'b111,
		
		scale       = 4; // offset value for indexing proper number of bits from icon memory
		
     
    // text files for icons read below   
    initial begin
        $readmemb("C:/Users/fabuf/OneDrive/Documents/School/ECE_540/project_final/rojobridge/icons/tortoiseEast.txt", iconmemEast);
		$readmemb("C:/Users/fabuf/OneDrive/Documents/School/ECE_540/project_final/rojobridge/icons/tortoiseWest.txt", iconmemWest);
		$readmemb("C:/Users/fabuf/OneDrive/Documents/School/ECE_540/project_final/rojobridge/icons/tortoiseNorth.txt", iconmemNorth);
		$readmemb("C:/Users/fabuf/OneDrive/Documents/School/ECE_540/project_final/rojobridge/icons/tortoiseSouth.txt", iconmemSouth);
		
    end
    
    // Combinational logic for translating DTG counters to rojobot location-relative counters
    
    assign hiresX = pixel_column - LocX_reg * 8 + 8;
    assign hiresY = pixel_row    - LocY_reg * 6 + 8;
    assign hiresNX = hiresX * scale;
//    assign hiresoffset = hiresNX + 1;
    
         
    always @(posedge clock) begin
        // Make icon transparent on reset
        if (~reset_n) begin
            icon <= 4'b0;
        end
        
        // Comparator to determine when DTG is scanning the rojobot's location
        if (hiresY >=0 && hiresY < 16) begin
            if (hiresX >= 0 && hiresX < 16) begin
                case(BotInfo_reg[2:0])
                    NORTH: 		icon <= iconmemNorth[hiresY][hiresNX +: scale];
//        					NORTHEAST:	icon <= {iconmemNorthEast[hiresY][hiresoffset],iconmemNorthEast[hiresY][hiresNX]};
                    EAST:		icon <= iconmemEast[hiresY][hiresNX +: scale];
//        					SOUTHEAST:	icon <= {iconmemSouthEast[hiresY][hiresoffset],iconmemSouthEast[hiresY][hiresNX]};
                    SOUTH:		icon <= iconmemSouth[hiresY][hiresNX +: scale];
//        					SOUTHWEST:	icon <= {iconmemSouthWest[hiresY][hiresoffset],iconmemSouthWest[hiresY][hiresNX]};
                    WEST:		icon <= iconmemWest[hiresY][hiresNX +: scale];
//        					NORTHWEST:	icon <= {iconmemNorthWest[hiresY][hiresoffset],iconmemNorthWest[hiresY][hiresNX]};
                    default:    icon <= 4'b0;
                endcase
            end
            else
                icon <= 4'b0;
        end
        
        // icon is transparent for the majority of the world map grid    
        else begin
            icon <= 4'b0;
        end
    end   
    
endmodule