`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/23 22:43:45
// Design Name: 
// Module Name: Music
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Music(input clk, input wire[4:0] mode, output reg[0:0] music = 0);

parameter do_low = 191110;
parameter re_low = 170259;
parameter me_low = 151685;
parameter fa_low = 143172;
parameter so_low = 127554;
parameter la_low = 113636;
parameter si_low = 101239;

parameter do = 93941;
parameter re = 85136;
parameter me = 75838;
parameter fa = 71582;
parameter so = 63776;
parameter la = 56818;
parameter si = 50618;

parameter do_high = 47778;
parameter re_high = 42567;
parameter me_high = 37921;
parameter fa_high = 36498;
parameter so_high = 31888;
parameter la_high = 28409;
parameter si_high = 25309;

parameter beat = 40 * 500000;
parameter gap =  10 * 500000;
parameter index_period = beat + gap;

parameter silence = beat<<9;

/*
0 - silence
1 - 7 low
8 - 14 meidum
15 - 21 high
*/
parameter JiangNan = 1660'b0000001111000001000000000100001000110010000000000000000100000000001111100011001010011100011001010001100100111100000000000000010011100110111101111000001010010100011010110001110011100000000000000000111000000100000111110000100011000001111011100111110000100011000100000000000000010000000000111110001100101001110010100011000110001100000111100000000000000010000000000111110001100101001110001100101000110010011110000000000100111001101111011110000000000101001010001101011000111000000000000000001110000001000001111000001000010001100000111101110011111000010001100010000000000000001000000000011111000110010100111001010001100011000110000011110000000000000001001110011100110000010100000000111101111100110110101111000000111101111100110111101111000000111101111100000111110001100010000010001100001000110001100011000110001100011000110001000001000110001100011000110001100010000000000000000110101100011100111110000011110111001110011100000000000000000110101111100010000010011011110111001101000000000000000011010111101101000000110001110011110111001110011100000000000000000110101111000001000110011011110111001101000000000000000011010000001100011100111110000011110111001110011100000000000000000110101111000001000110011011110111001101011010000000000000000110101100000000111001111011100111001110000000000000000011010111100000100011001101111011100110100000000001000110001100000111101110011010101000110011100111101111011100110101100010010010100000100010000001101011000101101000011010111110001100110111101110011010101000110100011000010001011110111001101010100011001110011110111101110011010110001001001010000010001000000110101100010110100001101011111000110011011110111001101010100011000000;
parameter HappyBirthday = 130'b0111110000011111000110010000000000001101011100111110001100110110001111011111000001100011010110001110011100111101100011010010100101;
parameter MerryChristmas = 335'b01111011110111101110100000110101100011001001101111100001000110000000000110001100011010111001111011100000001110011110111101111011000000001111011110111010000011010110001100000000110101111100001000110010100011000100000011000110000000011000111001111100001000110000100000000001101000000000001101011010111001111100000111101111000000110001100;

parameter JN_length = 332;
parameter HB_length = 26;
parameter MC_length = 67;

reg[29:0] freq =  beat;

reg[2000:0] melody = 0;
integer melody_length = 0;

integer frequency_count = 0;      // count1 control frequency
integer index_count = 0;      // count2 control beat;

integer index = 0;       // index control the location music playing

reg [0:0] isSilence = 0; 
reg [0:0] isEnd = 0;
reg [0:0] isPeriodic = 0;

reg[4:0] last_mode = 0;


always @(posedge clk) begin
    
    if(mode != last_mode) begin
        last_mode = mode;
        isEnd = 0;
        index = 0;
        index_count = 0;
        
        if(mode >= 17) isPeriodic = 1;
        else begin isPeriodic = 0; melody_length = 1; end
        
        if(mode == 17) melody_length = MC_length;
        if(mode == 18) melody_length = HB_length;
        if(mode == 19) melody_length = JN_length;
       
        case(mode)
            17: melody = MerryChristmas;
            18: melody = HappyBirthday;
            19: melody = JiangNan;
            default : melody = mode;
        endcase
       
    end


    if(frequency_count >= freq) begin
        frequency_count = 0;
        music = ~music;
    end
    else frequency_count = frequency_count + 1;
    
    if(index_count <= gap) begin
        isSilence = 1;
    end
    
    if(gap < index_count && index_count <= index_period) begin
        isSilence = 0;
    end
    
    if(index_count > index_period) begin
        index_count = 0;
        index = index + 1;
        if(index > melody_length && isPeriodic) begin
            isEnd = 0;
            index = 0;
        end
        if(index > melody_length && !isPeriodic) begin
            index = 0;
            isEnd = 1;
        end
    end
    
    index_count = index_count + 1;
    
end



always @ * begin

if(isSilence || isEnd)
freq = silence;
else
case(melody[index * 5 +4 -:5])
5'd0 : freq = silence;
5'd1 : freq = do_low;
5'd2 : freq = re_low;
5'd3 : freq = me_low;
5'd4 : freq = fa_low;
5'd5 : freq = so_low;
5'd6 : freq = la_low;
5'd7 : freq = si_low;
5'd8 : freq = do;
5'd9 : freq = re;
5'd10 : freq = me;
5'd11: freq = fa;
5'd12 : freq = so;
5'd13 : freq = la;
5'd14 : freq = si;
5'd15 : freq = do_high;
5'd16 : freq = re_high;
5'd17 : freq = me_high;
5'd18 : freq = fa_high;
5'd19 : freq = so_high;
5'd20 : freq = la_high;
5'd21 : freq = si_high;
default : freq = silence;
endcase
end


endmodule