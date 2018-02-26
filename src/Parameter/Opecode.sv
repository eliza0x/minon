`ifdef OPECODE_LOADED
`else 
`define OPECODE_LOADED

parameter op_resister_resister  = 7'b1100110;

parameter funct3_add_sub = 3'b000;

parameter funct7_add = 7'b0000000;
parameter funct7_sub = 7'b0000010;

parameter op_conditional_branch = 7'b1100011; 

parameter funct3_beq     = 3'b000;

parameter op_nop               = 7'b0000000;
parameter op_halt              = 7'b1111111;

`endif
