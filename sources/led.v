`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/22 01:30:29
// Design Name: 
// Module Name: digital_tube
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


module digital_tube( 
    output reg [7:0] tube_char, //控制数码管样式
    output reg [7:0] tube_switch = 0,  //控制各个数码管显示与否
    input clk, //时钟信号
    input up, // 货道上翻信号
    input down,  // 下翻
    input[5:0] new_text, // 下一个显示物品的货道号  
    input wire[2:0] mode,  // 当前的显示模式
    input wire[15:0] number,  // 要显示的数字
    input wire[11:0]  Time);  // 要显示的时间

reg[33:0] counter_scan = 0;
reg[33:0] counter_roll = 0;
reg[2:0] cube_onshowing_index = 0;
reg[63:0] on_showing_eight_chars;

reg[3:0] BCD_codes = 0;
wire[6:0] text_bits;

reg[6:0] tmp_text_bits_1;
reg[6:0] tmp_text_bits_2;
reg[6:0] tmp_text_bits_3;
reg[6:0] tmp_text_bits_4;
reg[6:0] tmp_text_bits_5;
reg[6:0] tmp_text_bits_6;
reg[6:0] tmp_text_bits_7;
reg[6:0] tmp_text_bits_8;

wire[19:0] number_BCD;
wire[15:0] time_BCD;

toBCD_16_20 object_1(number, number_BCD);
toBCD_16_20 object_2(Time, time_BCD);

parameter scan_period = 150000;
parameter rolling_period = 100000000;


parameter SUCCESS = 24'b100100101100000111111111;
parameter FAILURE = 24'b100001101010111111111111;

parameter SUCCESS_LENGTH = 3;
parameter FAILURE_LENGTH = 3;


parameter commodity_0 = 64'b1111111111111111111111111111111111111111111111111111111111111111;
parameter commodity_1 = 120'b110000001111100111111111110001101100000011000110100010001100011011000000110001111000100011111111001100001001001011111111;
parameter commodity_2 = 88'b1100000010100100111111111100011011000000110001101100000011111111000000101100000011111111;
parameter commodity_3 = 96'b110000001011000011111111100100101000011010000110110000001111111111111001001100001100000011111111;
parameter commodity_4 = 96'b110000001001100111111111110001101000100111001111110001111100111111111111001100001100000011111111;
parameter commodity_5 = 96'b110000001001001011111111100011101100111110010010100010011111111110010010010000001100000011111111;
parameter commodity_6 = 96'b110000001000001011111111111000001000011011000111110001111100000011111111011110011001001011111111;
parameter commodity_7 = 80'b11000000111110001111111110000110110000101100001011111111011110011100000011111111;
parameter commodity_8 = 80'b11000000100000001111111111001111110001101000011011111111010000001001001011111111;
parameter commodity_9 = 96'b110000001001100011111111100011001100111111000111110001111111111110110000010000001100000011111111;
parameter commodity_10 = 96'b111110011100000011111111110001101000100110000110100011101111111110000010001100001001001011111111;
parameter commodity_11 = 112'b1111100111111001111111111100011010001001100001101000011010010010100001101111111110010010000100101100000011111111;
parameter commodity_12 = 96'b111110011010010011111111100100101100000011000001100011001111111110100100000000001100000011111111;


//不同商品固定文本的长度
parameter length_0 = 8;
parameter length_1 = 15;
parameter length_2 = 11;
parameter length_3 = 12;
parameter length_4 = 12;
parameter length_5 = 12;
parameter length_6 = 12;
parameter length_7 = 10;
parameter length_8 = 10;
parameter length_9 = 12;
parameter length_10 = 12;
parameter length_11 = 14;
parameter length_12 = 12;

reg[200:0] on_showing_text = commodity_1;
reg[250:0] on_showing_text_with_rest;


integer on_showing_text_length = length_1;
integer on_showing_text_length_with_rest;
integer current_commodity_index = 1;
integer rolling_index = 0; // 滚动显示的index

reg[1:0] is_up_or_down = 0;  

// 0 默认状态 收到 up 或 down 信号之后便会 = 1
// 1 上升/下降 一半的状态 period 之后会变为 2
// 2 完全上升/下降的状态 period 之后会变为 3
// 3 上升/下降 一半的状态 之后变为 0

reg[33:0] is_up_or_down_counter = 0;
parameter is_up_or_down_period = 50000000;
reg[0:0] current_change_direction = 0; // 保留传来的up或down信号 0 表示向下，1表示向上

reg[0:0] is_changing_text = 0;

always @ (posedge clk) begin

    //扫描计时器 会更改 counter_scan
    if(counter_scan >= scan_period) begin
        cube_onshowing_index = cube_onshowing_index + 1;
        counter_scan = 0;
    end
    
    else counter_scan = counter_scan + 1;

    if(counter_roll >= rolling_period && is_up_or_down == 0) begin  // 上下滚动时，不会左右滚动，不然看不清
        rolling_index = rolling_index - 1;
        counter_roll = 0;
        if(rolling_index < 0) 
        rolling_index = on_showing_text_length_with_rest - 8;
        on_showing_eight_chars = on_showing_text_with_rest[ rolling_index * 8 + 63 -: 64 ];
    end
    else counter_roll = counter_roll + 1;
    
    if(mode == 1 || mode == 4 || mode == 5) begin
    // 模式1是普通的显示商品，只需要用到 4 个数字 的 中间两个
    case(number_BCD[3:0])
    4'd0 : tmp_text_bits_1 = 7'b1000000;
    4'd1 : tmp_text_bits_1 = 7'b1111001;
    4'd2 : tmp_text_bits_1 = 7'b0100100; 
    4'd3 : tmp_text_bits_1 = 7'b0110000; 
    4'd4 : tmp_text_bits_1 = 7'b0011001; 
    4'd5 : tmp_text_bits_1 = 7'b0010010; 
    4'd6 : tmp_text_bits_1 = 7'b0000010; 
    4'd7 : tmp_text_bits_1 = 7'b1111000; 
    4'd8 : tmp_text_bits_1 = 7'b0000000; 
    4'd9 : tmp_text_bits_1 = 7'b0010000; 
    default : tmp_text_bits_1 = 7'b1111111;
    endcase
    
    case(number_BCD[7:4])
    4'd0 : tmp_text_bits_2 = 7'b1000000;
    4'd1 : tmp_text_bits_2 = 7'b1111001;
    4'd2 : tmp_text_bits_2 = 7'b0100100; 
    4'd3 : tmp_text_bits_2 = 7'b0110000; 
    4'd4 : tmp_text_bits_2 = 7'b0011001; 
    4'd5 : tmp_text_bits_2 = 7'b0010010; 
    4'd6 : tmp_text_bits_2 = 7'b0000010; 
    4'd7 : tmp_text_bits_2 = 7'b1111000; 
    4'd8 : tmp_text_bits_2 = 7'b0000000; 
    4'd9 : tmp_text_bits_2 = 7'b0010000; 
    default : tmp_text_bits_2 = 7'b1111111;
    endcase    
    
    
   /* BCD_codes = number_BCD[3:0];
    tmp_text_bits_1 = text_bits;
    
    BCD_codes = number_BCD[7:4];
    tmp_text_bits_2 = text_bits;*/
    
    on_showing_text_with_rest = {on_showing_text, 1'b1, tmp_text_bits_2, 1'b1, tmp_text_bits_1};

    on_showing_text_length_with_rest = on_showing_text_length + 2;

     //向上 且不在改变中
    if(up == 1 && is_up_or_down == 0) begin
        is_up_or_down = 1;
        current_change_direction = 1;
    end
          
    //向下 且不在改变中
    if(down == 1 && is_up_or_down == 0) begin
        is_up_or_down = 1;
        current_change_direction = 0;
    end
    
    // is_up_or_down = 1 时 是一个比较重要的状态，1切换到2时，会更换当时播放的物品!
    if(is_up_or_down == 1) begin
         if(is_up_or_down_counter >= is_up_or_down_period) begin
             is_up_or_down_counter = 0;
             is_up_or_down = 2;
             case(new_text)
                 4'd0 : begin on_showing_text = commodity_0; on_showing_text_length = length_0; end
                 4'd1 : begin on_showing_text = commodity_1; on_showing_text_length = length_1; end
                 4'd2 : begin on_showing_text = commodity_2; on_showing_text_length = length_2; end
                 4'd3 : begin on_showing_text = commodity_3; on_showing_text_length = length_3; end
                 4'd4 : begin on_showing_text = commodity_4; on_showing_text_length = length_4; end
                 4'd5 : begin on_showing_text = commodity_5; on_showing_text_length = length_5; end
                 4'd6 : begin on_showing_text = commodity_6; on_showing_text_length = length_6; end
                 4'd7 : begin on_showing_text = commodity_7; on_showing_text_length = length_7; end
                 4'd8 : begin on_showing_text = commodity_8; on_showing_text_length = length_8; end
                 4'd9 : begin on_showing_text = commodity_9; on_showing_text_length = length_9; end
                 4'd10 : begin on_showing_text = commodity_10; on_showing_text_length = length_10; end
                 4'd11 : begin on_showing_text = commodity_11; on_showing_text_length = length_11; end
                 4'd12 : begin on_showing_text = commodity_12; on_showing_text_length = length_12; end
                 default : begin on_showing_text = commodity_0; on_showing_text_length = length_0; end
              endcase   
              
               BCD_codes = number_BCD[7:4];
               tmp_text_bits_1 = text_bits;
          
               BCD_codes = number_BCD[11:8];
               tmp_text_bits_2 = text_bits;
                 
               on_showing_text_with_rest = {on_showing_text, 1'b1, tmp_text_bits_2, 1'b1, tmp_text_bits_1};
             
              //on_showing_text_length_with_rest = on_showing_text_length + 2;

               rolling_index = on_showing_text_length - 6;   
               
               on_showing_eight_chars = on_showing_text_with_rest[ rolling_index * 8 + 63 -: 64 ]; // 归0
              
         end
         else is_up_or_down_counter = is_up_or_down_counter + 1; 
     end      
         
    if(is_up_or_down == 2) begin
          if(is_up_or_down_counter >= is_up_or_down_period) begin
              is_up_or_down_counter = 0;
              is_up_or_down = 3;
          end
          else is_up_or_down_counter = is_up_or_down_counter + 1; 
      end             
    
    if(is_up_or_down == 3) begin
         if(is_up_or_down_counter >= is_up_or_down_period) begin
             is_up_or_down_counter = 0;
             is_up_or_down = 0;
             counter_roll = 0;  // 换完一次后，下次无缝切换
         end
         else is_up_or_down_counter = is_up_or_down_counter + 1; 
     end    
     end
     
    if(mode == 2) begin
    
           case(time_BCD[15:12])
               4'd0 : tmp_text_bits_1 = 7'b1000000;
               4'd1 : tmp_text_bits_1 = 7'b1111001;
               4'd2 : tmp_text_bits_1 = 7'b0100100; 
               4'd3 : tmp_text_bits_1 = 7'b0110000; 
               4'd4 : tmp_text_bits_1 = 7'b0011001; 
               4'd5 : tmp_text_bits_1 = 7'b0010010; 
               4'd6 : tmp_text_bits_1 = 7'b0000010; 
               4'd7 : tmp_text_bits_1 = 7'b1111000; 
               4'd8 : tmp_text_bits_1 = 7'b0000000; 
               4'd9 : tmp_text_bits_1 = 7'b0010000; 
               default : tmp_text_bits_1 = 7'b1111111;
           endcase    
           
           case(time_BCD[11:8])
               4'd0 : tmp_text_bits_2 = 7'b1000000;
               4'd1 : tmp_text_bits_2 = 7'b1111001;
               4'd2 : tmp_text_bits_2 = 7'b0100100; 
               4'd3 : tmp_text_bits_2 = 7'b0110000; 
               4'd4 : tmp_text_bits_2 = 7'b0011001; 
               4'd5 : tmp_text_bits_2 = 7'b0010010; 
               4'd6 : tmp_text_bits_2 = 7'b0000010; 
               4'd7 : tmp_text_bits_2 = 7'b1111000; 
               4'd8 : tmp_text_bits_2 = 7'b0000000; 
               4'd9 : tmp_text_bits_2 = 7'b0010000; 
               default : tmp_text_bits_2 = 7'b1111111;
           endcase             
            
           tmp_text_bits_3 = 7'b1111111;
           
           case(number_BCD[19:16])
              4'd0 : tmp_text_bits_4 = 7'b1000000;
              4'd1 : tmp_text_bits_4 = 7'b1111001;
              4'd2 : tmp_text_bits_4 = 7'b0100100; 
              4'd3 : tmp_text_bits_4 = 7'b0110000; 
              4'd4 : tmp_text_bits_4 = 7'b0011001; 
              4'd5 : tmp_text_bits_4 = 7'b0010010; 
              4'd6 : tmp_text_bits_4 = 7'b0000010; 
              4'd7 : tmp_text_bits_4 = 7'b1111000; 
              4'd8 : tmp_text_bits_4 = 7'b0000000; 
              4'd9 : tmp_text_bits_4 = 7'b0010000; 
              default : tmp_text_bits_4 = 7'b1111111;
          endcase             
                      
           case(number_BCD[15:12])
            4'd0 : tmp_text_bits_5 = 7'b1000000;
            4'd1 : tmp_text_bits_5 = 7'b1111001;
            4'd2 : tmp_text_bits_5 = 7'b0100100; 
            4'd3 : tmp_text_bits_5 = 7'b0110000; 
            4'd4 : tmp_text_bits_5 = 7'b0011001; 
            4'd5 : tmp_text_bits_5 = 7'b0010010; 
            4'd6 : tmp_text_bits_5 = 7'b0000010; 
            4'd7 : tmp_text_bits_5 = 7'b1111000; 
            4'd8 : tmp_text_bits_5 = 7'b0000000; 
            4'd9 : tmp_text_bits_5 = 7'b0010000; 
            default : tmp_text_bits_5 = 7'b1111111;
        endcase             
                        
           case(number_BCD[11:8])
          4'd0 : tmp_text_bits_6 = 7'b1000000;
          4'd1 : tmp_text_bits_6 = 7'b1111001;
          4'd2 : tmp_text_bits_6 = 7'b0100100; 
          4'd3 : tmp_text_bits_6 = 7'b0110000; 
          4'd4 : tmp_text_bits_6 = 7'b0011001; 
          4'd5 : tmp_text_bits_6 = 7'b0010010; 
          4'd6 : tmp_text_bits_6 = 7'b0000010; 
          4'd7 : tmp_text_bits_6 = 7'b1111000; 
          4'd8 : tmp_text_bits_6 = 7'b0000000; 
          4'd9 : tmp_text_bits_6 = 7'b0010000; 
          default : tmp_text_bits_6 = 7'b1111111;
      endcase             
  
           case(number_BCD[7:4])
        4'd0 : tmp_text_bits_7 = 7'b1000000;
        4'd1 : tmp_text_bits_7 = 7'b1111001;
        4'd2 : tmp_text_bits_7 = 7'b0100100; 
        4'd3 : tmp_text_bits_7 = 7'b0110000; 
        4'd4 : tmp_text_bits_7 = 7'b0011001; 
        4'd5 : tmp_text_bits_7 = 7'b0010010; 
        4'd6 : tmp_text_bits_7 = 7'b0000010; 
        4'd7 : tmp_text_bits_7 = 7'b1111000; 
        4'd8 : tmp_text_bits_7 = 7'b0000000; 
        4'd9 : tmp_text_bits_7 = 7'b0010000; 
        default : tmp_text_bits_7 = 7'b1111111;
    endcase               
    
           case(number_BCD[3:0])
       4'd0 : tmp_text_bits_8 = 7'b1000000;
       4'd1 : tmp_text_bits_8 = 7'b1111001;
       4'd2 : tmp_text_bits_8 = 7'b0100100; 
       4'd3 : tmp_text_bits_8 = 7'b0110000; 
       4'd4 : tmp_text_bits_8 = 7'b0011001; 
       4'd5 : tmp_text_bits_8 = 7'b0010010; 
       4'd6 : tmp_text_bits_8 = 7'b0000010; 
       4'd7 : tmp_text_bits_8 = 7'b1111000; 
       4'd8 : tmp_text_bits_8 = 7'b0000000; 
       4'd9 : tmp_text_bits_8 = 7'b0010000; 
       default : tmp_text_bits_8 = 7'b1111111;
   endcase                    
           
           on_showing_text_with_rest = {1'b1, tmp_text_bits_1, 1'b1, tmp_text_bits_2, 1'b1, tmp_text_bits_3, 1'b1,tmp_text_bits_4, 1'b1, tmp_text_bits_5, 1'b1,tmp_text_bits_6, 1'b0,tmp_text_bits_7, 1'b1,tmp_text_bits_8 };
           on_showing_text_length_with_rest = 8;
           rolling_index = 0;
           
    end
     
    if(mode == 3) begin
     
          case(number_BCD[19:16])
                           4'd0 : tmp_text_bits_4 = 7'b1000000;
                           4'd1 : tmp_text_bits_4 = 7'b1111001;
                           4'd2 : tmp_text_bits_4 = 7'b0100100; 
                           4'd3 : tmp_text_bits_4 = 7'b0110000; 
                           4'd4 : tmp_text_bits_4 = 7'b0011001; 
                           4'd5 : tmp_text_bits_4 = 7'b0010010; 
                           4'd6 : tmp_text_bits_4 = 7'b0000010; 
                           4'd7 : tmp_text_bits_4 = 7'b1111000; 
                           4'd8 : tmp_text_bits_4 = 7'b0000000; 
                           4'd9 : tmp_text_bits_4 = 7'b0010000; 
                           default : tmp_text_bits_4 = 7'b1111111;
                       endcase             
                                   
          case(number_BCD[15:12])
                         4'd0 : tmp_text_bits_5 = 7'b1000000;
                         4'd1 : tmp_text_bits_5 = 7'b1111001;
                         4'd2 : tmp_text_bits_5 = 7'b0100100; 
                         4'd3 : tmp_text_bits_5 = 7'b0110000; 
                         4'd4 : tmp_text_bits_5 = 7'b0011001; 
                         4'd5 : tmp_text_bits_5 = 7'b0010010; 
                         4'd6 : tmp_text_bits_5 = 7'b0000010; 
                         4'd7 : tmp_text_bits_5 = 7'b1111000; 
                         4'd8 : tmp_text_bits_5 = 7'b0000000; 
                         4'd9 : tmp_text_bits_5 = 7'b0010000; 
                         default : tmp_text_bits_5 = 7'b1111111;
                     endcase             
                                     
          case(number_BCD[11:8])
                       4'd0 : tmp_text_bits_6 = 7'b1000000;
                       4'd1 : tmp_text_bits_6 = 7'b1111001;
                       4'd2 : tmp_text_bits_6 = 7'b0100100; 
                       4'd3 : tmp_text_bits_6 = 7'b0110000; 
                       4'd4 : tmp_text_bits_6 = 7'b0011001; 
                       4'd5 : tmp_text_bits_6 = 7'b0010010; 
                       4'd6 : tmp_text_bits_6 = 7'b0000010; 
                       4'd7 : tmp_text_bits_6 = 7'b1111000; 
                       4'd8 : tmp_text_bits_6 = 7'b0000000; 
                       4'd9 : tmp_text_bits_6 = 7'b0010000; 
                       default : tmp_text_bits_6 = 7'b1111111;
                   endcase             
               
          case(number_BCD[7:4])
                     4'd0 : tmp_text_bits_7 = 7'b1000000;
                     4'd1 : tmp_text_bits_7 = 7'b1111001;
                     4'd2 : tmp_text_bits_7 = 7'b0100100; 
                     4'd3 : tmp_text_bits_7 = 7'b0110000; 
                     4'd4 : tmp_text_bits_7 = 7'b0011001; 
                     4'd5 : tmp_text_bits_7 = 7'b0010010; 
                     4'd6 : tmp_text_bits_7 = 7'b0000010; 
                     4'd7 : tmp_text_bits_7 = 7'b1111000; 
                     4'd8 : tmp_text_bits_7 = 7'b0000000; 
                     4'd9 : tmp_text_bits_7 = 7'b0010000; 
                     default : tmp_text_bits_7 = 7'b1111111;
                 endcase               
                 
          case(number_BCD[3:0])
                    4'd0 : tmp_text_bits_8 = 7'b1000000;
                    4'd1 : tmp_text_bits_8 = 7'b1111001;
                    4'd2 : tmp_text_bits_8 = 7'b0100100; 
                    4'd3 : tmp_text_bits_8 = 7'b0110000; 
                    4'd4 : tmp_text_bits_8 = 7'b0011001; 
                    4'd5 : tmp_text_bits_8 = 7'b0010010; 
                    4'd6 : tmp_text_bits_8 = 7'b0000010; 
                    4'd7 : tmp_text_bits_8 = 7'b1111000; 
                    4'd8 : tmp_text_bits_8 = 7'b0000000; 
                    4'd9 : tmp_text_bits_8 = 7'b0010000; 
                    default : tmp_text_bits_8 = 7'b1111111;
                endcase                    
             
          on_showing_text_with_rest = {FAILURE, 1'b1, tmp_text_bits_4, 1'b1, tmp_text_bits_5,1'b1, tmp_text_bits_6, 1'b0, tmp_text_bits_7, 1'b1, tmp_text_bits_8};
          on_showing_text_length_with_rest = FAILURE_LENGTH + 5;
         // rolling_index = on_showing_text_length_with_rest - 8;        
     
     end
     
    if(mode == 7) begin
       
        case(number_BCD[19:16])
                      4'd0 : tmp_text_bits_4 = 7'b1000000;
                      4'd1 : tmp_text_bits_4 = 7'b1111001;
                      4'd2 : tmp_text_bits_4 = 7'b0100100; 
                      4'd3 : tmp_text_bits_4 = 7'b0110000; 
                      4'd4 : tmp_text_bits_4 = 7'b0011001; 
                      4'd5 : tmp_text_bits_4 = 7'b0010010; 
                      4'd6 : tmp_text_bits_4 = 7'b0000010; 
                      4'd7 : tmp_text_bits_4 = 7'b1111000; 
                      4'd8 : tmp_text_bits_4 = 7'b0000000; 
                      4'd9 : tmp_text_bits_4 = 7'b0010000; 
                      default : tmp_text_bits_4 = 7'b1111111;
                  endcase             
                              
        case(number_BCD[15:12])
                    4'd0 : tmp_text_bits_5 = 7'b1000000;
                    4'd1 : tmp_text_bits_5 = 7'b1111001;
                    4'd2 : tmp_text_bits_5 = 7'b0100100; 
                    4'd3 : tmp_text_bits_5 = 7'b0110000; 
                    4'd4 : tmp_text_bits_5 = 7'b0011001; 
                    4'd5 : tmp_text_bits_5 = 7'b0010010; 
                    4'd6 : tmp_text_bits_5 = 7'b0000010; 
                    4'd7 : tmp_text_bits_5 = 7'b1111000; 
                    4'd8 : tmp_text_bits_5 = 7'b0000000; 
                    4'd9 : tmp_text_bits_5 = 7'b0010000; 
                    default : tmp_text_bits_5 = 7'b1111111;
                endcase             
                                
        case(number_BCD[11:8])
                  4'd0 : tmp_text_bits_6 = 7'b1000000;
                  4'd1 : tmp_text_bits_6 = 7'b1111001;
                  4'd2 : tmp_text_bits_6 = 7'b0100100; 
                  4'd3 : tmp_text_bits_6 = 7'b0110000; 
                  4'd4 : tmp_text_bits_6 = 7'b0011001; 
                  4'd5 : tmp_text_bits_6 = 7'b0010010; 
                  4'd6 : tmp_text_bits_6 = 7'b0000010; 
                  4'd7 : tmp_text_bits_6 = 7'b1111000; 
                  4'd8 : tmp_text_bits_6 = 7'b0000000; 
                  4'd9 : tmp_text_bits_6 = 7'b0010000; 
                  default : tmp_text_bits_6 = 7'b1111111;
              endcase             
          
        case(number_BCD[7:4])
                4'd0 : tmp_text_bits_7 = 7'b1000000;
                4'd1 : tmp_text_bits_7 = 7'b1111001;
                4'd2 : tmp_text_bits_7 = 7'b0100100; 
                4'd3 : tmp_text_bits_7 = 7'b0110000; 
                4'd4 : tmp_text_bits_7 = 7'b0011001; 
                4'd5 : tmp_text_bits_7 = 7'b0010010; 
                4'd6 : tmp_text_bits_7 = 7'b0000010; 
                4'd7 : tmp_text_bits_7 = 7'b1111000; 
                4'd8 : tmp_text_bits_7 = 7'b0000000; 
                4'd9 : tmp_text_bits_7 = 7'b0010000; 
                default : tmp_text_bits_7 = 7'b1111111;
            endcase               
            
        case(number_BCD[3:0])
               4'd0 : tmp_text_bits_8 = 7'b1000000;
               4'd1 : tmp_text_bits_8 = 7'b1111001;
               4'd2 : tmp_text_bits_8 = 7'b0100100; 
               4'd3 : tmp_text_bits_8 = 7'b0110000; 
               4'd4 : tmp_text_bits_8 = 7'b0011001; 
               4'd5 : tmp_text_bits_8 = 7'b0010010; 
               4'd6 : tmp_text_bits_8 = 7'b0000010; 
               4'd7 : tmp_text_bits_8 = 7'b1111000; 
               4'd8 : tmp_text_bits_8 = 7'b0000000; 
               4'd9 : tmp_text_bits_8 = 7'b0010000; 
               default : tmp_text_bits_8 = 7'b1111111;
           endcase                    
        
        on_showing_text_with_rest = {SUCCESS, 1'b1, tmp_text_bits_4, 1'b1, tmp_text_bits_5,1'b1, tmp_text_bits_6, 1'b0, tmp_text_bits_7, 1'b1, tmp_text_bits_8};
        on_showing_text_length_with_rest = SUCCESS_LENGTH + 5;
       // rolling_index = on_showing_text_length_with_rest - 8;
    end
    
    if(mode == 6) begin
          /*case(time_BCD[11:8])
                   4'd0 : tmp_text_bits_1 = 7'b1000000;
                   4'd1 : tmp_text_bits_1 = 7'b1111001;
                   4'd2 : tmp_text_bits_1 = 7'b0100100; 
                   4'd3 : tmp_text_bits_1 = 7'b0110000; 
                   4'd4 : tmp_text_bits_1 = 7'b0011001; 
                   4'd5 : tmp_text_bits_1 = 7'b0010010; 
                   4'd6 : tmp_text_bits_1 = 7'b0000010; 
                   4'd7 : tmp_text_bits_1 = 7'b1111000; 
                   4'd8 : tmp_text_bits_1 = 7'b0000000; 
                   4'd9 : tmp_text_bits_1 = 7'b0010000; 
                   default : tmp_text_bits_1 = 7'b1111111;
               endcase    
               
          case(time_BCD[7:4])
                   4'd0 : tmp_text_bits_2 = 7'b1000000;
                   4'd1 : tmp_text_bits_2 = 7'b1111001;
                   4'd2 : tmp_text_bits_2 = 7'b0100100; 
                   4'd3 : tmp_text_bits_2 = 7'b0110000; 
                   4'd4 : tmp_text_bits_2 = 7'b0011001; 
                   4'd5 : tmp_text_bits_2 = 7'b0010010; 
                   4'd6 : tmp_text_bits_2 = 7'b0000010; 
                   4'd7 : tmp_text_bits_2 = 7'b1111000; 
                   4'd8 : tmp_text_bits_2 = 7'b0000000; 
                   4'd9 : tmp_text_bits_2 = 7'b0010000; 
                   default : tmp_text_bits_2 = 7'b1111111;
           endcase    
           
           case(time_BCD[3:0])
                              4'd0 : tmp_text_bits_3 = 7'b1000000;
//                              4'd1 : tmp_text_bits_3 = 7'b1111001;
//                              4'd2 : tmp_text_bits_3 = 7'b0100100; 
//                              4'd3 : tmp_text_bits_3 = 7'b0110000; 
//                              4'd4 : tmp_text_bits_3 = 7'b0011001; 
//                              4'd5 : tmp_text_bits_3 = 7'b0010010; 
//                              4'd6 : tmp_text_bits_3 = 7'b0000010; 
//                              4'd7 : tmp_text_bits_3 = 7'b1111000; 
//                              4'd8 : tmp_text_bits_3 = 7'b0000000; 
//                              4'd9 : tmp_text_bits_3 = 7'b0010000; 
//                              default : tmp_text_bits_3 = 7'b1111111;
//                      endcase                 
//                */
                
           tmp_text_bits_1 = 7'b1111111;
           
           tmp_text_bits_2 = 7'b1111111;
           
           tmp_text_bits_3 = 7'b1111111;     
                
          tmp_text_bits_4 = 7'b1111111;
                                        
          case(number_BCD[15:12])
                4'd0 : tmp_text_bits_5 = 7'b1000000;
                4'd1 : tmp_text_bits_5 = 7'b1111001;
                4'd2 : tmp_text_bits_5 = 7'b0100100; 
                4'd3 : tmp_text_bits_5 = 7'b0110000; 
                4'd4 : tmp_text_bits_5 = 7'b0011001; 
                4'd5 : tmp_text_bits_5 = 7'b0010010; 
                4'd6 : tmp_text_bits_5 = 7'b0000010; 
                4'd7 : tmp_text_bits_5 = 7'b1111000; 
                4'd8 : tmp_text_bits_5 = 7'b0000000; 
                4'd9 : tmp_text_bits_5 = 7'b0010000; 
                default : tmp_text_bits_5 = 7'b1111111;
            endcase             
                            
          case(number_BCD[11:8])
              4'd0 : tmp_text_bits_6 = 7'b1000000;
              4'd1 : tmp_text_bits_6 = 7'b1111001;
              4'd2 : tmp_text_bits_6 = 7'b0100100; 
              4'd3 : tmp_text_bits_6 = 7'b0110000; 
              4'd4 : tmp_text_bits_6 = 7'b0011001; 
              4'd5 : tmp_text_bits_6 = 7'b0010010; 
              4'd6 : tmp_text_bits_6 = 7'b0000010; 
              4'd7 : tmp_text_bits_6 = 7'b1111000; 
              4'd8 : tmp_text_bits_6 = 7'b0000000; 
              4'd9 : tmp_text_bits_6 = 7'b0010000; 
              default : tmp_text_bits_6 = 7'b1111111;
          endcase             
      
          case(number_BCD[7:4])
            4'd0 : tmp_text_bits_7 = 7'b1000000;
            4'd1 : tmp_text_bits_7 = 7'b1111001;
            4'd2 : tmp_text_bits_7 = 7'b0100100; 
            4'd3 : tmp_text_bits_7 = 7'b0110000; 
            4'd4 : tmp_text_bits_7 = 7'b0011001; 
            4'd5 : tmp_text_bits_7 = 7'b0010010; 
            4'd6 : tmp_text_bits_7 = 7'b0000010; 
            4'd7 : tmp_text_bits_7 = 7'b1111000; 
            4'd8 : tmp_text_bits_7 = 7'b0000000; 
            4'd9 : tmp_text_bits_7 = 7'b0010000; 
            default : tmp_text_bits_7 = 7'b1111111;
        endcase               
        
          case(number_BCD[3:0])
           4'd0 : tmp_text_bits_8 = 7'b1000000;
           4'd1 : tmp_text_bits_8 = 7'b1111001;
           4'd2 : tmp_text_bits_8 = 7'b0100100; 
           4'd3 : tmp_text_bits_8 = 7'b0110000; 
           4'd4 : tmp_text_bits_8 = 7'b0011001; 
           4'd5 : tmp_text_bits_8 = 7'b0010010; 
           4'd6 : tmp_text_bits_8 = 7'b0000010; 
           4'd7 : tmp_text_bits_8 = 7'b1111000; 
           4'd8 : tmp_text_bits_8 = 7'b0000000; 
           4'd9 : tmp_text_bits_8 = 7'b0010000; 
           default : tmp_text_bits_8 = 7'b1111111;
       endcase                    
               
          on_showing_text_with_rest = {1'b1, tmp_text_bits_1, 1'b1, tmp_text_bits_2, 1'b1, tmp_text_bits_3, 1'b1,tmp_text_bits_4, 1'b1, tmp_text_bits_5, 1'b1,tmp_text_bits_6, 1'b0,tmp_text_bits_7, 1'b1,tmp_text_bits_8 };
          on_showing_text_length_with_rest = 8;
          rolling_index = 0;        
    end
   
   if(mode == 0) begin
       on_showing_text_with_rest = commodity_0;
       on_showing_text_length_with_rest = 8;
   end
   
    
end

always @ (cube_onshowing_index) begin  // 显示 on_showing_eight_chars
    tube_switch = 8'hff;
    tube_switch[cube_onshowing_index] = 0;
    tube_char = on_showing_eight_chars[cube_onshowing_index * 8 + 7 -: 8];
    
        // 向下 状态1 这个时候显然会改变 on_showing_eight_bits
    if ((is_up_or_down == 1 && current_change_direction == 0) || (is_up_or_down == 3 && current_change_direction == 1)) begin
        tube_char[6] = tube_char[0];
        tube_char[2] = tube_char[1];
        tube_char[3] = tube_char[6];
        tube_char[4] = tube_char[5];
        tube_char[0] = 1;
        tube_char[1] = 1;
        tube_char[5] = 1;       
        tube_char[7] = 1; 
    end
        // 向上 状态1 这个时候显然会改变 on_showing_eight_bits
    if ((is_up_or_down == 1 && current_change_direction == 1) || (is_up_or_down == 3 && current_change_direction == 0) ) begin
         tube_char[0] = tube_char[6];
         tube_char[1] = tube_char[2];
         tube_char[5] = tube_char[4];
         tube_char[6] = tube_char[3];
         tube_char[2] = 1;
         tube_char[4] = 1;
         tube_char[3] = 1;   
         tube_char[7] = 1; 
    end
        //状态2 什么都不显示 
    if(is_up_or_down == 2) begin
        tube_char = 8'b11111111;
    end
    
end
endmodule
/*
module toBCD_10_16(
input wire[9:0] BinaryNumber, output reg[15:0] BCD);

reg[9:0] number = 0;
integer i;
integer j;

always@(BinaryNumber) begin
number = BinaryNumber;
BCD = 0;

for(i = 1; i <= 9; i = i + 1) begin
{BCD, number} = {BCD, number} << 1;

for(j = 0; j <= 12; j = j + 4) begin
BCD[j+3-:4] = BCD[j+3-:4] > 4'd4 ? BCD[j+3-:4] + 2'b11 :BCD[j+3-:4];
end
end

{BCD, number} = {BCD, number} << 1;
end
endmodule
*/



//将16位二进制输入转化成20位BCD编码的模块，输入16bit， 输出20bit bcd编码 用于数码管显示具体数字
module toBCD_16_20(
    input wire[15:0] BinaryNumber, 
    output reg[19:0] BCD);

reg[15:0] number = 0;
integer i;
integer j;

always@(BinaryNumber) begin
number = BinaryNumber;
BCD = 0;

for(i = 1; i <= 15; i = i + 1) begin
{BCD, number} = {BCD, number} << 1;

for(j = 0; j <= 16; j = j + 4) begin
BCD[j+3-:4] = BCD[j+3-:4] > 4'd4 ? BCD[j+3-:4] + 2'b11 :BCD[j+3-:4];
end
end

{BCD, number} = {BCD, number} << 1;
end

endmodule
