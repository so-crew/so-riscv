`include "arch_state.sv"
`include "datapath.sv"
`include "control.sv"

/* verilator lint_off UNOPTFLAT */
module single_cycle_r32i(
  input clk,
  input en,
  input prog,
  input [31:0] addr,
  input [31:0] instr
);
  bit half_clk = 0;
  
  // register file outputs
  bit [31:0] reg_data_a;
  bit [31:0] reg_data_b;
  
  // program counter outputs
  bit [31:0] pc_out;
  
  // instruction memory outputs
  bit [31:0] instr_mem_o;
  
  // data memory outputs
  bit [31:0] data_mem_out;

  // data memory masker/extender signals
  bit [2:0] data_mem_i_mask_ext_cmd;
  bit [2:0] data_mem_o_mask_ext_cmd;
  bit [31:0] data_mem_i_masked;
  bit [31:0] data_mem_o_masked;
  
  // instruction decoder outputs
  bit [6:0] opcode;
  bit [2:0] funct3;
  bit [6:0] funct7;
  bit [4:0] rs1;
  bit [4:0] rs2;
  bit [4:0] rd;
  bit [19:0] imm20;
  
  // extender outputs
  bit [31:0] ext_out;
  
  // alu outputs
  bit [31:0] alu_out;
  bit alu_out_sign;
  bit alu_ab_eq;
  bit alu_c_sign;
  
  // control unit outputs
  bit [1:0] ext_cmd;
  bit reg_file_wen;
  bit [2:0] reg_file_src;
  bit data_mem_en;
  bit data_mem_rw;
  bit alu_src_a;
  bit alu_src_b;
  bit [2:0] alu_cmd;
  bit [1:0] pc_inc_src;
  bit pc_branch;
  bit pc_jump_rel;
  
  // stage manager outputs
  bit if_stage;
  bit ex_stage;
  bit wb_stage;
  
  // next program counter stuff
  bit [31:0] pc_jump, pc_inc, pc_inc_next, pc_next;
  always @(posedge clk) begin
    if (if_stage) pc_inc <= pc_inc_next;
  end
  always_comb begin
    pc_inc_next = pc_out + 4;
    case (pc_inc_src)
      2'b01: pc_jump = ext_out;
      2'b10: pc_jump = alu_out;
      default: pc_jump = 4;
    endcase
  end
  
  // register file write source
  bit [31:0] reg_file_wdata;
  always_comb begin
    case (reg_file_src)
      3'b000: reg_file_wdata = data_mem_o_masked;
      3'b001: reg_file_wdata = alu_out;
      3'b010: reg_file_wdata = pc_inc;
      3'b011: reg_file_wdata = ext_out;
      3'b100: reg_file_wdata = alu_c_sign ? 32'h00000001 : 32'h00000000;
      default: reg_file_wdata = 32'h00000000;
    endcase
  end
  
  stage_manager stg_mngr(
    .clk(clk),
    .en(~prog),
    .if_stage(if_stage),
    .ex_stage(ex_stage),
    .wb_stage(wb_stage)
  );
  
  control_unit cntrl_unit(
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .alu_ab_eq(alu_ab_eq),
    .alu_c_sign(alu_c_sign),
    .ext_cmd(ext_cmd),
    .reg_file_wen(reg_file_wen),
    .reg_file_src(reg_file_src),
    .data_mem_en(data_mem_en),
    .data_mem_rw(data_mem_rw),
    .alu_src_a(alu_src_a),
    .alu_src_b(alu_src_b),
    .alu_cmd(alu_cmd),
    .pc_inc_src(pc_inc_src),
    .pc_branch(pc_branch),
    .pc_jump_rel(pc_jump_rel),
    .data_mem_i_mask_ext_cmd(data_mem_i_mask_ext_cmd),
    .data_mem_o_mask_ext_cmd(data_mem_o_mask_ext_cmd)
  );
  
  instruction_decoder instr_dec(
    .instr(instr_mem_o),
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .imm20(imm20)
  );
  
  extender ext(
    .in(imm20),
    .cmd(ext_cmd),
    .in_ext(ext_out)
  );
  
  register_file reg_file(
    .clk(clk),
    .rstn(1'b1),
    .en(1'b1),
    .wen(reg_file_wen & wb_stage),
    .w_addr(rd),
    .w_data(reg_file_wdata),
    .r_addr_a(rs1),
    .r_addr_b(rs2),
    .r_data_a(reg_data_a),
    .r_data_b(reg_data_b)
  );
  
  program_counter pc(
    .clk(clk),
    .rstn(~prog),
    .en(ex_stage),
    .next_cnt(pc_branch ? pc_jump_rel ? pc_out + pc_jump : pc_jump : pc_inc),
    .cnt(pc_out)
  );
  
  instruction_memory instr_mem(
    .clk(clk),
    .rstn(1'b1),
    .en(wb_stage),
    .wen(prog),
    .addr(prog ? addr : pc_out),
    .data_i(instr),
    .data_o(instr_mem_o)
  );

  data_masker_extender data_mem_i_mask_ext(
    .in(reg_data_b),
    .cmd(data_mem_i_mask_ext_cmd),
    .out(data_mem_i_masked)
  );

  data_masker_extender data_mem_o_mask_ext(
    .in(data_mem_out),
    .cmd(data_mem_o_mask_ext_cmd),
    .out(data_mem_o_masked)
  );
  
  data_memory data_mem(
    .clk(clk),
    .rstn(1'b1),
    .en(data_mem_en),
    .wen(ex_stage & data_mem_rw),
    .addr(alu_out),
    .data_i(data_mem_i_masked),
    .data_o(data_mem_out)
  );
  
  alu alu_inst(
    .cmd(alu_cmd),
    .a(alu_src_a ? reg_data_a : pc_out),
    .b(alu_src_b ? reg_data_b : ext_out),
    .c(alu_out),
    .c_sign(alu_c_sign),
    .ab_eq(alu_ab_eq)
  );
endmodule
/* verilator lint_on UNOPTFLAT */