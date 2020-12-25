module view(input enable,input reset,input up,input down,input clk,input [5:0] rest,output [5:0]s);
parameter SOLD_OUT = 6'b000000; //售罄
parameter PASSAGE_01 = 6'b000001; //cola
parameter PASSAGE_02 = 6'b000010; //dog_food
parameter PASSAGE_03 = 6'b000011; //pie
parameter PASSAGE_04 = 6'b000100; //rye bun
parameter PASSAGE_05 = 6'b000101; //soya
parameter PASSAGE_06 = 6'b000110; //cob
parameter PASSAGE_07 = 6'b000111; //frie
parameter PASSAGE_08 = 6'b001000; //hydra
parameter PASSAGE_09 = 6'b001001; //cake
parameter PASSAGE_10 = 6'b001010; //nacho
parameter PASSAGE_11 = 6'b001011; //cheating_paper
parameter PASSAGE_12 = 6'b001100; //chocolate_bar
reg [19:0] cnt;  //分频
always @ (posedge clk, negedge reset)
  if (!reset)
    cnt = 0;
  else
    cnt = cnt + 1;
    
wire check = cnt[19];
reg [5:0] current_state, next_state;
assign s=current_state;

always @ (posedge check, negedge reset)
  if (!reset)
    current_state = PASSAGE_01;
  else
    current_state = next_state;
wire [1:0]re;
reg [3:0]reg_up=0; 
reg [3:0]reg_down=0;    // 扫描计数器
assign re[0]=reg_up[3];
assign re[1]=reg_down[3];
always @ (posedge check)
  begin
      if(up!=0)begin
        if(reg_up[3]!=1)
          reg_up=reg_up+1;end
      else reg_up=0;
      if(down!=0)begin
        if(reg_down[3]!=1)
          reg_down=reg_down+1;
          else reg_up[3]=1;
          end
      else reg_down=0;
end
always @ (posedge re,negedge reset)
if(!reset)next_state=PASSAGE_01;
else if(enable)
  case (current_state)
    PASSAGE_01 :
        if (reg_down[3]==1)
          next_state = PASSAGE_12;
        else
          next_state = PASSAGE_02;
    PASSAGE_02 :
        if (reg_down[3]==1)
          next_state = PASSAGE_01;
        else
          next_state = PASSAGE_03;
    PASSAGE_03 :                      
        if (reg_down[3]==1)
          next_state = PASSAGE_02;
        else
          next_state = PASSAGE_04;
    PASSAGE_04 :                      
        if (reg_down[3]==1)
          next_state = PASSAGE_03;
        else
          next_state = PASSAGE_05;
    PASSAGE_05 :                      
        if (reg_down[3]==1)
          next_state = PASSAGE_04;
        else
          next_state = PASSAGE_06;
    PASSAGE_06 :                      
        if (reg_down[3]==1)
          next_state = PASSAGE_05;
        else
          next_state = PASSAGE_07;
    PASSAGE_07 :                      
        if (reg_down[3]==1)
          next_state = PASSAGE_06;
        else
          next_state = PASSAGE_08;
    PASSAGE_08 :                      
        if (reg_down[3]==1)
          next_state = PASSAGE_07;
        else
          next_state = PASSAGE_09;
    PASSAGE_09 :                      
        if (reg_down[3]==1)
          next_state = PASSAGE_08;
        else
          next_state = PASSAGE_10;
    PASSAGE_10 :                      
        if (reg_down[3]==1)
          next_state = PASSAGE_09;
        else
          next_state = PASSAGE_11;
    PASSAGE_11 :                      
        if (reg_down[3]==1)
          next_state = PASSAGE_10;
        else
          next_state = PASSAGE_12;
    PASSAGE_12 :                      
        if (reg_down[3]==1)
          next_state = PASSAGE_11;
        else
          next_state = PASSAGE_01;
  endcase
endmodule