`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/19 22:35:47
// Design Name: 
// Module Name: light_
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


module light(
    input clk,
    input[2:0]  mode,
    output [7:0] led1,
    output [7:0] led2,
    output [7:0] led3
    );   
    reg[2:0]change1=3'b000, change2=3'b000,change3=3'b000;
    reg[2:0] last_mode=3'b0;
    reg en1=1,en2=1,en3=1;
    reg[1:0] m1=0,m2=0,m3=0;
    reg boolean=0;//check the direction of led
    Multi3_8 u1(en1,m1,change1,led1);
    Multi3_8 u2(en2,m2,change2,led2);
    Multi3_8 u3(en3,m3,change3,led3);
    //reg[7:0] rand=1'b0;
    integer count=0;
    integer cnt_change=0;
    parameter freq=20000000;
    
 
   
    always@(posedge clk)
    begin
    if(count <= freq)
    count=count+1;
    else
    begin
    count=0;
    case(mode)
    0:begin//from left to right at the same time
    m1=0;
    m2=0;
    m3=0;
    if(last_mode!=3'b0)
    begin
    change1=0;
    change2=0;
    change3=0;
    end
    last_mode=0;
    change1=change1+1;
    change2=change2+1;
    change3=change3+1;
    end
    1:begin  //from left to right one by one
    m1=0;
    m2=0;
    m3=0;
    if(last_mode!=3'b1)
        begin
        change1=0;
        change2=0;
        change3=0;
        end
        last_mode=1;
    if(change1!=7)
    begin 
    change1=change1+1;
    change2=0;
    change3=0;
    end
    else
    begin
        if(change2!=7)
        begin
        change1=7;
        change2=change2+1;
        change3=0;
        end
        else
        begin
            if(change3!=7)
             begin
             change1=7;
             change2=7;
             change3=change3+1;
             end
             else
             begin
                change1=0;
                change2=0;
                change3=0;
             end
       end
    end
    end
    2:begin// from left to right at the same time in another view
       m1=1;
       m2=1;
       m3=1;
       if(last_mode!=3'd2)
       begin
       change1=0;
       change2=0;
       change3=0;
        end
    last_mode=2;
    change1=change1+1;
    change2=change2+1;
    change3=change3+1;
    end
    3:begin//from middle to side
    m1=0;
    m2=2;
    m3=0;
    if(last_mode!=3)
    begin
    change1=7;
    change2=0;
    change3=0;
    end
    last_mode=3;
    if(change2<3)
    change2=change2+1;
    else
        begin
        if(change3<7)
        begin
        change1=change1-1;
        change3=change3+1;
        end
        else
            begin
            change1=7;
            change2=0;
            change3=0;
            end
        end
    end
    4:begin
    m1=2;
    m2=2;
    m3=2;
    if(last_mode!=4)
           begin
           change1=0;
           change2=0;
           change3=0;
           end
    last_mode=4;
    change1=change1+1;
    change2=change2+1;
    change3=change3+1;
    end
    5:begin
    
    m1=0;
    m2=0;
    m3=0;
    if(last_mode!=5)
        begin
        change1=0;
        change2=0;
        change3=0;
        end
    last_mode=5;
    if(boolean==0)
    begin
    change1=change1+1;
    change2=change2+1;
    change3=change3+1;
    if(change1==7)
    begin
    boolean=1;
    end
    end
    else
    begin
    change1=change1-1;
    change2=change2-1;
    change3=change3-1;
    if(change1==0)
    boolean=0;
    end
    end
    6:begin
        m1=0;
        m2=0;
        m3=0;
 if(last_mode!=6)
        begin
        change1=0;
        change2=0;
        change3=0;
        end
        last_mode=6;
        if(change1!=0)
        begin 
        change1=change1-1;
        end
        else
        begin
            if(change2!=0)
            begin
            change2=change2-1;
            end
            else
            begin
                if(change3!=0)
                 begin
                 change3=change3-1;
                 end
                 else
                 begin
                    change1=7;
                    change2=7;
                    change3=7;
                 end
           end
        end
    end
    default:
    begin
       m1=2;
       m2=2;
       m3=2;
       change1=4;
       change2=4;
       change3=4;
       end
    endcase
    end
    end
endmodule

module Multi3_8(
    input en,
    input [1:0]mode,
    input [2:0] in,
    output reg [7:0] out
    );
   always@(*)
   begin
   if(en==1)
   begin
   case(mode)
   2'd0:begin
        case(in)
        3'b000: out=8'b00000001;
        3'b001: out=8'b00000010;
        3'b010: out=8'b00000100;
        3'b011: out=8'b00001000;
        3'b100: out=8'b00010000;
        3'b101: out=8'b00100000;
        3'b110: out=8'b01000000;
        3'b111: out=8'b10000000;
        endcase
        end
   2'd1:begin 
        case(in)
        3'b000: out=8'b00000101;
        3'b001: out=8'b00001010;
        3'b010: out=8'b00010100;
        3'b011: out=8'b00101000;
        3'b100: out=8'b01010000;
        3'b101: out=8'b10100000;
        3'b110: out=8'b01000001;
        3'b111: out=8'b10000010;
        endcase
        end
    2'd2:begin
        case(in)
            3'b000: out=8'b00011000;
            3'b001: out=8'b00100100;
            3'b010: out=8'b01000010;
            3'b011: out=8'b10000001;
            default out=8'b00000000;
            endcase
      end
         
    endcase
    end
    end
    
endmodule


