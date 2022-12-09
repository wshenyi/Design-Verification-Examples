module fifo(
    input clock, rd, wr,
    input [7:0] data_in,
    input rst,

    output full, empty,
    output reg [7:0] data_out
);

    reg [7:0] mem [32];
    reg [5:0] head;
    reg [5:0] tail;

    assign full = (head ^ tail) == 6'b100000 ? 1 : 0;
    assign empty = (head ^ tail) == 0 ? 1 : 0;

    always_ff @(posedge clock) begin
        if (rst == 1'b1) begin 
            data_out <= 0;
            head <= 0;
            tail <= 0;
            for (int i = 0; i < 32; i++)
            begin
                mem[i] <= 0;
            end
        end
        else begin
            if (wr == 1'b1 && full != 1'b1) begin
                mem[tail[4:0]] <= data_in;
                tail <= tail + 1;
            end
            if (rd == 1'b1 && empty != 1'b1) begin
                data_out <= mem[head[4:0]];
                head <= head + 1;
            end
        end
    end

endmodule
