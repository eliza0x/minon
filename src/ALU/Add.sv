`include "../Utility.sv"

// 実験の為に1クロック遅延を発生させている
module Add(
    input wire                clk,
    input wire                RSTN_N,
    input ReservationStation  rstation,
    output logic [31:0]       result,
    output logic              result_available
);

    bit b_result_available = 0;
    logic [31:0] b_result = 0;

    bit calculated = 0;

    always @(posedge clk or negedge RSTN_N) begin
        if (!RSTN_N) begin
            result_available <= 0;
            result           <= 0;
        end else begin
            if (!calculated && rstation.alu1==8'd0 && rstation.alu2==8'd0 && rstation.busy) begin
                b_result_available <= 1;
                b_result   <= rstation.value1 + rstation.value2;

                result_available <= b_result_available;
                result           <= b_result;
                calculated <= 1;
            end else if (calculated && rstation.alu1==8'd0 && rstation.alu2==8'd0 && rstation.busy) begin
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

