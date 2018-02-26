`include "../CPU.sv"

module TbCPU();
    bit CLOCK_50 = 1;
    bit RSTN_N = 1;

    always #100 CLOCK_50 = ~CLOCK_50;

    CPU cpu(.*);

initial begin
        #5;
        // OK

        cpu.regs[1].data = 32'h0000_0001;
        for (int i=0; i<$size(cpu.instCache); i++) begin
            cpu.instCache[i] = 32'h0000_0000;     
        end
        cpu.instCache[3+ 1] = 32'b1100110_00001_000_00001_00001_0000000;     
        cpu.instCache[3+ 2] = 32'b1100110_00001_000_00001_00001_0000000;     
        cpu.instCache[3+ 3] = 32'b1100110_00001_000_00001_00001_0000000;     
        cpu.instCache[3+ 4] = 32'b1100110_00001_000_00001_00001_0000000;     
        cpu.instCache[3+ 5] = 32'b1100110_00001_000_00001_00001_0000000;     
        cpu.instCache[3+ 6] = 32'b1100110_00001_000_00001_00001_0000000;     
        cpu.instCache[3+ 7] = 32'b1100110_00001_000_00001_00001_0000000;     
        cpu.instCache[3+ 8] = 32'b1100110_00001_000_00001_00001_0000000;     
        cpu.instCache[3+ 9] = 32'b1100110_00001_000_00001_00001_0000000;     
        cpu.instCache[3+10] = 32'b1100110_00001_000_00001_00001_0000000;     
        cpu.instCache[3+11] = 32'b1100110_00001_000_00001_00001_0000000;     
        cpu.instCache[3+12] = 32'b1100110_00001_000_00001_00001_0000000;     
        cpu.instCache[3+13] = 32'b1100110_00001_000_00001_00001_0000000;     
        cpu.instCache[3+14] = 32'b1100110_00001_000_00001_00001_0000000;     
        cpu.instCache[3+15] = 32'b1100110_00001_000_00001_00001_0000000;     
        // cpu.instCache[3+16] = 32'b1100110_00001_000_00001_00001_0000000;     
        cpu.instCache[3+16] = 32'b1100011_10110_000_00001_00001_1111111; // beq 1 1 -10
        cpu.instCache[3+17] = 32'hffff_ffff;
        // cpu.instCache[11] = 32'b1100110_00001_000_00001_00001_0000000;     
        // cpu.instCache[7] = 32'b1100110_00010_000_00001_00001_0000000;     
        // cpu.instCache[8] = 32'b1100110_00001_000_00001_00001_0000010;     
    end

    // always @(negedge cpu.is_halt_N) begin
    always #100000 begin
        $display("====================");
        $display("clk_cnt: %0d", cpu.clk_cnt);
        for (int i=0; i<10; i++) begin
            $display("regs[%2d]: %d", i, cpu.regs[i].data);
        end
        $display("====================");
        $finish(1);
    end
endmodule
