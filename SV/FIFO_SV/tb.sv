class transaction;

    rand bit rd,wr;
    rand bit [7:0] data_in;
         bit full, empty;
         bit [7:0] data_out;
    
    constraint wr_rd {
        rd != wr;
        rd dist {0 :/ 50, 1 :/ 50};
        wr dist {0 :/ 50, 1 :/ 50};
    }

    constraint data_con {
        data_in > 1;
        data_in < 8;
    }

    function void display(input string tag);
      $display("[%0s] : WR=%0b\t RD=%0b\t DATA_IN=%0b\t DATA_OUT=%0b\t FULL=%0b\t EMPTY=%0b\t @%0t", tag, wr, rd, data_in, data_out, full, empty, $time);
    endfunction

    function transaction copy();
        copy = new();
        copy.rd = this.rd;
        copy.wr = this.wr;
        copy.data_in = this.data_in;
        copy.data_out= this.data_out;
        copy.full = this.full;
        copy.empty = this.empty;
    endfunction

endclass

class sequencer;

    transaction tr;
    mailbox #(transaction) mbx;

    int count = 0;

    event next; // know when to send next transaction
    event done; // conveys completion of requested number of transaction

    function new(mailbox #(transaction) mbx);
        this.mbx = mbx;
        tr = new();
    endfunction

    task run();
        repeat(count) begin
            assert(tr.randomize) else $error("Randomization Failed");
            mbx.put(tr.copy);
            tr.display("GEN");
            @(next);
        end
        -> done;
    endtask
endclass

class driver;

    mailbox #(transaction) mbx;
    virtual fifo_if _if;
    transaction tr_rec;

    event next;

    function new(mailbox #(transaction) mbx);
        this.mbx = mbx;
    endfunction

    // Reset DUT
    task reset();
        _if.rst <= 1;
        _if.rd  <= 0;
        _if.wr  <= 0;
        _if.data_in <= 0;
        repeat(5) @(posedge _if.clock);
        _if.rst <= 0;
    endtask

    // Apply random stimulus to DUT
    //    1. Receive transactions
    //    2. Apply transactions to DUT
    task run();
        forever begin
            mbx.get(tr_rec);
            tr_rec.display("DRV");

            _if.data_in <= tr_rec.data_in;
            _if.rd      <= tr_rec.rd;
            _if.wr      <= tr_rec.wr;
            repeat(2) @(posedge _if.clock);
            ->next;
        end
    endtask

endclass

class monitor;

    mailbox #(transaction) mbx;
    virtual fifo_if _if;
    transaction tr_sent;

    function new(mailbox #(transaction) mbx);
        this.mbx = mbx;
    endfunction

    task run();
        tr_sent = new();
        forever begin
            repeat(2) @(posedge _if.clock);
            // Get from Driver
            tr_sent.data_in <= _if.data_in;
            tr_sent.rd      <= _if.rd;
            tr_sent.wr      <= _if.wr;
            // Get from DUT
            tr_sent.data_out <= _if.data_out;
            tr_sent.empty    <= _if.empty;
            tr_sent.full     <= _if.full;

            mbx.put(tr_sent);
            tr_sent.display("MON");
        end
    endtask

endclass

class scoreboard;

    mailbox #(transaction) mbx;
    transaction tr_rec;
    event next;

    bit [7:0] queue[$];
    bit [7:0] data;

    function new(mailbox #(transaction) mbx);
        this.mbx = mbx;
    endfunction

    task run();
        forever begin
            mbx.get(tr_rec);
            tr_rec.display("SCO");

            if (tr_rec.wr == 1) begin
                if (tr_rec.full == 0) begin
                    queue.push_back(tr_rec.data_in);
                    $display("[SCO] : Data stored in queue :%0d", tr_rec.data_in);
                end
                else begin
                    assert(queue.size() == 32) else begin
                        $error("[SCO] : FIFO overflow!");
                    end
                end
            end

            if (tr_rec.rd == 1) begin
                if (tr_rec.empty == 0) begin
                    data = queue.pop_front();
                    assert(data == tr_rec.data_out) begin
                        $display("[SCO] : Data match. ref_out: %0d dut_out: %0d", data, tr_rec.data_out);
                    end else begin
                        $error("[SCO] : Data mismatch. ref_out: %0d dut_out: %0d", data, tr_rec.data_out);
                    end
                end
                else begin
                    assert(queue.size == 0) else begin
                        $error("[SCO] : Access null FIFO!");
                    end
                end
            end

            ->next;
        end
    endtask

endclass

class environment;

    sequencer seqr;
    driver drv;
    monitor mon;
    scoreboard sco;

    mailbox #(transaction) sdmbx;
    mailbox #(transaction) msmbx;

    event next_tag;
    virtual fifo_if fif;

    function new(virtual fifo_if fif);
        sdmbx = new();
        msmbx = new();
        seqr = new(sdmbx);
        drv  = new(sdmbx);
        sco = new(msmbx);
        mon = new(msmbx);

        this.fif = fif;
        drv._if = this.fif;
        mon._if = this.fif;

        seqr.next = next_tag;
        sco.next = next_tag;

    endfunction

    task pre_test();
        drv.reset();
    endtask

    task run_test();
        fork
            seqr.run();
            drv.run();
            mon.run();
            sco.run();
        join_any
    endtask

    task post_test();
        wait(seqr.done.triggered);
        $finish();
    endtask

    task run();
        pre_test();
        run_test();
        post_test();
    endtask

endclass

module mod;
    environment env;

    fifo_if fif();
    fifo #(.SIZE(32)) DUT(
        .clock(fif.clock),
        .rd(fif.rd),
        .wr(fif.wr),
        .rst(fif.rst),
        .data_in(fif.data_in),
        .empty(fif.empty),
        .full(fif.full),
        .data_out(fif.data_out)
    );
    
    always #10 fif.clock <= ~fif.clock;
    
    initial fif.clock = 0;

    initial begin
        env = new(fif);
        env.seqr.count = 20;
        env.run();
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end

endmodule