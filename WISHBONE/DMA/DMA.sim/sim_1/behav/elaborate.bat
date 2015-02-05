@echo off
set xv_path=C:\\Xilinx\\Vivado\\2014.3\\bin
call %xv_path%/xelab  -wto 243dd12971454f77b81e6c003e7ae2c6 -m64 --debug typical --relax -L xil_defaultlib -L secureip --snapshot DMA_WISHBONE_TOPLEVEL_tb_behav xil_defaultlib.DMA_WISHBONE_TOPLEVEL_tb -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
