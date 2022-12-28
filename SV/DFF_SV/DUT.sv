module dff(dff_if vif);
    always @(posedge vif.clk) begin
        if (vif.rst == 1) begin
            vif.dout <= 0;
        end
        else begin
            vif.dout <= vif.din;
        end
    end
endmodule

interface dff_if;
    logic clk;
    logic rst;
    logic din;
    logic dout;
endinterface