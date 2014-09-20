#!/usr/bin/env ruby

require 'pp'
require 'gtk3'

class Spwm
  attr_accessor :updown

  attr_reader :f_main
  attr_reader :f_pwm
  attr_reader :dc_init
  attr_reader :dc_term
  attr_reader :dc_inc

  attr_reader :k
  attr_reader :d_pwm
  attr_reader :d_init
  attr_reader :d_term
  attr_reader :d_inc

  %w(d_pwm d_init d_term d_inc).each do |meth|
    define_method(meth+'_xs') do
      to_xs(send(meth))
    end
  end

  def f_main=(value)
    raise Exception, "Fmain must be greater than 0" if value <= 0
    @f_main = value
  end

  def f_pwm=(value)
    raise Exception, "Fpwm must be greater than 0" if value <= 0
    @f_pwm = value
  end

  def dc_init=(value)
    raise Exception, "Initial duty cycle must be greater than 0 and less than 100" if (value < 0 or value > 100)
    @dc_init = value
  end

  def dc_term=(value)
    raise Exception, "Terminal duty cycle must be greater than 0 and less than 100" if (value < 0 or value > 100)
    @dc_term = value
  end

  def dc_inc=(value)
    raise Exception, "Duty cycle increment must be greater than 0 and less than 100" if (value < 0 or value > 100)
    @dc_inc = value
  end

  def scale
    @d_pwm
  end

  def to_xs(value)
    ns = 10**9 * value / @f_main
    return "#{ns/10**9}S" if ns >= 10**9
    return "#{ns/10**6}mS" if ns >= 10**6
    return "#{ns/10**3}uS" if ns >= 10**3
    return "#{ns}nS"
  end

  def calc_init
    raise Exception, "Fmain must be at least 2 times greater than Fpwm" if @f_main < @f_pwm*2
    t_main_ns = 10**9 / @f_main
    t_pwm_ns = 10**9 / @f_pwm
    @d_pwm = (t_pwm_ns / t_main_ns).ceil
    if @dc_init + @dc_inc > 100 or @dc_init + @dc_inc > @dc_term then
      raise Exception, "Duty cycle increment is too big"
    end
    raise Exception, "Initial duty cycle is bigger than terminal" if @dc_init > @dc_term
    @d_init = ((@d_pwm * @dc_init)/100).ceil
    @d_inc = ((@d_pwm * @dc_inc)/100).ceil
    @d_term = ((@d_pwm * @dc_term)/100).ceil
  end

  def calc_one
    d0 = @d_init
    r = [d0]
    for @k in 1..1024
      break if @d_inc == 0
      d0 += @d_inc
      break if d0 > @d_term
      r += [d0]
      break if d0 == @d_term
    end
    if @updown then
      @k.times do
        d0 = d0 - @d_inc
        r += [d0]
      end
    end
    return r
  end

  def calc(iterations)
    calc_init
    r = []
    iterations.times do
      r += calc_one
    end
    return r
  end
end

class Area < Gtk::DrawingArea
  attr_accessor :values
  attr_accessor :scale

  def initialize
    super
    @values = nil
    @scale = nil
    set_size_request 300, 400
    signal_connect("draw") do |widget, event|
      configure
      draw
    end
  end

  def configure
    @cr = window.create_cairo_context
    @w = allocation.width
    @h = allocation.height
  end

  def yaxis
    @cr.set_font_size 13
    text = "Duty Cycle (%) / Level"
    te = @cr.text_extents text
    x = 10 + te.height
    y = 10 + te.width
    @y_max = 15
    @x_max = @w-15
    @x0 = x+15

    @cr.move_to x, y
    @cr.save
    @cr.rotate -Math::PI/2
    @cr.show_text text
    @cr.stroke
    @cr.restore

    @cr.set_line_width 0.5
    @cr.move_to @x0, @h
    @cr.line_to @x0, 5
    @cr.stroke

    @cr.save
    @cr.set_line_width 1
    @cr.set_dash [14.0, 6.0]
    @cr.move_to @x0, @y_max
    @cr.line_to @x_max, @y_max
    @cr.stroke
    @cr.restore
  end

  def xaxis
    @cr.set_font_size 13
    text = "Iterations / Time"
    te = @cr.text_extents text
    x = @w - 10 - te.width
    y = @h - 10 - te.height
    @y_max = 15
    @x_max = @w-15
    @y0 = y-15

    @cr.move_to x, y
    @cr.show_text text
    @cr.set_line_width 0.5
    @cr.move_to 5, @y0
    @cr.line_to @w, @y0
    @cr.stroke

    @cr.save
    @cr.set_line_width 1
    @cr.set_dash [14.0, 6.0]
    @cr.move_to @x_max, @y0
    @cr.line_to @x_max, @y_max
    @cr.stroke
    @cr.restore
  end

  def draw
    xaxis
    yaxis

    return if @values == nil

    xscale = [@x_max/@values.length, 1].max
    yscale = (@y0-@y_max)/100
    xidx = @x0
    pyidx, pxidx = 0, 0
    @values.each do |v|
      yidx = @y0 - ((v*100)/@scale)*yscale
      @cr.set_source_rgb 0, 0, 1
      @cr.arc xidx, yidx, 2, 0, 2*Math::PI
      @cr.fill
      @cr.stroke
      if pyidx != 0 and pxidx != 0 then
        @cr.set_source_rgb 0, 1, 0
        @cr.move_to pxidx, pyidx
        @cr.line_to xidx, yidx
        @cr.stroke

        d0 = xscale*v/@scale
        d1 = xscale

        @cr.set_source_rgba 1, 0, 0, 0.4
        @cr.rectangle pxidx, @y0/4, d0, @y0/2
        @cr.fill
        @cr.stroke

        @cr.set_source_rgb 1, 0, 0
        @cr.move_to pxidx, 3*@y0/4
        @cr.line_to pxidx, @y0/4

        @cr.move_to pxidx, @y0/4
        @cr.line_to pxidx+d0, @y0/4

        @cr.move_to pxidx+d0, @y0/4
        @cr.line_to pxidx+d0, 3*@y0/4

        @cr.move_to pxidx+d0, 3*@y0/4
        @cr.line_to pxidx+d1, 3*@y0/4
        @cr.stroke
      end

      pyidx = yidx
      pxidx = xidx
      xidx += xscale
    end
  end

  def redraw
    rect = Gdk::Rectangle.new(0, 0, @w, @h)
    window.invalidate rect, true
  end
