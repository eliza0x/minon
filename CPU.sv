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
    bit  result_available[3];
    ReservationStation rstation[3];
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
            automatic inst instruction = instCache[pc];
            automatic logic [1:0] consumed_inst = 0;


            // Bload Cast: register file
            for (int l=1; l<$size(result); l++) begin
                if (result_available[l]) begin
                    $display("bload cast: %d, result: %d", l, result[l]);
                    for (int i=1; i<$size(regs); i++) begin
                        // $display("regs[%d].alu: %d", i, regs[i].alu);
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
                    for (int i=0; i<$size(rstation); i++) begin
                        if (rstation[i].alu1 == l) begin
                            rstation[i].value1 = result[l];
                            rstation[i].alu1   = 2'b00;
                        end

                        if (rstation[i].alu2 == l) begin
                            rstation[i].value2 = result[l];
                            rstation[i].alu2   = 2'b00;
                        end
                    end
                end
            end
            // Resister-Resister Operation
            if (instruction[op_begin:op_end] == 7'b1100110) begin
                // ADD, SLT, SLTU
                $display("!!!!!!!!!!!!!!!!!!!!: %b", instruction[funct3_begin:funct3_end]);
                if (instruction[funct3_begin:funct3_end] == 3'b000) begin
                    // ADD
                    if (instruction[funct7_begin:funct7_end] == 7'b0000000) begin
                        if (!rstation[1].busy) begin
                            // rs1 is available
                            if (regs[instruction[rs1_begin:rs1_end]].alu == 2'b00) begin
                                rstation[1].value1 = regs[instruction[rs1_begin:rs1_end]].data;
                                rstation[1].alu1   = 2'b00;
                            end else begin
                                rstation[1].value1 = 32'd0;
                                rstation[1].alu1   = regs[instruction[rs1_begin:rs1_end]].alu;
                            end

                            // rs2 is available
                            if (regs[instruction[rs2_begin:rs2_end]].alu == 2'b00) begin
                                rstation[1].value2 = regs[instruction[rs2_begin:rs2_end]].data;
                                rstation[1].alu2   = 2'b00;
                            end else begin
                                rstation[1].value2 = 32'd0;
                                rstation[1].alu2   = regs[instruction[rs2_begin:rs2_end]].alu;
                            end

                            rstation[1].busy = 1'b1;
                            $display("regs[%d].alu", instruction[rd_begin:rd_end]);
                            regs[instruction[rd_begin:rd_end]].alu = 1;
                            consumed_inst += 1;
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
        for (i=1; i<2; i++) begin
            Add add_module (
                .rstation(rstation[i]),
                .result(result[i]),
                .result_available(result_available[i]),
                .*
            );
        end
    endgenerate 
endmodule

module Add(
    input wire                CLOCK_50,
    input wire                RSTN_N,
    input ReservationStation  rstation,
    output logic [31:0]       result,
    output logic              result_available
);

    always @(CLOCK_50 or negedge RSTN_N) begin
        if (!RSTN_N) begin
            result_available <= 0;
            result           <= 0;
        end else if (!CLOCK_50 && rstation.alu1==2'b00 && rstation.alu2==2'b00 && rstation.busy) begin
            result_available <= 1;
            result <= rstation.value1 + rstation.value2;
            $display("add: %d", rstation.value1 + rstation.value2);
        end else begin
            result_available <= 0;
            result           <= 0;
        end
    end
endmodule

