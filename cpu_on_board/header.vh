`define Rom_base   64'h0000_0000
`define Rom_size   64'h0000_1000
`define Ram_base   64'h0000_1000
`define Ram_size   64'h0000_1000
`define Key_base   64'h0000_2000
`define Art_base   64'h0000_2004
`define ArtC_base  64'h0000_2008

`define Sdc_base   64'h0000_3000
`define Sdc_addr   64'h0000_3200
`define Sdc_read   64'h0000_3204
`define Sdc_write  64'h0000_3208
`define Sdc_ncd    64'h0000_3212
`define Sdc_wp     64'h0000_3216
`define Sdc_ready  64'h0000_3220
`define Sdc_dirty  64'h0000_3224
`define Sdc_avail  64'h0000_3228

`define Sdram_min  64'h1000_0000
`define Sdram_max  64'h1080_0000

`define Mtime      64'h0200_bff8
`define Mtimecmp   64'h0200_4000

`define Plic_base         64'h0C00_0000  
`define Plic_pending      64'h0C00_1000  
`define Plic_enable       64'h0C00_2000  
`define Plic_threshold    64'h0C20_0000  
`define Plic_claim        64'h0C20_0004  
`define HARTS 1

`define Tlb    64'h2000_0000
`define CacheI 64'h2000_1000