end

class Window < Gtk::Window
  def initialize
    super
    @spwm = Spwm.new
    init_ui
    init_widgets
    init_window
  end

  def init_ui
    set_default_width 800
    set_window_position :center
  end

  def init_window
    signal_connect("destroy") do
      Gtk.main_quit
    end
    show_all
    Gtk.main
  end

  def init_element(box, entry, name)
    vbox = Gtk::Box.new :vertical, 0
    vbox.add Gtk::Label.new name
    vbox.add entry
    box.add vbox
    return entry
  end

  def init_entry(box, name, value)
    entry = Gtk::Entry.new
    entry.text = value
    init_element box, entry, name
    return entry
  end

  def init_checkbox(box, name, value)
    chbox = Gtk::CheckButton.new
    chbox.active = value
    init_element box, chbox, name
    return chbox
  end

  def error(msg)
    dialog = Gtk::Dialog.new(title: msg, parent: @this,
                    flags: Gtk::Dialog::Flags::MODAL,
                    buttons: [[Gtk::Stock::OK, Gtk::ResponseType::CLOSE]])
    dialog.run do
      dialog.destroy
    end
  end

  def init_widgets
    vbox = Gtk::Box.new :vertical, 0
    add vbox

    area = Area.new
    vbox.add area

    formula = Gtk::Label.new "D(k+1) = D(k) + Dinc"
    vbox.add formula
    vars = Gtk::Label.new ""
    vbox.add vars

    hbox = Gtk::Box.new :horizontal, 0
    vbox.add hbox

    f_main = init_entry hbox, "Fmain(HZ)", "50000000"
    f_pwm = init_entry hbox, "Fpwm(HZ)", "10000"
    dc_init = init_entry hbox, "Initial duty cycle(%)", "50"
    dc_term = init_entry hbox, "Terminal duty cycle(%)", "100"
    dc_inc = init_entry hbox, "Duty cycle increment(% of whole cycle)", "0"
    updown = init_checkbox hbox, "up-down", false

    button = Gtk::Button.new label: "calculate"
    button.signal_connect("clicked") do
      begin
        @spwm.f_main = f_main.text.to_i
        @spwm.f_pwm = f_pwm.text.to_f
        @spwm.dc_init = dc_init.text.to_f
        @spwm.dc_term = dc_term.text.to_f
        @spwm.dc_inc = dc_inc.text.to_f
        @spwm.updown = updown.active?

        area.values = @spwm.calc 2
        area.scale = @spwm.scale
      rescue Exception => e
        error e.to_s
      else
        area.redraw
        vars.text = "Dpwm=#{@spwm.d_pwm} (#{@spwm.d_pwm_xs}), "
        vars.text += "Dinit=#{@spwm.d_init} (#{@spwm.d_init_xs}), "
        vars.text += "Ddelta=#{@spwm.d_inc} (#{@spwm.d_inc_xs}), "
        vars.text += "k=#{@spwm.k}"
      end
    end
    vbox.add button
  end
end

Window.new
