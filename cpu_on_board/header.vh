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

`define Plic_base         32'h0C00_0000  # PRIORITY(id) = base + 4 * id
`define Plic_pending_word 32'h0C00_1000  # id 1-32
`define Plic_enable       32'h0C00_2000  # base + 0x2000 + (hart * 0x80) + (word_id*4) |2:hart1S-m
`define Plic_threshold    32'h0C20_0000  # base + 0x200000 + (hart * 0x1000)
`define Plic_claim        32'h0C20_0004  # base + 0x200004 + (hart * 0x1000)
`define HARTS 1
