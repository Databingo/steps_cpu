_start:
    # Initialize base address register x5 to 0.
    # Assumes the data from 'data_test.txt' is loaded into memory starting at address 0.
    li x5, 0

    # Test sequence starts here.
    # Assumes an external harness monitors x11 and compares x31 vs x30 when x11 becomes 1.

##--------------------------------------------
## LB (Load Byte) Specific Tests - RV64
## Using x31 as result/test value
## Using x30 to load Golden value
## Using x11 for Compare Signaling
## Using x5 as base address register (rs1), assumes base address = 0
## REQUIRES data memory pre-loaded from 'data_test.txt' at address 0.
##--------------------------------------------

## TEST: LB_MAX_POS_BYTE
    # Purpose: Load max positive byte (0x7F at Addr 0), check sign extension.
    # Data @000: 7F ...
    lb  x31, 0(x5)            # Load byte: x31 = MEM[0 + 0] sign-extended
    li  x30, 0x000000000000007F # Golden value (0x7F sign-extended is still 0x7F)
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal
    # csrrw ...
    li  x6, 0x80000010 # keyboard_map_address
    lb  x31, 0(x6) # load addr_saved value into x31
    li  x7, 0x80000000 # aurt_map_address
    sb  x31, 0(x7) # save x31 to uart_map_address 
    #mret
      
   
