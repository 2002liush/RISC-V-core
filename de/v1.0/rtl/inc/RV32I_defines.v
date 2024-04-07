  // The ITCM size is 2^addr_width bytes, and ITCM is 8bits wide (1 bytes)

`define RV32I_ITCM_RAM_DW      8 // data width: 8 bit = 1 Byte
`define RV32I_ITCM_RAM_WW      32 // word width: 32 bit
`define RV32I_ITCM_RAM_AW      16 // RAM Size: 2^16 = 64K
`define RV32I_ITCM_RAM_SZ      1024*64 // Size: 2^16 = 64K Byte
`define RV32I_ITCM_RAM_MW      4

`define RV32I_DTCM_RAM_DW      8
`define RV32I_DTCM_RAM_WW      32
`define RV32I_DTCM_RAM_AW      16
`define RV32I_DTCM_RAM_SZ      1024*64
`define RV32I_DTCM_RAM_MW      4

`define PROGADDR_RESET          32'h0000_0000
`define PROGADDR_IRQ            32'h0000_0100
`define ITCM_START              32'h0000_0000 // 64KB
`define DTCM_START              32'h0001_0000 // 64KB
`define BUS_START               32'h0002_0000 // 64KB