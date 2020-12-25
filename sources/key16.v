`timescale 1ns / 1ps

module key16(
  input            clk,   //时钟
  input            enable,  //开关，1的时候才有输出信号
    input      [3:0] row,  //扫描结果 [0123]K3  L3  J4  K4 
    output reg [3:0] col, //扫描信号 [0123]L5  J6  K6  M2
  output reg [4:0] key  // 输出的键盘值
);
reg [19:0] cnt;  //分频
always @ (posedge clk, negedge enable)
  if (!enable)
    cnt = 0;
  else
    cnt = cnt + 1;
wire check = cnt[19];

parameter NO_KEY_PRESSED = 3'b000;  // 没有按键按下  
parameter SCAN_COL0      = 3'b001;  // 扫描0列
parameter SCAN_COL1      = 3'b010;  // 扫描1 
parameter SCAN_COL2      = 3'b011;  // 扫描2 
parameter SCAN_COL3      = 3'b100;  // 扫描3
parameter KEY_PRESSED    = 3'b101;  // 有按键按下
 
reg [2:0] current_state, next_state;    // 现态、次态
 
always @ (posedge check, negedge enable)
  if (!enable)
    current_state = NO_KEY_PRESSED;
  else
    current_state = next_state;
 
always @ *
  case (current_state)
    NO_KEY_PRESSED :                    // 没有按键按下
        if (row != 4'hF)
          next_state = SCAN_COL0;
        else
            next_state = NO_KEY_PRESSED;
    SCAN_COL0 :                         // 扫描0列
        if (row != 4'hF)
          next_state = KEY_PRESSED;
        else
          next_state = SCAN_COL1;
    SCAN_COL1 :                         // 扫描1
        if (row != 4'hF)
          next_state = KEY_PRESSED;
        else
          next_state = SCAN_COL2;    
    SCAN_COL2 :                         // 扫描2
        if (row != 4'hF)
          next_state = KEY_PRESSED;
        else
          next_state = SCAN_COL3;
    SCAN_COL3 :                         // 扫描3
        if (row != 4'hF)
          next_state = KEY_PRESSED;
        else
          next_state = NO_KEY_PRESSED;
    KEY_PRESSED :                       // 有按键按下
        if (row != 4'hF)
          next_state = KEY_PRESSED;
        else
          next_state = NO_KEY_PRESSED;                      
  endcase

reg       key_pressed_flag;             // 键盘按下标志
reg [3:0] col_val, row_val;             // 列、行
 reg [3:0]void=0;                       // 扫描计数器
always @ (posedge check, negedge enable)
  begin
      if(row==4'hf)
          void=void+1;
      else void=0;
      if(void[3])
          key_pressed_flag=0;            //判断扫描是否全空
  if (!enable || next_state==NO_KEY_PRESSED)
  begin
    col              = 4'h0;
    key_pressed_flag =    0;
  end
  else
    case (next_state)
      SCAN_COL0 :                       // 扫描第0列
        col = 4'b1110;
      SCAN_COL1 :                       // 扫描第1列
        col = 4'b1101;
      SCAN_COL2 :                       // 扫描第2列
        col = 4'b1011;
      SCAN_COL3 :                       // 扫描第3列
        col = 4'b0111;
      KEY_PRESSED :                     // 有按键按下
      begin
        col_val          = col;        // 锁存列值
        row_val          = row;        // 锁存行值
        key_pressed_flag = 1;          // 置键盘按下标志  
      end
    endcase
end

always @ (posedge check, negedge enable)
  if (!enable || !key_pressed_flag)
    key = 5'b0;
  else
    case ({col_val, row_val})
      8'b11101110 : key = 5'b00001;
      8'b11011110 : key = 5'b00010;
      8'b10111110 : key = 5'b00011;
      8'b01111110 : key = 5'b00100;
      8'b11101101 : key = 5'b00101;
      8'b11011101 : key = 5'b00110;
      8'b10111101 : key = 5'b00111;
      8'b01111101 : key = 5'b01000;
      8'b11101011 : key = 5'b01001;
      8'b11011011 : key = 5'b01010;
      8'b10111011 : key = 5'b01011;
      8'b01111011 : key = 5'b01100;
      8'b11100111 : key = 5'b01101;
      8'b11010111 : key = 5'b01110;
      8'b10110111 : key = 5'b01111;
      8'b01110111 : key = 5'b10000;
    endcase
endmodule
