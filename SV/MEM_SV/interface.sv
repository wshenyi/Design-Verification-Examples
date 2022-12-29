`ifndef MEM_IF_SV
`define MEM_IF_SV

interface mem_if;
    logic clock;
    logic rst;
    logic en;
    logic read_write; // read = 0, write = 1
    logic [7:0] address;
    logic [7:0] data_in;
    logic [7:0] data_out;
endinterface

`endif