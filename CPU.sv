typedef logic [31:0] inst;
typedef logic [1:0] ALU;

typedef struct {
    ALU  alu;
    inst data;
} RegF;

typedef struct {
    logic         busy;
    logic [31:0]  value1;
    logic [31:0]  value2;
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
    inst result[3];
    bit  result_available[4];
    ReservationStation rstation[4];
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
            automatic logic [1:0] consumed_inst = 0;

            $display("------------------------------");

            // Bload Cast: register file
            for (int l=1; l<$size(result); l++) begin
                if (result_available[l]) begin
                    $display("bload cast - regs: %2d, result: %d", l, result[l]);
                    for (int i=1; i<$size(regs); i++) begin
                        $display("regs[%2d].alu: %d", i, regs[i].alu);
                        if (regs[i].alu == l) begin
                            $display("written: %d", result[l]);
                            regs[i].data     = result[l];
                            regs[i].alu      = 2'b00;
                            rstation[l].busy = 0;
                        end
                    end
                end
            end

            // Bload Cast: reservation station
            for (int l=0; l<$size(result); l++) begin
                if (result_available[l]) begin
                    $display("bload cast - rstation: %2d, result: %d", l, result[l]);
                    for (int i=0; i<$size(rstation); i++) begin
                        $display("rstation[%2d].alu1: %d", i, rstation[i].alu1);
                        $display("rstation[%2d].alu2: %d", i, rstation[i].alu2);
                        if (rstation[i].alu1 == l) begin
                            $display("written - rst1: %d", result[l]);
                            rstation[i].value1 = result[l];
                            rstation[i].alu1   = 2'b00;
                            rstation[l].busy = 0;
                        end

                        if (rstation[i].alu2 == l) begin
                            $display("written - rst2: %d", result[l]);
                            rstation[i].value2 = result[l];
                            rstation[i].alu2   = 2'b00;
                            rstation[l].busy = 0;
                        end
                    end
                end
            end

            instruction = instCache[pc+consumed_inst];
            // Resister-Resister Operation
            if (instruction[op_begin:op_end] == 7'b1100110) begin
                // ADD, SLT, SLTU
                $display("!!!!!!!!!!!!!!!!!!!!: %b", instruction[funct3_begin:funct3_end]);
                if (instruction[funct3_begin:funct3_end] == 3'b000) begin
                    // ADD
                    if (instruction[funct7_begin:funct7_end] == 7'b0000000) begin
                        for (int i=1; i<4; i++) begin
                            if (!rstation[i].busy) begin
                                $display("using: %d", i);
                                // rs1 is available
                                if (regs[instruction[rs1_begin:rs1_end]].alu == 2'b00) begin
                                    $display("rs1 is available");
                                    rstation[i].value1 = regs[instruction[rs1_begin:rs1_end]].data;
                                    rstation[i].alu1   = 2'b00;
                                end else begin
                                    $display("rs1 is not available: %d", regs[instruction[rs1_begin:rs1_end]].alu);
                                    rstation[i].value1 = 32'd0;
                                    rstation[i].alu1   = regs[instruction[rs1_begin:rs1_end]].alu;
                                end

                                // rs2 is available
                                if (regs[instruction[rs2_begin:rs2_end]].alu == 2'b00) begin
                                    $display("rs2 is available");
                                    rstation[i].value2 = regs[instruction[rs2_begin:rs2_end]].data;
                                    rstation[i].alu2   = 2'b00;
                                end else begin
                                    $display("rs2 is not available: %d", regs[instruction[rs2_begin:rs2_end]].alu);
                                    rstation[i].value2 = 32'd0;
                                    rstation[i].alu2   = regs[instruction[rs2_begin:rs2_end]].alu;
                                end

                                rstation[i].busy = 1'b1;
                                $display("regs[%d].alu", instruction[rd_begin:rd_end]);
                                regs[instruction[rd_begin:rd_end]].alu = i;
                                consumed_inst += 1;

                                break;
                            end
                        end
                    end
                end
            end else if (instruction[op_begin:op_end] == 7'b0000000) begin
                consumed_inst += 1;
            end

            pc = pc + consumed_inst;
        end
    end

    genvar i;
    generate 
        for (i=1; i<$size(rstation); i++) begin
            Add add_module (
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

    always @(CLOCK_50 or negedge RSTN_N) begin
        if (!RSTN_N) begin
            result_available <= 0;
            result           <= 0;
        end else if (CLOCK_50) begin
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

