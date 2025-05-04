compile:
	verilator --binary -j 0 +incdir+hdl sim/core_tb.sv --top-module single_cycle_r32i_tb --trace

run:
	./obj_dir/Vsingle_cycle_r32i_tb

display:
	gtkwave dump.vcd

default:
	verilator --binary -j 0 +incdir+hdl sim/core_tb.sv --top-module single_cycle_r32i_tb --trace
	./obj_dir/Vsingle_cycle_r32i_tb
	gtkwave dump.vcd
