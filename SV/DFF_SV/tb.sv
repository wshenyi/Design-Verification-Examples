class transaction;

    rand bit din;
    bit dout;

    function void display(input string tag);
        $display("[%0s] din=%0b\t dout=%0b\t @%0t", tag, din, dout, $time);
    endfunction

    function transaction copy();
        copy = new();
        copy.din = this.din;
        copy.dout = this.dout;
    endfunction

endclass

class generator;

    mailbox #(transaction) mbx_dut;
    mailbox #(transaction) mbx_ref;
    transaction tr;

    int count = 0;

    event next_sco;
    event done;

    function new(mailbox #(transaction) mbx_dut, mailbox #(transaction) mbx_ref);
        this.mbx_dut = mbx_dut;
        this.mbx_ref = mbx_ref;
        tr = new();
    endfunction

    task run();
        repeat(count) begin
            assert (tr.randomize) else $error("[GEN] Randomization Failed!");
            mbx_dut.put(tr.copy);
            mbx_ref.put(tr.copy);
            tr.display("GEN");
            @(next_sco);
        end
        ->done;
    endtask

endclass

class driver;

    transaction tr;
    mailbox #(transaction) mbx;
    virtual dff_if vif;

    function new(mailbox #(transaction) mbx);
        this.mbx = mbx;
    endfunction

    task reset();
        vif.rst <= 1;
        vif.din   <= 0;
        repeat(5) @(posedge vif.clk);
        vif.rst <= 0;
        @(posedge vif.clk);
        $display("[DRV] RESET Done");
    endtask

    task run();
        forever begin
            mbx.get(tr);
            tr.display("DRV");

            vif.din <= tr.din;
            @(posedge vif.clk);
        end
    endtask

endclass

class monitor;

    transaction tr;
    mailbox #(transaction) mbx;
    virtual dff_if vif;

    function new(mailbox #(transaction) mbx);
        this.mbx = mbx;
    endfunction

    task run();
        tr = new();
        forever begin
            repeat(2) @(posedge vif.clk);
            tr.dout = vif.dout;
            mbx.put(tr);
            tr.display("MON");
        end
    endtask

endclass

class scoreboard;

    mailbox #(transaction) mbx_gen; // input to dut
    mailbox #(transaction) mbx_mon; // output from dut

    event next_sco;

    transaction tr_in;
    transaction tr_out;
    
    function new(mailbox #(transaction) mbx_gen, mailbox #(transaction) mbx_mon);
        this.mbx_gen = mbx_gen;
        this.mbx_mon = mbx_mon;
    endfunction

    task run();
        forever begin
            mbx_gen.get(tr_in);
            mbx_mon.get(tr_out);
            $display("[REF] ref_din=%0d", tr_in.din);
            $display("[DUT] dut_dout=%0d", tr_out.dout);
            if (tr_in.din == tr_out.dout)
                $display("[SCO] Data Match");
            else
                $error("[SCO] Data Mismatch");

            ->next_sco;
        end
    endtask

endclass

class environment;

    generator gen;
    driver drv;
    monitor mon;
    scoreboard sco;

    event next; // gen <-> sco

    mailbox #(transaction) mbx1; // gen -> drv
    mailbox #(transaction) mbx2; // gen -> sco
    mailbox #(transaction) mbx3; // mon -> sco

    virtual dff_if vif;

    function new(virtual dff_if vif);
        mbx1 = new();
        mbx2 = new();
        mbx3 = new();

        gen = new(mbx1, mbx2);
        drv = new(mbx1);
        mon = new(mbx3);
        sco = new(mbx2, mbx3);

        this.vif = vif;
        drv.vif = this.vif;
        mon.vif = this.vif;

        gen.next_sco = next;
        sco.next_sco = next;
    endfunction

    task pre_test();
        drv.reset();
    endtask

    task run_test();
        fork
            gen.run();
            drv.run();
            mon.run();
            sco.run();
        join_any
    endtask

    task post_test();
        wait(gen.done.triggered);
        $finish();
    endtask

    task run();
        pre_test();
        run_test();
        post_test();
    endtask

endclass

module tb;

    dff_if rif();
    dff dut(rif);
    environment env;

    initial rif.clk <= 0;

    always #10 assign rif.clk = ~rif.clk;

    initial begin
        env = new(rif);
        env.gen.count = 30;
        env.run();
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end

endmodule
