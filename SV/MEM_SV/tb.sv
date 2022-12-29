
class mem_base_object;
    bit [7:0] addr;
    bit [7:0] data;
    // Read = 0, Write = 1
    bit rd_wr;
endclass

class mem_driver;
    virtual mem_if ports;
  
    function new(virtual mem_if ports);
        this.ports = ports;
        ports.address    = 0;
        ports.en         = 0;
        ports.read_write = 0;
        ports.data_in    = 0;
    endfunction
    
    task drive_mem (mem_base_object object);
        @ (posedge ports.clock);
        ports.address    = object.addr;
        ports.en         = 1;
        ports.read_write = object.rd_wr;
        ports.data_in    = (object.rd_wr) ? object.data : 0;
        if (object.rd_wr) begin
            $display("Driver : Memory write access-> Address : %x Data : %x\n", 
            object.addr,object.data);
        end 
        else begin
            $display("Driver : Memory read  access-> Address : %x\n", 
            object.addr);
        end
        @ (posedge ports.clock);
        ports.address    = 0;
        ports.en         = 0;
        ports.read_write = 0;
        ports.data_in    = 0;
    endtask
  
endclass

class mem_txgen;
    mem_base_object  mem_object;
    mem_driver  mem_driver;
    
    integer num_cmds;
  
    function new(virtual mem_if ports);
        num_cmds = 3;
        mem_driver = new(ports);
    endfunction
    
    
    task gen_cmds();
        integer i = 0;
        for (i=0; i < num_cmds; i ++ ) begin
            mem_object = new();
            mem_object.addr = $random();
            mem_object.data = $random();
            mem_object.rd_wr = 1;
            mem_driver.drive_mem(mem_object);
            mem_object.rd_wr = 0;
            mem_driver.drive_mem(mem_object);
        end
    endtask
  
endclass

class mem_scoreboard;
    // Create a keyed list to store the written data
    // Key to the list is address of write access
    mem_base_object mem_object [*];
  
    // post_input method is used for storing write data
    // at write address
    task post_input (mem_base_object  input_object);
        mem_object[input_object.addr] = input_object;
    endtask
    // post_output method is used by the output monitor to 
    // compare the output of memory with expected data
    task post_output (mem_base_object  output_object);
        // Check if address exists in scoreboard  
        if (mem_object[output_object.addr] != null) begin 
            mem_base_object  in_mem = mem_object[output_object.addr];
            $display("scoreboard : Found Address %x in list",output_object.addr);
            if (output_object.data != in_mem.data)  begin
                $display ("Scoreboard : Error : Exp data and Got data don't match");
                $display("             Expected -> %x",
                    in_mem.data);
                $display("             Got      -> %x",
                    output_object.data);
            end 
            else begin
                $display("Scoreboard : Exp data and Got data match");
            end
        end
    endtask
  
endclass

class mem_ip_monitor;
    mem_base_object mem_object;
    mem_scoreboard  sb;
    virtual mem_if       ports;
  
    function new (mem_scoreboard sb,virtual mem_if ports);
        this.sb    = sb;
        this.ports = ports;
    endfunction

    task input_monitor();
        while (1) begin
            @ (posedge ports.clock);
            if ((ports.en      == 1) && (ports.read_write == 1)) begin
                mem_object = new();
                $display("input_monitor : Memory wr access-> Address : %x Data : %x", 
                    ports.address,ports.data_in);
                mem_object.addr = ports.address;
                mem_object.data = ports.data_in;
                sb.post_input(mem_object);
            end
        end
    endtask
  
endclass

class mem_op_monitor;
    mem_base_object mem_object;
    mem_scoreboard  sb;
    virtual mem_if  ports;
  
    function new (mem_scoreboard sb,virtual mem_if ports);
        this.sb    = sb;
        this.ports = ports;
    endfunction

    task output_monitor();
        while (1) begin
            @ (negedge ports.clock);
            if ((ports.en      == 1) && (ports.read_write == 0)) begin
            mem_object = new();
            $display("Output_monitor : Memory rd access-> Address : %x Data : %x", 
                ports.address,ports.data_out);
            mem_object.addr = ports.address;
            mem_object.data = ports.data_out;
            sb.post_output(mem_object);
            end
        end
    endtask

endclass

program environment #(
    parameter clock_num=20
)(
    mem_if ports
);
    mem_txgen txgen;
    mem_scoreboard sb;
    mem_ip_monitor ipm;
    mem_op_monitor opm;

    initial begin
        sb    = new();
        ipm   = new (sb, ports);
        opm   = new (sb, ports);
        txgen = new(ports);
        fork
            ipm.input_monitor();
            opm.output_monitor();
        join_none
        txgen.gen_cmds();
        repeat (clock_num) @ (posedge ports.clock);
    end
endprogram

module tb_top;
    mem_if vif();
    memory memory_0(vif);
    environment #(20) env(vif);

    always #5 vif.clock = ~ vif.clock;

    initial vif.clock = 0;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end

endmodule