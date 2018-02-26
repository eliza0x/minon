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
    inst          value1;
    inst          value2;
    inst          address;
    inst          address_offset;
    ALU           alu1;
    ALU           alu2;
} ReservationStation ;

typedef struct {
    logic         available;
    logic         is_failure;
    logic         is_store;
    logic         is_branch;
    logic         is_halt;
    logic         is_resister;
    logic [5:0]   reg_num;
    logic [31:0]  address;
    logic [31:0]  address_offset;
    logic [31:0]  value;
    ALU           alu;
} ReorderBuffer;

`endif
