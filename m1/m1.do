# -*-ruby-*-

{
  name: :m1,
  target: {family: 'Cyclone IV E', device: 'EP4CE22F17C6', eprom: 'EPCS64'},
  top: 'm1_de0nano',
  sim: 'm1_sim',
  pins: {
    sys_clk: {pad: 'R8', voltage: "3.3-V LVTTL",},
    rstn: {pad: 'J15', voltage: "3.3-V LVTTL",},
    rstn_it: {pad: 'E1', voltage: "3.3-V LVTTL",},
    leds: [
           {pad: 'A15', voltage: "3.3-V LVTTL", current: '4mA'},
           {pad: 'A13', voltage: "3.3-V LVTTL", current: '4mA'},
           {pad: 'B13', voltage: "3.3-V LVTTL", current: '4mA'},
           {pad: 'A11', voltage: "3.3-V LVTTL", current: '4mA'},
           {pad: 'D1', voltage: "3.3-V LVTTL", current: '4mA'},
           {pad: 'F3', voltage: "3.3-V LVTTL", current: '4mA'},
           {pad: 'B1', voltage: "3.3-V LVTTL", current: '4mA'},
           {pad: 'L3', voltage: "3.3-V LVTTL", current: '4mA'},
          ]
  },
  sdc: '../boards/de0-nano.sdc',
  files: ['*.v'],
  include: [:cnt],
}
