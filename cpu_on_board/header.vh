`define Rom_base   32'h0000_0000
`define Rom_size   32'h0000_1000
`define Ram_base   32'h0000_1000
`define Ram_size   32'h0000_1000
`define Key_base   32'h0000_2000
`define Art_base   32'h0000_2004

`define Sdc_base   32'h0000_3000
`define Sdc_addr   32'h0000_3200
`define Sdc_read   32'h0000_3204
`define Sdc_write  32'h0000_3208
`define Sdc_ncd    32'h0000_3212
`define Sdc_wp     32'h0000_3216
`define Sdc_ready  32'h0000_3220
`define Sdc_dirty  32'h0000_3224
`define Sdc_avail  32'h0000_3228

`define Sdram_min  32'h1000_0000
`define Sdram_max  32'h1080_0000

`define Mtime      32'h0200_bff8
`define Mtimecmp   32'h0200_4000

`define Plic_base 32'h0C00_0000
`define Plic_msip 32'h0200_0000

