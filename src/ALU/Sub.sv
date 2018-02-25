`include "../Utility.sv"

module Sub(
    input wire                clk,
    input wire                RSTN_N,
    input ReservationStation  rstation,
    output logic [31:0]       result,
    output logic              result_available
);

    always @(posedge clk or negedge RSTN_N) begin
        if (!RSTN_N) begin
            result_available <= 0;
            result           <= 0;
        end else begin
            if (rstation.alu1==8'd0 && rstation.alu2==8'd0 && rstation.busy) begin
                result_available <= 1;
                result <= rstation.value1 - rstation.value2;
            end else begin
                result_available <= 0;
                result           <= 0;
            end
        end
    end
endmodule
