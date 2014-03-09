module cnt(clk, top, cnt, i);
   parameter width=32;

   input clk;
   input [width-1:0] top;
   output reg [width-1:0] cnt;
   output reg i;


   initial begin
      cnt = 0;
      i = 0;
   end

   always @(posedge clk) begin
      cnt <= cnt + {{width-1{1'b0}}, 1'b1};
      if (cnt == top - {{width-1{1'b0}}, 1'b1}) begin
        i <= 1'b1;
        cnt <= {width{1'b0}};
      end else
        i <= 1'b0;
   end
endmodule

module cnt_sim_clk(clk);
   output reg clk;

   initial begin
      clk = 0;
      forever begin
         clk = #1 !clk;
      end
   end
endmodule

module cnt_sim;
   wire clk;
   wire i;
   reg [7:0] top;
   wire [7:0] cnt;

   initial top = 4;

   cnt_sim_clk cntIClk(clk);
   cnt #(.width(8)) cntI(clk, top, cnt, i);

   initial begin
      $dumpfile("cnt.vcd");
      $dumpvars();
      $monitor("T=%t, clk=%d cnt=%d i=%0d", $time, clk, cnt, i);
      #70 $finish;
   end
endmodule
