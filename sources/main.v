`timescale 1ns / 1ps

module main(input clk, input enable,input admin,         //主程序
        input[3:0] row, output  [3:0] col,               //小键盘
        input up,input down,                             //上下键（五个
        input left,input mid,input right,               //中间三个键
        output [7:0] tube_char, output [7:0] tube_switch,
        output[7:0] led1,output[7:0] led2,output[7:0] led3,
        output mus);

//////////////////////////////////////////////////////////////////////////////////////
//小键盘模块，带防抖
wire [4:0]key;
wire [3:0]key_col;
key16 bind_key(clk,enable,row,key_col,key); 
assign col=key_col;
reg pass_admin;

reg passage_change_able;
reg [5:0] current_passage;
reg [5:0] next_passage;
reg [4:0]music_mode=0;
Music music(clk,music_mode,mus);

reg[2:0]light_mode=7;
light show(clk, light_mode, led1, led2, led3); 
reg [5:0] rest_goods[0:63];
reg [10:0] pric_goods[0:63];

parameter BOARD   = 3'b000;
parameter ON_SHOW = 3'b001;
parameter ON_SALE = 3'b010;
parameter FAIL_PAY= 3'b011;
parameter RELOAD  = 3'b100;
parameter CHECK_F  = 3'b101;
parameter CHECK_SALE   = 3'b110;
parameter SUCCESS  = 3'b111;
////////////////////////////////////////////////////////////////////////////////////
//分频
reg [19:0] cnt; 
always @ (posedge clk, negedge enable)
  if (!enable)
    cnt = 0;
  else
    cnt = cnt + 1;
////////////////////////////////////////////////////////////////////////////////
///更新状态机
wire check = cnt[19];
reg [5:0] current_state;
reg [5:0] next_state;
//assign res=current_state;
reg [15:0]number;
reg [11:0] clock_cnt;
digital_tube dt_led(tube_char,tube_switch,clk,up,down, next_passage,current_state,number,clock_cnt);
reg easy_mode;
always @ (posedge check, negedge enable)
begin
  if (!enable)
  begin
    current_passage=6'b000001;
    current_state = BOARD;
  end
  else
  begin
    current_state = next_state;
  end
end

/***
*A 购买     确认
*B 返回显示 取消
*C         补货
*D         检查状态
***/
parameter KEY_NU= 5'b00000;
parameter KEY_A = 5'b00100;
parameter KEY_B = 5'b01000;
parameter KEY_C = 5'b01100;
parameter KEY_D = 5'b10000;
parameter KEY_E = 5'b01111;
parameter TOTAL_PASSAGES = 12;
//////////////////////////////////////////////////////////////////////////////
//倒计时
reg clock_start;
reg clock_end;
////////////////////////////////////////////////////////////////////////////////
////模式切换
reg [13:0]board_time;//90S
wire board_mode;
assign board_mode=board_time[13];

reg [6:0] number_sold[6:0];
reg [17:0] price_sold;
reg [5:0] pass_word=0;
/////////////////////////////////////////////////////////////////////////////
//主消息监听
reg money_change_able;
reg [10:0] need_to_pay=10'b1111111111;
reg [10:0] change_money;
reg [1:0] money;
reg [3:0]reg_left=0; 
reg [3:0]reg_mid=0; 
reg [3:0]reg_right=0; 
reg [3:0]reg_u=0; 
reg [3:0]reg_d=0; 
reg made_left;
reg made_mid;
reg made_right;
reg made_u;
reg made_d;
reg multiple_goods;
reg [1:0]repeat_pwd=0;
reg music_flag;
always @ (posedge check,negedge enable)
if(!enable)
begin : BLOCK_init_rest_array
    integer i;
    rest_goods[0]=6'b000000;
    for(i=1;i<=64;i=i+1) 
    begin
        number_sold[i]=0;
        rest_goods[i]=6'b000001;
    end
    price_sold=0;
    
    rest_goods[2]=6'b100001;
    rest_goods[3]=6'b111111;
    rest_goods[4]=6'b000000;
    rest_goods[5]=6'b001100;
light_mode=7;
music_mode=0;
    pric_goods[1]=35;
    pric_goods[2]=60;
    pric_goods[3]=130;
    pric_goods[4]=30;
    pric_goods[5]=500;
    pric_goods[6]=15;
    pric_goods[7]=10;
    pric_goods[8]=5;
    pric_goods[9]=30;
    pric_goods[10]=635;
    pric_goods[11]=550;
    pric_goods[12]=280;
    
    need_to_pay=10'b1111111111;
    next_state=BOARD;
    
    pass_word=3'b000;
    repeat_pwd=0;
end
else
begin
    current_passage=next_passage;
    if(rest_goods[current_passage]==0 && next_state!=RELOAD)
    begin
        if(rest_goods[current_passage]==TOTAL_PASSAGES) current_passage=1;
        else current_passage=current_passage+1;
    end
    case(key)
        5'b01001: if(pass_word==3'b000)pass_word=3'b001;
        5'b00011: if(pass_word==3'b001)pass_word=3'b010;
        5'b00110: if(pass_word==3'b010 || pass_word==3'b011)
                    begin 
                        if(repeat_pwd==2)
                        begin
                            pass_word=3'b100;
                            repeat_pwd=0;
                        end
                        else 
                        begin
                            repeat_pwd=1;
                            pass_word=3'b011;
                        end
                    end 
        5'b00111: if(pass_word==3'b100)pass_word=3'b101;
        5'b01110: if(pass_word==3'b101)pass_word=3'b110;
        5'b01010: if(pass_word==3'b110)pass_admin=1;
        5'b00000: if(repeat_pwd==1)repeat_pwd=2;
        5'b00001: begin pass_word=3'b000; pass_admin=0; end
    endcase
    
    if(!clock_end) clock_cnt=clock_cnt-1;
    if(clock_start)
    begin
        clock_cnt=1000;
        clock_start=0;
    end
    if(clock_cnt==0) clock_end=1;
    
   if(current_state!=BOARD) board_time=board_time+1;
   if(key==KEY_NU && board_mode) begin next_state=BOARD; end
   if(key!=KEY_NU)  board_time=0;
   if(next_state==BOARD && key!=KEY_NU )next_state=ON_SHOW;
   if(next_state!=ON_SALE)
   case(key)
      KEY_A: next_state=ON_SALE;
      KEY_B: if(next_state!=FAIL_PAY)next_state=ON_SHOW;
      KEY_C: if(admin || pass_admin) next_state=RELOAD;
      KEY_D: if(admin || pass_admin) next_state=CHECK_SALE;
      KEY_E: if(admin || pass_admin) next_state=CHECK_F;
      5'b1:if(next_state==FAIL_PAY)next_state=ON_SHOW;
      default:begin music_mode=key;  end
   endcase
   else
   begin
      case(key)
         KEY_B: next_state=FAIL_PAY;
   endcase
         music_mode=key;
   end
    if(current_state!=ON_SHOW) passage_change_able=0;
    if(current_state!=ON_SALE) need_to_pay=10'b1111111111;
    easy_mode=0;
    case(current_state)
    BOARD:  begin music_mode=19;light_mode=2; end
            ON_SHOW: begin  
                            light_mode=1;
                            passage_change_able=1; 
                            number=rest_goods[next_passage];
                     end
            RELOAD : begin
            easy_mode=1;
                            music_mode=17;
                            passage_change_able=1; 
                            light_mode=2;
                            if(!reg_mid)made_mid=0;
                            if(reg_mid[3] && !made_mid) begin
                                   rest_goods[next_passage]=rest_goods[next_passage]+1;
                                   made_mid=1;
                            end
                            number=rest_goods[next_passage];
                     end
            CHECK_SALE  : 
                     begin
                        number=price_sold;
                        music_mode=18;
                        light_mode=7;
                     end
            ON_SALE: begin  
                            if(!reg_left)made_left=0;
                            if(!reg_right)made_right=0;
                            if(!reg_mid)made_mid=0;
                            if(!reg_u)made_u=0;
                            if(!reg_d)made_d=0;
                            light_mode=3;
                            if(need_to_pay==10'b1111111111)begin
                                multiple_goods=0;
                                need_to_pay=pric_goods[next_passage]+100;
                                clock_start=1;
                                clock_end=0;
                                clock_cnt=1000;
                            end
                            if(reg_left[3] && !made_left) begin
                                need_to_pay=need_to_pay-5;
                                made_left=1;
                            end
                            if(reg_mid[3] && !made_mid) begin
                                need_to_pay=need_to_pay-10;
                                made_mid=1;
                            end
                            if(reg_right[3] && !made_right) begin
                                need_to_pay=need_to_pay-100;
                                made_right=1;
                            end
                            if(reg_u[3] && !made_u && multiple_goods<rest_goods[next_passage]-1) begin
                                need_to_pay=need_to_pay+pric_goods[next_passage];
                                made_u=1;
                                multiple_goods=multiple_goods+1;
                            end
                            if(reg_d[3] && !made_d && multiple_goods) begin
                                need_to_pay=need_to_pay-pric_goods[next_passage];
                                made_d=1;
                                multiple_goods=multiple_goods-1;
                            end
                            change_money=(multiple_goods+1)*pric_goods[next_passage]+100-need_to_pay;
                            if(need_to_pay < 101)
                            begin
                                change_money=100-need_to_pay;
                                rest_goods[next_passage]=rest_goods[next_passage]-1-multiple_goods;
                                need_to_pay=10'b1111111111;
                                clock_cnt=1000;
                                number_sold[next_passage]=number_sold[next_passage]+1+multiple_goods;
                                price_sold=(1+multiple_goods)*pric_goods[next_passage]+price_sold;
                                //if((1+multiple_goods)*pric_goods[next_passage]>500) next_state=RANDOM;
                                next_state=SUCCESS;
                            end
                            if(clock_end)
                            begin
                                next_state=FAIL_PAY;
                                change_money=(multiple_goods+1)*pric_goods[next_passage]+100-need_to_pay;
                            end
                                                                
                            number=need_to_pay-100;
                     end
            SUCCESS: begin
                        need_to_pay=10'b1111111111;
                        light_mode=6;
                        clock_end=0;
                        music_mode=18;
                        number=change_money;
                     end
            CHECK_F: begin
                        light_mode=4;
                        passage_change_able=1; 
                        number=number_sold[next_passage];
                     end
            FAIL_PAY:   begin
                            light_mode=5;
                            clock_end=0;
                            number=change_money;
                        end
    endcase
end
///////////////////////////////////////////////////////////////////////////
///按钮
reg [3:0]reg_up=0; 
reg [3:0]reg_down=0;    // 扫描计数器,防抖
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

always @ (posedge check)
begin
      if(left!=0)
      begin
        if(reg_left[3]!=1)
          reg_left=reg_left+1;
      end
      else reg_left=0;
      if(mid!=0)
      begin
        if(reg_mid[3]!=1)
          reg_mid=reg_mid+1;
      end
      else reg_mid=0;
      if(right!=0)
      begin
        if(reg_right[3]!=1)
          reg_right=reg_right+1;
      end
      else reg_right=0;
      if(up!=0)
      begin
        if(reg_u[3]!=1)
          reg_u=reg_u+1;
      end
      else reg_u=0;
      if(down!=0)
      begin
        if(reg_d[3]!=1)
          reg_d=reg_d+1;
      end
      else reg_d=0;
end
///////////////////////////////////////////////////////////////////
///货道选择，不显示无货货道
integer repeat_passage;
always @ (posedge reg_up[3],negedge enable)
if(!enable)next_passage=6'b000001;
else if(passage_change_able) 
begin
    if (reg_down[3]==1)begin
    if(!easy_mode)
    begin
        repeat_passage=0;
        if(next_passage==1)next_passage=TOTAL_PASSAGES;
        else next_passage=(next_passage-1);
        while(rest_goods[next_passage]==0 & next_passage!=0)
        begin
            if(next_passage==1)next_passage=TOTAL_PASSAGES;
            else next_passage=(next_passage-1);
            repeat_passage=repeat_passage+1;
            if(repeat_passage>TOTAL_PASSAGES+1) next_passage=6'b000000;
        end
    end
                else 
                        if(next_passage==1)next_passage=TOTAL_PASSAGES;
                        else next_passage=(next_passage-1);end
    else begin
                            if(!easy_mode)
    begin
        repeat_passage=0;
        if(next_passage==TOTAL_PASSAGES)  next_passage=1;
        else next_passage=next_passage+1;
        while(rest_goods[next_passage]==0 & next_passage!=0)
        begin
            if(next_passage==TOTAL_PASSAGES)  next_passage=1;
            else next_passage=next_passage+1;
            repeat_passage=repeat_passage+1;
            if(repeat_passage>TOTAL_PASSAGES+1) next_passage=6'b000000;
        end
    end
                        else 
                                if(next_passage==TOTAL_PASSAGES)  next_passage=1;
                                else next_passage=next_passage+1;end
end
///////////////////////////////////////////////////
//////////变量
//always @(posedge check) led2=music_mode;

endmodule