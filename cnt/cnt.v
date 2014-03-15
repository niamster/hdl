`define CNT_UP 1
`define CNT_DOWN 0

module cnt
  #(parameter width=32,
    parameter direction=`CNT_UP,
    parameter freerun=1)
   (input clk,
    input [width-1:0] top,
    input rstn,
    input rstn_it,

    output reg [width-1:0] cnt,
    output reg it);

   wire [width-1:0] one;
   wire [width-1:0] zero;
   wire [width-1:0] load;
   wire [width-1:0] tgt;
   wire [width-1:0] inc;

   reg [width-1:0] next;

   assign one = {{width-1{1'b0}}, 1'b1};
   assign zero = {width{1'b0}};
   assign load = (direction == `CNT_UP)?zero:top;
   assign tgt = (direction == `CNT_UP)?top:zero;
   assign inc = (direction == `CNT_UP)?one:-one;

   always @(clk or rstn or rstn_it) begin
      if (~rstn) begin
         next = load;
         cnt <= load;
         it <= 0;
      end else begin
         if (~rstn_it && !freerun)
           next = load-inc; // on next posedge of the clk, next will be equal to load
         else if (cnt == tgt && freerun)
           next = load;
         else if (clk)
           next = next + inc;

         if (clk)
           cnt <= next;

         if (next == tgt)
           it <= 1'b1;
         else if (~rstn_it)
           it <= 1'b0;
      end
   end
endmodule

module clkdiv
  #(parameter div=2)
   (input rstn,
    input iclk,
    output reg oclk);

   wire [31:0] top;
   wire [31:0] cnt;

   wire it;

   assign one = {{31{1'b0}}, 1'b1};
   assign zero = {31{1'b0}};
   assign top = div-one;
   assign rstn_it = 0;

   always @(posedge iclk or negedge rstn) begin
      if (~rstn)
        oclk <= 0;
      else begin
         if (cnt == top)
           oclk <= oclk + 1'b1;
      end
   end

   cnt cntI0(iclk, top, rstn, rstn_it, cnt, it);
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
   wire sys_clk;
   cnt_sim_clk simClk(sys_clk);

   // ------------

   reg rstn[3:0];
   reg rstn_it[3:0];
   reg [7:0] top[3:0];
   wire it[3:0];
   wire [7:0] cnt[3:0];

   genvar i;
   generate
      for (i=0; i<4; i=i+1) begin :gen0
         initial begin
            top[i] = 4;
            rstn_it[i] = 1;
            rstn[i] = 0;
         end
         initial #2 rstn[i] = 1;
         initial #65 rstn[i] = 0;

         always @(posedge it[i]) begin
           #1 rstn_it[i] = 1'b0;
           #1 rstn_it[i] = 1'b1;
         end
      end
   endgenerate

   initial #15 top[0] = 5;
   initial #50 top[1] = 5;
   initial #50 top[3] = 5;

   cnt #(.width(8),.direction(`CNT_UP),.freerun(1)) cntUpFree(sys_clk, top[0], rstn[0], rstn_it[0], cnt[0], it[0]);
   cnt #(.width(8),.direction(`CNT_UP),.freerun(0)) cntUpLocked(sys_clk, top[1], rstn[1], rstn_it[1], cnt[1], it[1]);
   cnt #(.width(8),.direction(`CNT_DOWN),.freerun(1)) cntDownFree(sys_clk, top[2], rstn[2], rstn_it[2], cnt[2], it[2]);
   cnt #(.width(8),.direction(`CNT_DOWN),.freerun(0)) cntDownLocked(sys_clk, top[3], rstn[3], rstn_it[3], cnt[3], it[3]);

   // ------------

   wire sys_clk_div_2;
   reg clkdiv_rstn;

   initial begin
      clkdiv_rstn = 0;
      #1 clkdiv_rstn = 1;
   end

   clkdiv clkDiv(clkdiv_rstn, sys_clk, sys_clk_div_2);

   // ------------

   initial begin
      $dumpfile("cnt.vcd");
      $dumpvars();
      $monitor("T=%t, clk=%d cnt[0]=%d i[0]=%0d cnt[1]=%d i[1]=%0d cnt[2]=%d i[2]=%0d cnt[3]=%d i[3]=%0d",
               $time, sys_clk,
               cnt[0], it[0],
               cnt[1], it[1],
               cnt[2], it[2],
               cnt[3], it[3]);
      #70 $finish;
   end
endmodule
