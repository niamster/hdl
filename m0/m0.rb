{
  target: {family: 'Cyclone IV E', device: 'EP4CE22F17C6'},
  top: 'm0_de0nano',
  pins: {
    sys_clk: 'R8',
    key: 'J15',
    rstn: 'E1',
    leds: ['A15', 'A13', 'B13', 'A11', 'D1', 'F3', 'B1', 'L3']
  },
  sdc: '../boards/de0-nano.sdc',
  # files: ['m0.v'],
  files: ['*.v'],
}
