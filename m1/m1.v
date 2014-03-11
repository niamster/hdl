module m1(clk, leds);
   parameter width=8;

   input clk;
   output reg [width-1:0] leds;

   initial begin
      leds = 0;
   end

   always @(posedge clk) begin
      leds <= leds + {{width-1{1'b0}}, 1'b1};
   end
endmodule

module m1_de0nano(sys_clk, leds);
   input sys_clk;
   output [7:0] leds;

   wire [31:0] top;
   wire [31:0] cnt;
   wire i;

   assign top = 50000000;

   cnt #(.width(32)) m1CntI(sys_clk, top, cnt, i);
   m1 #(.width(8)) m1I(i, leds);
endmodule

module m1_sim_clk(clk);
   output reg clk;

   initial begin
      clk = 0;
      forever begin
         clk = #1 !clk;
      end
   end
endmodule

module m1_sim;
   wire clk;
   wire [7:0] leds;

   wire [31:0] top;
   wire [31:0] cnt;
   wire i;

   assign top = 50;

   m1_sim_clk m1IClk(clk);
   cnt #(.width(32)) m1CntI(clk, top, cnt, i);
   m1 #(.width(8)) m1I(i, leds);

   initial begin
      $dumpfile("m1.vcd");
      $dumpvars();
      $monitor("T=%t, i=%0d", $time, i);
      #1000 $finish;
   end
endmodule
