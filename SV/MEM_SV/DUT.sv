`include "interface.sv"

module memory (
    mem_if vif
);

    logic [7:0] mem [256];

    always_ff @(vif.clock) begin
        if (vif.rst == 1) begin
            for (int i=0; i < 256; i++) begin
                mem[i] <= 0;
            end
            vif.data_out <= 0;
        end 
        else if (vif.en == 1) begin
            if (vif.read_write == 0) begin
                vif.data_out <= mem[vif.address]; // read
            end
            else begin
                mem[vif.address] <= vif.data_in;  // write
            end
        end
        else begin
            vif.data_out <= 0;
        end
    end

endmodule