`ifdef UTILITY_LOADED
`else
`define UTILITY_LOADED

typedef logic [31:0] inst;
typedef byte ALU;
typedef byte RB;

typedef struct {
    RB    rbuffer;
    logic in_rbuffer;
    inst  data;
} RegF;

typedef struct {
    logic         busy;
    logic [31:0]  value1;
    logic [31:0]  value2;
    logic [2:0]   funct3;
    ALU           alu1;
    ALU           alu2;
} ReservationStation ;

typedef struct {
    logic         available;
    logic         is_failure;
    logic         is_store;
    logic         is_branch;
    logic         is_halt;
    logic [5:0]   reg_num;
    logic [31:0]  address;
    logic [31:0]  value;
    ALU           alu;
} ReorderBuffer;

`endif
