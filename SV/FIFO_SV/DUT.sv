module fifo #(
	parameter SIZE=32
) (
	input logic clock,
	input logic rst,
	input logic [7:0] data_in,
  	input logic wr,
  	input logic rd,
  
  	output logic empty,
  	output logic full,
    output logic [7:0] data_out
);
  
    logic [7:0] queue [SIZE];
    logic [$clog2(SIZE):0] head;
    logic [$clog2(SIZE):0] tail;

    assign empty = tail == head;
    assign full  = (tail[$clog2(SIZE)] != head[$clog2(SIZE)]) && (tail[$clog2(SIZE)-1:0] == head[$clog2(SIZE)-1:0]);

    always_ff @(posedge clock) begin
        if (rst == 1) begin
            head <= 0;
            tail <= 0;
            data_out <= 0;
            for (int i = 0; i < SIZE; i++) begin
                queue[i] <= 0;
            end
        end
        else begin
            if (wr == 1 && full != 1) begin
                queue[tail[$clog2(SIZE)-1:0]] <= data_in;
                tail <= tail + 1;
            end
            if (rd == 1 && empty != 1) begin
                data_out <= queue[head[$clog2(SIZE)-1:0]];
                head <= head + 1;
            end
        end
    end
endmodule
