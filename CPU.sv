typedef logic [31:0] inst;
typedef byte ALU;

typedef struct {
    ALU  alu;
    inst data;
} RegF;

typedef struct {
    logic         busy;
    logic [31:0]  value1;
    logic [31:0]  value2;
    logic [2:0]   funct3;
    ALU           alu1;
    ALU           alu2;
} ReservationStation ;

module CPU(
    input wire CLOCK_50,
    input wire RSTN_N
);
    `include "src/Parameter.sv"
    
    inst instCache[256];
    RegF regs[32];
    inst result[8];
    bit  result_available[$size(result)];
    ReservationStation rstation[$size(result)];
    inst pc;

    // 初期化
    initial begin
        for (int i=0; i<32; i++) begin
            regs[i].alu  <= 2'b00;
            regs[i].data <= 32'b0;
        end
        for (int i=0; i<$size(rstation); i++) begin
            rstation[i].busy   <= 1'b0;
            rstation[i].alu1   <= 2'b00;
            rstation[i].alu2   <= 2'b00;
            rstation[i].value1 <= 32'd0;
            rstation[i].value2 <= 32'd0;
        end
        pc <= 0;
    end

    always @(posedge CLOCK_50 or negedge RSTN_N) begin
        if (!RSTN_N) begin
            for (int i=0; i<32; i++) begin
                regs[i].alu  <= 2'b00;
                regs[i].data <= 32'b0;
            end
            for (int i=0; i<$size(rstation); i++) begin
                rstation[i].busy   <= 1'b0;
                rstation[i].alu1   <= 2'b00;
                rstation[i].alu2   <= 2'b00;
                rstation[i].value1 <= 32'd0;
                rstation[i].value2 <= 32'd0;
            end
            pc <= 0;
        end else begin
            automatic inst instruction;
            automatic byte consumed_inst = 0;

            for (int l=1; l<$size(result); l++) begin
                if (result_available[l]) begin
                    // Bload Cast: register file
                    for (int i=1; i<$size(regs); i++) begin
                        if (regs[i].alu == l) begin
                            regs[i].data     = result[l];
                            regs[i].alu      = 2'b00;
                            rstation[l].busy = 0;
                        end
                    end
                    // Bload Cast: reservation station
                    for (int i=0; i<$size(rstation); i++) begin
                        if (rstation[i].alu1 == l) begin
                            rstation[i].value1 = result[l];
                            rstation[i].alu1   = 2'b00;
                            rstation[l].busy = 0;
                        end

                        if (rstation[i].alu2 == l) begin
                            rstation[i].value2 = result[l];
                            rstation[i].alu2   = 2'b00;
                            rstation[l].busy = 0;
                        end
                    end
                end
            end

            for (int l=1; l<$size(rstation); l++) begin
                instruction = instCache[pc+consumed_inst];

                // Resister-Resister Operation
                if (instruction[op_begin:op_end] == 7'b1100110) begin
                    // ADD, SUB
                    if (instruction[funct3_begin:funct3_end] == 3'b000) begin
                        // ADD
                        if (instruction[funct7_begin:funct7_end] == 7'b0000000) begin
                            for (int i=1; i<=4; i++) begin
                                if (!rstation[i].busy) begin
                                    send_reservation_station(instruction, i);
                                    consumed_inst = consumed_inst + 1;
                                    break;
                                end
                            end
                        end else if (instruction[funct7_begin:funct7_end] == 7'b0000010) begin
                            for (int i=5; i<=7; i++) begin
                                if (!rstation[i].busy) begin
                                    send_reservation_station(instruction, i);
                                    consumed_inst = consumed_inst + 1;
                                    break;
                                end
                            end
                        end
                    end
                end else if (instruction[op_begin:op_end] == 7'b0000000) begin
                    consumed_inst = consumed_inst + 1;
                end
            end

            pc = pc + consumed_inst;
        end
    end

    function void send_reservation_station(inst instruction, byte i);
        // rs1 is available
        if (regs[instruction[rs1_begin:rs1_end]].alu == 2'b00) begin
            rstation[i].value1 = regs[instruction[rs1_begin:rs1_end]].data;
            rstation[i].alu1   = 2'b00;
        end else begin
            rstation[i].value1 = 32'd0;
            rstation[i].alu1   = regs[instruction[rs1_begin:rs1_end]].alu;
        end
                                                                            
        // rs2 is available
        if (regs[instruction[rs2_begin:rs2_end]].alu == 2'b00) begin
            rstation[i].value2 = regs[instruction[rs2_begin:rs2_end]].data;
            rstation[i].alu2   = 2'b00;
        end else begin
            rstation[i].value2 = 32'd0;
            rstation[i].alu2   = regs[instruction[rs2_begin:rs2_end]].alu;
        end
                                                                            
        rstation[i].busy = 1'b1;
        regs[instruction[rd_begin:rd_end]].alu = i;
    endfunction

    genvar i;
    generate 
        for (i=1; i<=4; i++) begin
            Add add_module (
                .rstation(rstation[i]),
                .result(result[i]),
                .result_available(result_available[i]),
                .*
            );
        end
        for (i=5; i<=7; i++) begin
            Sub sub_module (
                .rstation(rstation[i]),
                .result(result[i]),
                .result_available(result_available[i]),
                .*
            );
        end
    endgenerate 
endmodule

// 実験の為に1クロック遅延を発生させている
module Add(
    input wire                CLOCK_50,
    input wire                RSTN_N,
    input ReservationStation  rstation,
    output logic [31:0]       result,
    output logic              result_available
);

    bit b_result_available = 0;
    logic [31:0] b_result = 0;

    bit calculated = 0;

    always @(posedge CLOCK_50 or negedge RSTN_N) begin
        if (!RSTN_N) begin
            result_available <= 0;
            result           <= 0;
        end else begin
            if (!calculated && rstation.alu1==2'b00 && rstation.alu2==2'b00 && rstation.busy) begin
                b_result_available <= 1;
                b_result   <= rstation.value1 + rstation.value2;

                result_available <= b_result_available;
                result           <= b_result;
                calculated <= 1;
            end else if (calculated && rstation.alu1==2'b00 && rstation.alu2==2'b00 && rstation.busy) begin
                b_result_available <= 0;
                b_result           <= 0;

                result_available <= b_result_available;
                result           <= b_result;
                calculated       <= 0;
            end else begin
                b_result_available <= 0;
                b_result           <= 0;
            end
        end
    end
endmodule

module Sub(
    input wire                CLOCK_50,
    input wire                RSTN_N,
    input ReservationStation  rstation,
    output logic [31:0]       result,
    output logic              result_available
);

    always @(posedge CLOCK_50 or negedge RSTN_N) begin
        if (!RSTN_N) begin
            result_available <= 0;
            result           <= 0;
        end else begin
            if (rstation.alu1==2'b00 && rstation.alu2==2'b00 && rstation.busy) begin
                result_available <= 1;
                result <= rstation.value1 - rstation.value2;
            end else begin
                result_available <= 0;
                result           <= 0;
            end
        end
    end
endmodule

