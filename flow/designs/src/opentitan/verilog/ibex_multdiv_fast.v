module ibex_multdiv_fast (
	clk_i,
	rst_ni,
	mult_en_i,
	div_en_i,
	operator_i,
	signed_mode_i,
	op_a_i,
	op_b_i,
	alu_adder_ext_i,
	alu_adder_i,
	equal_to_zero,
	alu_operand_a_o,
	alu_operand_b_o,
	multdiv_result_o,
	valid_o
);
	localparam [1:0] ALBL = 0;
	localparam [2:0] MD_IDLE = 0;
	localparam [1:0] ALBH = 1;
	localparam [2:0] MD_ABS_A = 1;
	localparam [1:0] AHBL = 2;
	localparam [2:0] MD_ABS_B = 2;
	localparam [1:0] AHBH = 3;
	localparam [2:0] MD_COMP = 3;
	localparam [2:0] MD_LAST = 4;
	localparam [2:0] MD_CHANGE_SIGN = 5;
	localparam [2:0] MD_FINISH = 6;
	input wire clk_i;
	input wire rst_ni;
	input wire mult_en_i;
	input wire div_en_i;
	input wire [1:0] operator_i;
	input wire [1:0] signed_mode_i;
	input wire [31:0] op_a_i;
	input wire [31:0] op_b_i;
	input wire [33:0] alu_adder_ext_i;
	input wire [31:0] alu_adder_i;
	input wire equal_to_zero;
	output reg [32:0] alu_operand_a_o;
	output reg [32:0] alu_operand_b_o;
	output wire [31:0] multdiv_result_o;
	output wire valid_o;
	parameter [31:0] PMP_MAX_REGIONS = 16;
	parameter [31:0] PMP_CFG_W = 8;
	parameter [31:0] PMP_I = 0;
	parameter [31:0] PMP_D = 1;
	parameter [11:0] CSR_OFF_PMP_CFG = 12'h3A0;
	parameter [11:0] CSR_OFF_PMP_ADDR = 12'h3B0;
	parameter [11:0] CSR_OFF_MCOUNTER_SETUP = 12'h320;
	parameter [11:0] CSR_OFF_MCOUNTER = 12'hB00;
	parameter [11:0] CSR_OFF_MCOUNTERH = 12'hB80;
	parameter [11:0] CSR_MASK_MCOUNTER = 12'hFE0;
	parameter [31:0] CSR_MSTATUS_MIE_BIT = 3;
	parameter [31:0] CSR_MSTATUS_MPIE_BIT = 7;
	parameter [31:0] CSR_MSTATUS_MPP_BIT_LOW = 11;
	parameter [31:0] CSR_MSTATUS_MPP_BIT_HIGH = 12;
	parameter [31:0] CSR_MSTATUS_MPRV_BIT = 17;
	parameter [31:0] CSR_MSTATUS_TW_BIT = 21;
	parameter [31:0] CSR_MSIX_BIT = 3;
	parameter [31:0] CSR_MTIX_BIT = 7;
	parameter [31:0] CSR_MEIX_BIT = 11;
	parameter [31:0] CSR_MFIX_BIT_LOW = 16;
	parameter [31:0] CSR_MFIX_BIT_HIGH = 30;
	localparam [0:0] IMM_A_Z = 0;
	localparam [0:0] OP_B_REG_B = 0;
	localparam [1:0] CSR_OP_READ = 0;
	localparam [1:0] EXC_PC_EXC = 0;
	localparam [1:0] MD_OP_MULL = 0;
	localparam [1:0] OP_A_REG_A = 0;
	localparam [1:0] RF_WD_LSU = 0;
	localparam [2:0] IMM_B_I = 0;
	localparam [2:0] PC_BOOT = 0;
	localparam [4:0] ALU_ADD = 0;
	localparam [0:0] IMM_A_ZERO = 1;
	localparam [0:0] OP_B_IMM = 1;
	localparam [1:0] CSR_OP_WRITE = 1;
	localparam [1:0] EXC_PC_IRQ = 1;
	localparam [1:0] MD_OP_MULH = 1;
	localparam [1:0] OP_A_FWD = 1;
	localparam [1:0] RF_WD_EX = 1;
	localparam [2:0] IMM_B_S = 1;
	localparam [2:0] PC_JUMP = 1;
	localparam [4:0] ALU_SUB = 1;
	localparam [4:0] ALU_LE = 10;
	localparam [4:0] ALU_LEU = 11;
	localparam [4:0] ALU_GT = 12;
	localparam [11:0] CSR_MSTATUS = 12'h300;
	localparam [11:0] CSR_MISA = 12'h301;
	localparam [11:0] CSR_MIE = 12'h304;
	localparam [11:0] CSR_MTVEC = 12'h305;
	localparam [11:0] CSR_MCOUNTINHIBIT = 12'h320;
	localparam [11:0] CSR_MSCRATCH = 12'h340;
	localparam [11:0] CSR_MEPC = 12'h341;
	localparam [11:0] CSR_MCAUSE = 12'h342;
	localparam [11:0] CSR_MTVAL = 12'h343;
	localparam [11:0] CSR_MIP = 12'h344;
	localparam [11:0] CSR_PMPCFG0 = 12'h3A0;
	localparam [11:0] CSR_PMPCFG1 = 12'h3A1;
	localparam [11:0] CSR_PMPCFG2 = 12'h3A2;
	localparam [11:0] CSR_PMPCFG3 = 12'h3A3;
	localparam [11:0] CSR_PMPADDR0 = 12'h3B0;
	localparam [11:0] CSR_PMPADDR1 = 12'h3B1;
	localparam [11:0] CSR_PMPADDR2 = 12'h3B2;
	localparam [11:0] CSR_PMPADDR3 = 12'h3B3;
	localparam [11:0] CSR_PMPADDR4 = 12'h3B4;
	localparam [11:0] CSR_PMPADDR5 = 12'h3B5;
	localparam [11:0] CSR_PMPADDR6 = 12'h3B6;
	localparam [11:0] CSR_PMPADDR7 = 12'h3B7;
	localparam [11:0] CSR_PMPADDR8 = 12'h3B8;
	localparam [11:0] CSR_PMPADDR9 = 12'h3B9;
	localparam [11:0] CSR_PMPADDR10 = 12'h3BA;
	localparam [11:0] CSR_PMPADDR11 = 12'h3BB;
	localparam [11:0] CSR_PMPADDR12 = 12'h3BC;
	localparam [11:0] CSR_PMPADDR13 = 12'h3BD;
	localparam [11:0] CSR_PMPADDR14 = 12'h3BE;
	localparam [11:0] CSR_PMPADDR15 = 12'h3BF;
	localparam [11:0] CSR_DCSR = 12'h7b0;
	localparam [11:0] CSR_DPC = 12'h7b1;
	localparam [11:0] CSR_DSCRATCH0 = 12'h7b2;
	localparam [11:0] CSR_DSCRATCH1 = 12'h7b3;
	localparam [11:0] CSR_MCYCLE = 12'hB00;
	localparam [11:0] CSR_MINSTRET = 12'hB02;
	localparam [11:0] CSR_MCYCLEH = 12'hB80;
	localparam [11:0] CSR_MINSTRETH = 12'hB82;
	localparam [11:0] CSR_MHARTID = 12'hF14;
	localparam [4:0] ALU_GTU = 13;
	localparam [4:0] ALU_GE = 14;
	localparam [4:0] ALU_GEU = 15;
	localparam [4:0] ALU_EQ = 16;
	localparam [4:0] ALU_NE = 17;
	localparam [4:0] ALU_SLT = 18;
	localparam [4:0] ALU_SLTU = 19;
	localparam [1:0] CSR_OP_SET = 2;
	localparam [1:0] EXC_PC_DBD = 2;
	localparam [1:0] MD_OP_DIV = 2;
	localparam [1:0] OP_A_CURRPC = 2;
	localparam [1:0] RF_WD_CSR = 2;
	localparam [2:0] IMM_B_B = 2;
	localparam [2:0] PC_EXC = 2;
	localparam [4:0] ALU_XOR = 2;
	localparam [1:0] PMP_ACC_EXEC = 2'b00;
	localparam [1:0] PMP_MODE_OFF = 2'b00;
	localparam [1:0] PRIV_LVL_U = 2'b00;
	localparam [1:0] PMP_ACC_WRITE = 2'b01;
	localparam [1:0] PMP_MODE_TOR = 2'b01;
	localparam [1:0] PRIV_LVL_S = 2'b01;
	localparam [1:0] PMP_ACC_READ = 2'b10;
	localparam [1:0] PMP_MODE_NA4 = 2'b10;
	localparam [1:0] PRIV_LVL_H = 2'b10;
	localparam [1:0] PMP_MODE_NAPOT = 2'b11;
	localparam [1:0] PRIV_LVL_M = 2'b11;
	localparam [4:0] ALU_SLET = 20;
	localparam [4:0] ALU_SLETU = 21;
	localparam [1:0] CSR_OP_CLEAR = 3;
	localparam [1:0] EXC_PC_DBG_EXC = 3;
	localparam [1:0] MD_OP_REM = 3;
	localparam [1:0] OP_A_IMM = 3;
	localparam [2:0] IMM_B_U = 3;
	localparam [2:0] PC_ERET = 3;
	localparam [4:0] ALU_OR = 3;
	localparam [2:0] DBG_CAUSE_NONE = 3'h0;
	localparam [2:0] DBG_CAUSE_EBREAK = 3'h1;
	localparam [2:0] DBG_CAUSE_TRIGGER = 3'h2;
	localparam [2:0] DBG_CAUSE_HALTREQ = 3'h3;
	localparam [2:0] DBG_CAUSE_STEP = 3'h4;
	localparam [2:0] IMM_B_J = 4;
	localparam [2:0] PC_DRET = 4;
	localparam [4:0] ALU_AND = 4;
	localparam [3:0] XDEBUGVER_NO = 4'd0;
	localparam [3:0] XDEBUGVER_NONSTD = 4'd15;
	localparam [3:0] XDEBUGVER_STD = 4'd4;
	localparam [2:0] IMM_B_INCR_PC = 5;
	localparam [4:0] ALU_SRA = 5;
	localparam [2:0] IMM_B_INCR_ADDR = 6;
	localparam [4:0] ALU_SRL = 6;
	localparam [4:0] ALU_SLL = 7;
	localparam [6:0] OPCODE_LOAD = 7'h03;
	localparam [6:0] OPCODE_MISC_MEM = 7'h0f;
	localparam [6:0] OPCODE_OP_IMM = 7'h13;
	localparam [6:0] OPCODE_AUIPC = 7'h17;
	localparam [6:0] OPCODE_STORE = 7'h23;
	localparam [6:0] OPCODE_OP = 7'h33;
	localparam [6:0] OPCODE_LUI = 7'h37;
	localparam [6:0] OPCODE_BRANCH = 7'h63;
	localparam [6:0] OPCODE_JALR = 7'h67;
	localparam [6:0] OPCODE_JAL = 7'h6f;
	localparam [6:0] OPCODE_SYSTEM = 7'h73;
	localparam [4:0] ALU_LT = 8;
	localparam [4:0] ALU_LTU = 9;
	localparam [5:0] EXC_CAUSE_INSN_ADDR_MISA = {1'b0, 5'd00};
	localparam [5:0] EXC_CAUSE_INSTR_ACCESS_FAULT = {1'b0, 5'd01};
	localparam [5:0] EXC_CAUSE_ILLEGAL_INSN = {1'b0, 5'd02};
	localparam [5:0] EXC_CAUSE_BREAKPOINT = {1'b0, 5'd03};
	localparam [5:0] EXC_CAUSE_LOAD_ACCESS_FAULT = {1'b0, 5'd05};
	localparam [5:0] EXC_CAUSE_STORE_ACCESS_FAULT = {1'b0, 5'd07};
	localparam [5:0] EXC_CAUSE_ECALL_UMODE = {1'b0, 5'd08};
	localparam [5:0] EXC_CAUSE_ECALL_MMODE = {1'b0, 5'd11};
	localparam [5:0] EXC_CAUSE_IRQ_SOFTWARE_M = {1'b1, 5'd03};
	localparam [5:0] EXC_CAUSE_IRQ_TIMER_M = {1'b1, 5'd07};
	localparam [5:0] EXC_CAUSE_IRQ_EXTERNAL_M = {1'b1, 5'd11};
	localparam [5:0] EXC_CAUSE_IRQ_NM = {1'b1, 5'd31};
	reg [4:0] div_counter_q;
	reg [4:0] div_counter_n;
	reg [1:0] mult_state_q;
	reg [1:0] mult_state_n;
	reg [2:0] md_state_q;
	reg [2:0] md_state_n;
	wire signed [34:0] mac_res_signed;
	wire [34:0] mac_res_ext;
	reg [33:0] mac_res_q;
	reg [33:0] mac_res_n;
	wire [33:0] mac_res;
	reg [33:0] op_remainder_n;
	reg [15:0] mult_op_a;
	reg [15:0] mult_op_b;
	reg [33:0] accum;
	reg sign_a;
	reg sign_b;
	wire div_sign_a;
	wire div_sign_b;
	wire signed_mult;
	reg is_greater_equal;
	wire div_change_sign;
	wire rem_change_sign;
	wire [31:0] one_shift;
	reg [31:0] op_denominator_q;
	reg [31:0] op_numerator_q;
	reg [31:0] op_quotient_q;
	reg [31:0] op_denominator_n;
	reg [31:0] op_numerator_n;
	reg [31:0] op_quotient_n;
	wire [31:0] next_remainder;
	wire [32:0] next_quotient;
	wire [32:0] res_adder_h;
	reg mult_valid;
	reg div_valid;
	always @(posedge clk_i or negedge rst_ni) begin : proc_mult_state_q
		if (!rst_ni) begin
			mult_state_q <= ALBL;
			mac_res_q <= 1'sb0;
			div_counter_q <= 1'sb0;
			md_state_q <= MD_IDLE;
			op_denominator_q <= 1'sb0;
			op_numerator_q <= 1'sb0;
			op_quotient_q <= 1'sb0;
		end
		else begin
			if (mult_en_i)
				mult_state_q <= mult_state_n;
			if (div_en_i) begin
				div_counter_q <= div_counter_n;
				op_denominator_q <= op_denominator_n;
				op_numerator_q <= op_numerator_n;
				op_quotient_q <= op_quotient_n;
				md_state_q <= md_state_n;
			end
			case (1'b1)
				mult_en_i: mac_res_q <= mac_res_n;
				div_en_i: mac_res_q <= op_remainder_n;
				default: mac_res_q <= mac_res_q;
			endcase
		end
	end
	assign signed_mult = (signed_mode_i != 2'b00);
	assign multdiv_result_o = (div_en_i ? mac_res_q[31:0] : mac_res_n[31:0]);
	assign mac_res_signed = (($signed({sign_a, mult_op_a}) * $signed({sign_b, mult_op_b})) + $signed(accum));
	assign mac_res_ext = $unsigned(mac_res_signed);
	assign mac_res = mac_res_ext[33:0];
	assign res_adder_h = alu_adder_ext_i[33:1];
	assign next_remainder = (is_greater_equal ? res_adder_h[31:0] : mac_res_q[31:0]);
	assign next_quotient = (is_greater_equal ? ({1'b0, op_quotient_q} | {1'b0, one_shift}) : {1'b0, op_quotient_q});
	assign one_shift = ({31'b0, 1'b1} << div_counter_q);
	always @(*)
		if (((mac_res_q[31] ^ op_denominator_q[31]) == 1'b0))
			is_greater_equal = (res_adder_h[31] == 1'b0);
		else
			is_greater_equal = mac_res_q[31];
	assign div_sign_a = (op_a_i[31] & signed_mode_i[0]);
	assign div_sign_b = (op_b_i[31] & signed_mode_i[1]);
	assign div_change_sign = (div_sign_a ^ div_sign_b);
	assign rem_change_sign = div_sign_a;
	always @(*) begin : md_fsm
		div_counter_n = (div_counter_q - 5'h1);
		op_remainder_n = mac_res_q;
		op_quotient_n = op_quotient_q;
		md_state_n = md_state_q;
		op_numerator_n = op_numerator_q;
		op_denominator_n = op_denominator_q;
		alu_operand_a_o = {32'h0, 1'b1};
		alu_operand_b_o = {~op_b_i, 1'b1};
		div_valid = 1'b0;
		case (md_state_q)
			MD_IDLE: begin
				if ((operator_i == MD_OP_DIV)) begin
					op_remainder_n = 1'sb1;
					md_state_n = (equal_to_zero ? MD_FINISH : MD_ABS_A);
				end
				else begin
					op_remainder_n = {2'b0, op_a_i};
					md_state_n = (equal_to_zero ? MD_FINISH : MD_ABS_A);
				end
				alu_operand_a_o = {32'h0, 1'b1};
				alu_operand_b_o = {~op_b_i, 1'b1};
				div_counter_n = 5'd31;
			end
			MD_ABS_A: begin
				op_quotient_n = 1'sb0;
				op_numerator_n = (div_sign_a ? alu_adder_i : op_a_i);
				md_state_n = MD_ABS_B;
				div_counter_n = 5'd31;
				alu_operand_a_o = {32'h0, 1'b1};
				alu_operand_b_o = {~op_a_i, 1'b1};
			end
			MD_ABS_B: begin
				op_remainder_n = {33'h0, op_numerator_q[31]};
				op_denominator_n = (div_sign_b ? alu_adder_i : op_b_i);
				md_state_n = MD_COMP;
				div_counter_n = 5'd31;
				alu_operand_a_o = {32'h0, 1'b1};
				alu_operand_b_o = {~op_b_i, 1'b1};
			end
			MD_COMP: begin
				op_remainder_n = {1'b0, next_remainder[31:0], op_numerator_q[div_counter_n]};
				op_quotient_n = next_quotient[31:0];
				md_state_n = ((div_counter_q == 5'd1) ? MD_LAST : MD_COMP);
				alu_operand_a_o = {mac_res_q[31:0], 1'b1};
				alu_operand_b_o = {~op_denominator_q[31:0], 1'b1};
			end
			MD_LAST: begin
				if ((operator_i == MD_OP_DIV))
					op_remainder_n = {1'b0, next_quotient};
				else
					op_remainder_n = {2'b0, next_remainder[31:0]};
				alu_operand_a_o = {mac_res_q[31:0], 1'b1};
				alu_operand_b_o = {~op_denominator_q[31:0], 1'b1};
				md_state_n = MD_CHANGE_SIGN;
			end
			MD_CHANGE_SIGN: begin
				md_state_n = MD_FINISH;
				if ((operator_i == MD_OP_DIV))
					op_remainder_n = (div_change_sign ? {2'h0, alu_adder_i} : mac_res_q);
				else
					op_remainder_n = (rem_change_sign ? {2'h0, alu_adder_i} : mac_res_q);
				alu_operand_a_o = {32'h0, 1'b1};
				alu_operand_b_o = {~mac_res_q[31:0], 1'b1};
			end
			MD_FINISH: begin
				md_state_n = MD_IDLE;
				div_valid = 1'b1;
			end
			default: md_state_n = 1'bX;
		endcase
	end
	assign valid_o = (mult_valid | div_valid);
	always @(*) begin : mult_fsm
		mult_op_a = op_a_i[15:0];
		mult_op_b = op_b_i[15:0];
		sign_a = 1'b0;
		sign_b = 1'b0;
		accum = mac_res_q;
		mac_res_n = mac_res;
		mult_state_n = mult_state_q;
		mult_valid = 1'b0;
		case (mult_state_q)
			ALBL: begin
				mult_op_a = op_a_i[15:0];
				mult_op_b = op_b_i[15:0];
				sign_a = 1'b0;
				sign_b = 1'b0;
				accum = 1'sb0;
				mac_res_n = mac_res;
				mult_state_n = ALBH;
			end
			ALBH: begin
				mult_op_a = op_a_i[15:0];
				mult_op_b = op_b_i[31:16];
				sign_a = 1'b0;
				sign_b = (signed_mode_i[1] & op_b_i[31]);
				accum = {18'b0, mac_res_q[31:16]};
				if ((operator_i == MD_OP_MULL))
					mac_res_n = {2'b0, mac_res[15:0], mac_res_q[15:0]};
				else
					mac_res_n = mac_res;
				mult_state_n = AHBL;
			end
			AHBL: begin
				mult_op_a = op_a_i[31:16];
				mult_op_b = op_b_i[15:0];
				sign_a = (signed_mode_i[0] & op_a_i[31]);
				sign_b = 1'b0;
				if ((operator_i == MD_OP_MULL)) begin
					accum = {18'b0, mac_res_q[31:16]};
					mac_res_n = {2'b0, mac_res[15:0], mac_res_q[15:0]};
					mult_valid = 1'b1;
					mult_state_n = ALBL;
				end
				else begin
					accum = mac_res_q;
					mac_res_n = mac_res;
					mult_state_n = AHBH;
				end
			end
			AHBH: begin
				mult_op_a = op_a_i[31:16];
				mult_op_b = op_b_i[31:16];
				sign_a = (signed_mode_i[0] & op_a_i[31]);
				sign_b = (signed_mode_i[1] & op_b_i[31]);
				accum[17:0] = mac_res_q[33:16];
				accum[33:18] = {16 {(signed_mult & mac_res_q[33])}};
				mac_res_n = mac_res;
				mult_state_n = ALBL;
				mult_valid = 1'b1;
			end
			default: mult_state_n = 1'bX;
		endcase
	end
endmodule
