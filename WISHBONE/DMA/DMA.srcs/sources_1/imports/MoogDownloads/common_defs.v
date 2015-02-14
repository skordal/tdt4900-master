// Common Verilog SHMAC defines
`ifndef _COMMON_DEFS
`define _COMMON_DEFS

// ============  interconnect data interface ===============

`define ADDR_BEGIN     0    // address               - 32 bits
`define ADDR_END       31   
`define REPLY_IDX      32   // reply/request?        - 1 bit
`define WR_REQ_IDX     33   // write request         - 1 bit
`define WR_MASK_BEGIN  34   // write mask            - 16 bits
`define WR_MASK_END    49
`define EXCL_IDX       50   // exclusive operation   - 1 bit
`define ERROR_IDX      51   // error                 - 1 bit
`define DATA_BEGIN     52   // data                  - 128 bits
`define DATA_END       179
`define SEND_X_BEGIN   180  // sender coordinates    - 8 bits
`define SEND_X_END     183
`define SEND_Y_BEGIN   184
`define SEND_Y_END     187
`define DEST_X_BEGIN   188  // destination coordinates - 8 bits
`define DEST_X_END     191  //       (IC only)
`define DEST_Y_BEGIN   192
`define DEST_Y_END     195

`define PACKET_WIDTH   188  // packet width, local port
`define IC_WIDTH       196  // interconnect width (between routers)


// ============  status values =============================

`define STAT_SUCCESS   1'b0
`define STAT_ERROR     1'b1
 
// ============  address regions ===========================

`define RAM_BASE   32'h00000000
`define BRAM_BASE  32'hF8000000
`define TILE_BASE  32'hFFFE0000
`define SYS_BASE   32'hFFFF0000

// ============  tile unit offsets =========================

`define TILE_REGS  16'h0000
`define TIMER      16'h1000
`define INT_CTRL   16'h2000
`define ACC        16'h3000

// ============  register offsets ==========================

`define TILEREG_CPUID     12'h000
`define TILEREG_TILE_X    12'h004
`define TILEREG_TILE_Y    12'h008
`define TILEREG_DUMMY     12'h00c
`define TILEREG_DMA_LREG0 12'h010
`define TILEREG_DMA_SREG0 12'h014
`define TILEREG_DMA_RREG0 12'h018

`define AMBER_TM_TIMER0_LOAD      12'h000
`define AMBER_TM_TIMER0_VALUE     12'h004
`define AMBER_TM_TIMER0_CTRL      12'h008
`define AMBER_TM_TIMER0_CLR       12'h00c
`define AMBER_TM_TIMER1_LOAD      12'h100
`define AMBER_TM_TIMER1_VALUE     12'h104
`define AMBER_TM_TIMER1_CTRL      12'h108
`define AMBER_TM_TIMER1_CLR       12'h10c
`define AMBER_TM_TIMER2_LOAD      12'h200
`define AMBER_TM_TIMER2_VALUE     12'h204
`define AMBER_TM_TIMER2_CTRL      12'h208
`define AMBER_TM_TIMER2_CLR       12'h20c

`define AMBER_IC_IRQ0_STATUS      12'h000  
`define AMBER_IC_IRQ0_RAWSTAT     12'h004  
`define AMBER_IC_IRQ0_ENABLESET   12'h008 
`define AMBER_IC_IRQ0_ENABLECLR   12'h00c 
`define AMBER_IC_INT_SOFTSET_0    12'h010
`define AMBER_IC_INT_SOFTCLEAR_0  12'h014
`define AMBER_IC_FIRQ0_STATUS     12'h020  
`define AMBER_IC_FIRQ0_RAWSTAT    12'h024  
`define AMBER_IC_FIRQ0_ENABLESET  12'h028  
`define AMBER_IC_FIRQ0_ENABLECLR  12'h02c 
`define AMBER_IC_IRQ1_STATUS      12'h040  
`define AMBER_IC_IRQ1_RAWSTAT     12'h044  
`define AMBER_IC_IRQ1_ENABLESET   12'h048 
`define AMBER_IC_IRQ1_ENABLECLR   12'h04c 
`define AMBER_IC_INT_SOFTSET_1    12'h050
`define AMBER_IC_INT_SOFTCLEAR_1  12'h054
`define AMBER_IC_FIRQ1_STATUS     12'h060  
`define AMBER_IC_FIRQ1_RAWSTAT    12'h064  
`define AMBER_IC_FIRQ1_ENABLESET  12'h068  
`define AMBER_IC_FIRQ1_ENABLECLR  12'h06c 
`define AMBER_IC_INT_SOFTSET_2    12'h090
`define AMBER_IC_INT_SOFTCLEAR_2  12'h094
`define AMBER_IC_INT_SOFTSET_3    12'h0d0
`define AMBER_IC_INT_SOFTCLEAR_3  12'h0d4


// ============  router port directions ====================

`define EAST_DIR     0
`define NORTH_DIR    1
`define WEST_DIR     2
`define SOUTH_DIR    3
`define LOCAL_DIR    4    // processor

`define DIR_CNT      5    // total number of ports


// ============  APB =======================================
`define SINGLE_TTY
`ifdef SINGLE_TTY
 `define CHANNELS     1
`else
 `define CHANNELS    16
`endif

`ifdef GLOBAL_IRQ
 `define IRQS         `CHANNELS + 1
`else
 `define IRQS         `CHANNELS
`endif

`endif	// _COMMON_DEFS
