`ifdef PARAMETER_IS_LOADED
`else
`define PARAMETER_IS_LOADED

`include "./Parameter/Opecode.sv"

parameter op_begin = 31;
parameter op_end   = 25;

parameter rd_begin = 24;
parameter rd_end   = 20;

parameter funct3_begin = 19;
parameter funct3_end   = 17;

parameter rs1_begin = 16;
parameter rs1_end   = 12;

parameter rs2_begin = 11;
parameter rs2_end   = 7;

parameter funct7_begin = 6;
parameter funct7_end   = 0;

`endif

