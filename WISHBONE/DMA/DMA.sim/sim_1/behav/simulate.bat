@echo off
set xv_path=C:\\Xilinx\\Vivado\\2014.3\\bin
call %xv_path%/xsim DMA_WISHBONE_TOPLEVEL_tb_behav -key {Behavioral:sim_1:Functional:DMA_WISHBONE_TOPLEVEL_tb} -tclbatch DMA_WISHBONE_TOPLEVEL_tb.tcl -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
