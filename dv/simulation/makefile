SEED           = 0
TEST           = 01_example
UVM_TEST       = cpu_basic_test
SOFTWARE_DIR   = ${DV_HOME}/tests/${TEST}
REF_DIR        = ${SOFTWARE_DIR}/ref
SIMULATION_DIR = ${DV_HOME}/simulation/works
LOG_NAME       = log
LOG_DIR        = ${SIMULATION_DIR}/${LOG_NAME}
COMP_DIR       = ${LOG_DIR}/comp
SIM_DIR        = ${LOG_DIR}/${TEST}

prepare_log_dir:
	$(if $(wildcard $(LOG_DIR)),,mkdir -p $(LOG_DIR))

prepare_comp_dir:
	$(if $(wildcard ${COMP_DIR}),,$(if $(wildcard log/comp),ln -s ../log/comp $(LOG_DIR)/., mkdir -p ${COMP_DIR}))

prepare_sim_dir:
	$(if $(wildcard $(SIM_DIR)),,mkdir -p $(SIM_DIR))
	@ln -sf ${PRJ_HOME}/dv/c/run_swf_csim.py ${SIM_DIR}/.

prepare_ref_dir:
	$(if $(wildcard $(REF_DIR)),\cp -rf $(REF_DIR)/*.txt $(SIM_DIR)/,)

software:
	cd ${SOFTWARE_DIR}; \
	make clean; \
	make all; \

cpu: prepare_log_dir prepare_comp_dir
	cd ${COMP_DIR}; \
	vlogan -full64 +v2k -debug_access+all -timescale=1ns/1ps -nc \
		-kdb +lint=TFIPC-L +vcs+initreg+random -override_timescale=1ns/1ps +vcs+loopreport \
		-cm line+branch+cond+tgl+fsm+assert \
		+define+PLATFORM_SIM=1 \
		+incdir+${DE_HOME}/rtl/inc \
		-f ${DE_HOME}/vc/cpu.vc \
		-f ${DV_HOME}/vc/tb_cpu.vc \
		-l compile.log; \
	vcs -full64 -o ${COMP_DIR}/cpu.simv -ntb_opts -debug_all -debug_region+cell+encrypt +vcs+dumparrays \
		-LDFLAGS -Wl,--no-as-needed \
		-cm line+branch+cond+tgl+fsm+assert \
		-debug_acc+all+dmptf  -debug_access+all -debug_region+cell+encrypt -top tb_cpu +lint=TFIPC-L \
		+vcs+initreg+random +vcs+loopreport +vpi \
		-l elaborate.log


run: prepare_log_dir prepare_comp_dir prepare_sim_dir prepare_ref_dir cpu software
	cp ${SOFTWARE_DIR}/output/* ${SIM_DIR}/; \
	cd ${SIM_DIR}; \
	${COMP_DIR}/cpu.simv +vcs+initreg+0 -cm line+branch+cond+tgl+fsm+assert \
	-l run.log +ntb_random_seed=${SEED} -gui

clean:
	@rm -rf ${COMP_DIR};
	@rm -rf ucli.key *.simv *.simv.*  DVEfiles csrc inter.vpd swf.fsdb vc_hdrs.h
	@rm -rf dump* verdi* run.log runext uvm_comp.log comp*log  elab*log *.so *.txt
	@rm -rf work.lib++
	@rm -rf novas*
	@rm -rf 64 AN.DB

clean_test:
	@rm -rf ${SIM_DIR}

help:
	@echo "--- compile --------------------------------"
	@echo "-   make clean; make pure_swf"
	@echo "-   make clean; make spu"
	@echo "--- run cases ------------------------------"
	@echo "-   single mode: ...
	@echo "-   gui   mode: make run TEST=01_example
	@echo "--- run regression -------------------------"
	@echo "-   ...
	@echo "--------------------------------------------"
