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
        for (int i=0; i<32; i++) begin
            cpu.instCache[i] = 32'h0000_0000;     
        end
        cpu.instCache[3] = 32'b1100110_00001_000_00001_00001_0000000;     
        cpu.instCache[4] = 32'b1100110_00001_000_00001_00001_0000000;     
        cpu.instCache[5] = 32'b1100110_00001_000_00001_00001_0000000;     
        cpu.instCache[6] = 32'b1100110_00010_000_00001_00001_0000000;     
        cpu.instCache[7] = 32'b1100110_00001_000_00001_00001_0000010;     

        #(100*2*50);

        $display("====================");
        for (int i=0; i<10; i++) begin
            $display("regs[%2d]: %d", i, cpu.regs[i].data);
        end
        $display("====================");
        $finish(1);
    end
endmodule
