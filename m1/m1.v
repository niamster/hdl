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

   wire clk;
   wire rstn;

   assign rstn = 1;

   clkdiv #(50000000) clkDiv(rstn, sys_clk, clk);
   m1 #(.width(8)) m1I(clk, leds);
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
   wire sys_clk;
   cnt_sim_clk simClk(sys_clk);

   reg rstn;
   initial begin
      rstn = 0;
      #1 rstn = 1;
   end

   wire clk;
   clkdiv #(50) clkDiv(rstn, sys_clk, clk);

   wire [7:0] leds;
   m1 #(.width(8)) m1I(clk, leds);

   initial begin
      $dumpfile("m1.vcd");
      $dumpvars();
      $monitor("T=%t, i=%0d", $time, clk);
      #1000 $finish;
   end
endmodule
