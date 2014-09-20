module spwm
  #(parameter cwidth=32,
    parameter kwidth=10)
    (input clk,
     input rstn,
     input [cwidth-1:0] d_init,
     input [cwidth-1:0] d_delta,
     input [cwidth-1:0] d_pwm,
     input [kwidth-1:0] k_max,
     input updown,
     input d0_level,
     input clr_it,

     output reg io,
     output it);

  reg  [kwidth-1:0] k_curr;
  wire [kwidth-1:0] k_next;

  wire [cwidth-1:0] d_curr;
  reg  [cwidth-1:0] d0;
  wire [cwidth-1:0] d0_next;
  wire [cwidth-1:0] d0_prev;

  reg down;

  wire d1_level;

  assign k_next = k_curr + {{kwidth-1{1'b0}}, 1'b1};
  assign d0_next = d0 + d_delta;
  assign d0_prev = d0 - d_delta;
  assign d1_level = d0_level ^ 1'b1;

  cnt #(.width(cwidth)) cntD(.clk(clk),
                             .top(d_pwm), .rstn(rstn), .clr_it(clr_it), .start(1'b1), .freerun(1'b1),
                             .cnt(d_curr),
                             .it(it));

  always @(posedge clk, negedge rstn) begin
    if (~rstn) begin
      io <= d0_level;
      d0 <= d_init;
      k_curr <= 0;
      down <= 0;
    end else begin
      if (d_curr == d0)
        io <= d1_level;

      if (d_curr == d_pwm) begin
        io <= d0_level;
        if (k_curr == k_max) begin
          if (updown) begin
            down <= down ^ 1'b1;
            if (down)
              d0 <= d0_next;
            else
              d0 <= d0_prev;
          end else
            d0 <= d_init;
          k_curr <= 0;
        end else begin
          if (down)
            d0 <= d0_prev;
          else
            d0 <= d0_next;
          k_curr <= k_next;
        end
      end
    end
  end
endmodule

module spwm_de0nano(sys_clk, rstn, leds);
  input sys_clk;
  input rstn;
  output [7:0] leds;

  assign leds[7:6] = 2'd0;

  localparam d_init    = 32'd0;
  localparam d_delta   = 32'd2500;
  localparam d_pwm    = 32'd500000;
  localparam k_max     = 32'd200;

  spwm spwmI0(.clk(sys_clk),
              .rstn(rstn),
              .d_init(d_init),
              .d_delta(d_delta),
              .d_pwm(d_pwm),
              .k_max(k_max),
              .updown(1'b0),
              .d0_level(1'b0),
              .io(leds[0]),
              .clr_it(rstn));
  spwm spwmI1(.clk(sys_clk),
              .rstn(rstn),
              .d_init(d_init),
              .d_delta(d_delta),
              .d_pwm(d_pwm),
              .k_max(k_max),
              .updown(1'b0),
              .d0_level(1'b1),
              .io(leds[1]),
              .clr_it(rstn));
  spwm spwmI2(.clk(sys_clk),
              .rstn(rstn),
              .d_init(d_init),
              .d_delta(d_delta),
              .d_pwm(d_pwm),
              .k_max(k_max),
              .updown(1'b1),
              .d0_level(1'b0),
              .io(leds[2]),
              .clr_it(rstn));

  spwm spwmI3(.clk(sys_clk),
              .rstn(rstn),
              .d_init(32'd25000000),
              .d_delta(32'd0),
              .d_pwm(32'd50000000),
              .k_max(32'd1),
              .updown(1'b0),
              .d0_level(1'b0),
              .io(leds[3]),
              .clr_it(rstn));

  spwm spwmI4(.clk(sys_clk),
              .rstn(rstn),
              .d_init(32'd1000),
              .d_delta(32'd0),
              .d_pwm(32'd5000),
              .k_max(32'd1),
              .updown(1'b0),
              .d0_level(1'b1),
              .io(leds[4]),
              .clr_it(rstn));
  spwm spwmI5(.clk(sys_clk),
              .rstn(rstn),
              .d_init(32'd3000),
              .d_delta(32'd0),
              .d_pwm(32'd5000),
              .k_max(32'd1),
              .updown(1'b0),
              .d0_level(1'b1),
              .io(leds[5]),
              .clr_it(rstn));
endmodule

module spwm_sim;
  wire sys_clk;
  sim_clk simClk(sys_clk);

  reg rstn;
  initial begin
    rstn = 0;
    #2 rstn = 1;
  end

  wire [1:0] leds;

  localparam d_init    = 0;
  localparam d_delta   = 5;
  localparam d_pwm    = 50;
  localparam k_max     = 10;
  localparam updown    = 1'b1;
  localparam d0_level  = 0;

  spwm spwmI0(.clk(sys_clk),
              .rstn(rstn),
              .d_init(d_init),
              .d_delta(d_delta),
              .d_pwm(d_pwm),
              .k_max(k_max),
              .updown(updown),
              .d0_level(d0_level),
              .io(leds[0]));

  spwm spwmI1(.clk(sys_clk),
              .rstn(rstn),
              .d_init(50),
              .d_delta(0),
              .d_pwm(100),
              .k_max(1),
              .updown(1'b0),
              .d0_level(d0_level),
              .io(leds[1]));

  initial begin
    $dumpfile(`VCD_PATH);
    $dumpvars();
    // $monitor("T=%t, i=%0d", $time, clk);
    #5000 $finish;
  end
endmodule
