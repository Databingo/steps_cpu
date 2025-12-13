`define Rom_base   32'h0000_0000
`define Rom_size   32'h0000_1000
`define Ram_base   32'h0000_1000
`define Ram_size   32'h0000_1000
`define Key_base   32'h0000_2000
`define Art_base   32'h0000_2004
`define ArtC_base  32'h0000_2008

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

`define Plic_base         32'h0C00_0000  //# PER PRIORITY(id) = base + 4 * id (000-fff) array
`define Plic_pending      32'h0C00_1000  //# base + 0x1000 id 1-32 ... bitmap
`define Plic_enable       32'h0C00_2000  //# base + 0x2000 + ContextID*0x80 0hart0M 1hart0S... bitmap
`define Plic_threshold    32'h0C20_0000  //# base + 0x200000 + ContextID*0x1000 0hart0M 1hart0S...4B 
`define Plic_claim        32'h0C20_0004  //# base + 0x200004 + ContextID*0x1000 0hart0M 1hart0S...4B
`define HARTS 1

`define Tlb    32'h2000_0000
`define CacheI 32'h2000_1000
