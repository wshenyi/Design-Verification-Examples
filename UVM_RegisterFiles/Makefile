# make          <- runs simv (after compiling simv if needed)
# make all      <- runs simv (after compiling simv if needed)
# make simv     <- compile simv if needed (but do not run)
# make syn      <- runs syn_simv (after synthesizing if needed then 
#                                 compiling synsimv if needed)
# make clean    <- remove files created during compilations (but not synthesis)
# make nuke     <- remove all files created during compilation and synthesis
#
# To compile additional files, add them to the TESTBENCH or SIMFILES as needed
# Every .vg file will need its own rule and one or more synthesis scripts
# The information contained here (in the rules for those vg files) will be 
# similar to the information in those scripts but that seems hard to avoid.
#
#

##########################################################################
# IF YOU AREN'T USING A CAEN MACHINE, CHANGE THIS TO FALSE OR OVERRIDE IT
CAEN = 1
##########################################################################
ifeq (1, $(CAEN))
	GCC = riscv gcc
	OBJDUMP = riscv objdump
	AS = riscv as
	ELF2HEX = riscv elf2hex
else
	GCC = riscv64-unknown-elf-gcc
	OBJDUMP = riscv64-unknown-elf-objdump
	AS = riscv64-unknown-elf-as
	ELF2HEX = elf2hex
endif

UVM_HOME = /home/wshenyi/UVM
### With DPI
# VCS = vcs -V -sverilog +vc +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm.sv $(UVM_HOME)/src/dpi/uvm_dpi.cc\
# 	 -Mupdate -line -full64 +vcs+vcdpluson -debug_acc+pp+dmptf -debug_region+cell+encrypt \
# 	 -CFLAGS -DVCS

### Without DPI
VCS = vcs -V -sverilog +vc +define+UVM_NO_DPI +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm.sv\
	 -Mupdate -line -full64 +vcs+vcdpluson -debug_acc+pp+dmptf -debug_region+cell+encrypt


# SIMULATION CONFIG

HEADERS   = header.sv
TESTBENCH = tb_transaction.sv tb_sequence.sv tb_driver.sv tb_monitor.sv tb_driver.sv\
			tb_agent.sv tb_scoreboard.sv tb_environment.sv tb_test.sv tb_top.sv
DESIGNFILES = DUT.sv interface.sv
SIMFILES  = $(DESIGNFILES)

################################################################################
## RULES
################################################################################

# Default target:
all:    simv
	./simv | tee program.out

.PHONY: all

# Simulation:

sim:	simv
	./simv | tee sim_program.out

simv:	$(HEADERS) $(SIMFILES) $(TESTBENCH)
	$(VCS) $^ -o simv

.PHONY: sim


# Debugging

dve:	sim
	./simv -gui &

dve_syn: syn_simv 
	./syn_simv -gui &

.PHONY: dve dve_syn 

clean:
	rm -rf *simv *simv.daidir csrc vcs.key program.out *.key
	rm -rf vis_simv vis_simv.daidir
	rm -rf dve* inter.vpd DVEfiles
	rm -rf syn_simv syn_simv.daidir syn_program.out
	rm -rf synsimv synsimv.daidir csrc vcdplus.vpd vcs.key synprog.out pipeline.out writeback.out vc_hdrs.h
	rm -f *.elf *.dump *.mem debug_bin *.old

nuke:	clean
	rm -rf *.vg *.rep *.ddc *.chk *.log *.syn
	rm -rf *.out command.log *.db *.svf *.mr *.pvl
