module top
(
 input x,
 input y,
 input cin,

 output reg A,
 output B,
 output reg cout
 );

 reg A1,cout1;

 initial begin
    A = 0;
    cout = 0;
 end

always @(posedge x) begin
    A1 <=  ~y + &cin;
end
always @(negedge x) begin
    cout1 <= cin ? |y : ^A;
end

always @(*) begin
    if (x)
        A <=  A1|y~&cin;
end
always @(*) begin
    if (~x)
        cout <=  cout1&cin~|y;
end

bb ubb (cin,y,x,B);

endmodule

(* blackbox *) module bb(in1, in2, clk, out1);
 input in1;
 input in2;
 input clk;

 output reg out1;

 always @(posedge clk)
	out1 <= in1 & in2;
endmodule
