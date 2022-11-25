// Top level testbench contains the interface, DUT and test handles which
// can be used to start test components once the DUT comes out of reset. Or
// the reset can also be a part of the test class in which case all you need
// to do is start the test's run method.

module tb;
    reg clk;
  
    always #10 clk = ~clk;
    reg_if _if (clk);
  
    reg_ctrl u0 ( .clk (clk),
                  .addr (_if.addr),
                  .rstn (_if.rstn),
                  .sel  (_if.sel),
                  .wr   (_if.wr),
                  .wdata (_if.wdata),
                  .rdata (_if.rdata),
                  .ready (_if.ready));
  
    initial begin
        clk <= 0;
        uvm_config_db#(virtual reg_if)::set(null, "uvm_test_top", "reg_vif", _if);
        run_test("test");
      #200 $finish;
    end
  
    // Simulator dependent system tasks that can be used to
    // dump simulation waves.
    initial begin
      $dumpvars;
      $dumpfile("dump.vcd");
    end
endmodule