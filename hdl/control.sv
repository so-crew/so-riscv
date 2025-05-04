module stage_manager(
  input clk,
  input en,
  
  output if_stage,
  output ex_stage,
  output wb_stage
);
  localparam IDLE_STATE = 0;
  localparam FETCH_STATE = 1;
  localparam EXECUTE_STATE = 2;
  localparam WRITE_BACK_STATE = 3;
  
  bit [1:0] state, next_state;
  
  always_comb begin
    case (state)
      IDLE_STATE: next_state = en ? FETCH_STATE : IDLE_STATE;
      FETCH_STATE: next_state = en ? EXECUTE_STATE : IDLE_STATE;
      EXECUTE_STATE: next_state = en ? WRITE_BACK_STATE : IDLE_STATE;
      WRITE_BACK_STATE: next_state = en ? FETCH_STATE : IDLE_STATE;
    endcase
  end
  
  always @(posedge clk) begin
    if (~en) begin
      state <= 0;
    end
    else begin
      state <= next_state;
    end
  end
  
  assign if_stage = state == FETCH_STATE;
  assign ex_stage = state == EXECUTE_STATE;
  assign wb_stage = state == WRITE_BACK_STATE | state == IDLE_STATE & en;

endmodule

module alu_control_unit(
  input bit [6:0] opcode,
  input bit [2:0] funct3,
  input bit [6:0] funct7,
  
  output reg [2:0] cmd
);
  localparam LOAD_OPCODE = 7'b0000011;
  localparam STORE_OPCODE = 7'b0100011;
  localparam IMM_INTOP_OPCODE = 7'b0010011;
  localparam REG_INTOP_OPCODE = 7'b0110011;
  localparam BRANCH_OPCODE = 7'b1100011;
  localparam JUMP_OPCODE = 7'b1101111;
  localparam JUMP_IND_OPCODE = 7'b1100111;
  localparam LUI_OPCODE = 7'b0110111;
  localparam AUIPC_OPCODE = 7'b0010111;
  
  always_comb begin
    case (opcode)
        LOAD_OPCODE: cmd = 3'b000;
        STORE_OPCODE: cmd = 3'b000;
        IMM_INTOP_OPCODE: case (funct3)
            3'b000: cmd = 3'b000; //add
            3'b010: cmd = 3'b000; //slti
            3'b011: cmd = 3'b000; //sltiu
            3'b100: cmd = 3'b100; //xori
            3'b110: cmd = 3'b011; //ori
            3'b111: cmd = 3'b010; //andi
            3'b001: cmd = 3'b101; //slli
            3'b101: case (funct7)
                7'h00: cmd = 3'b110; //srli
                7'h20: cmd = 3'b111; //srai
            endcase
        endcase
    endcase
  end
  
endmodule

module control_unit(
  input [6:0] opcode,
  input [2:0] funct3,
  input [6:0] funct7,
  input alu_ab_eq,
  input alu_c_sign,
  
  output reg [1:0] ext_cmd,
  
  output reg reg_file_wen,
  output reg [2:0] reg_file_src, // mem. out, alu, pc inc., imm, slt
  
  output reg data_mem_en,
  output reg data_mem_rw, // 0 means read, 1 is write
  
  output reg [1:0] pc_inc_src, // +4, +imm, +alu_out
  output reg pc_branch,
  output reg pc_jump_rel,
  
  output reg alu_src_a,
  output reg alu_src_b,
  output reg [2:0] alu_cmd,

  output reg [2:0] data_mem_i_mask_ext_cmd,
  output reg [2:0] data_mem_o_mask_ext_cmd
);
  localparam LOAD_OPCODE = 7'b0000011;
  localparam STORE_OPCODE = 7'b0100011;
  localparam IMM_INTOP_OPCODE = 7'b0010011;
  localparam REG_INTOP_OPCODE = 7'b0110011;
  localparam BRANCH_OPCODE = 7'b1100011;
  localparam JUMP_OPCODE = 7'b1101111;
  localparam JUMP_IND_OPCODE = 7'b1100111;
  localparam LUI_OPCODE = 7'b0110111;
  localparam AUIPC_OPCODE = 7'b0010111;
  
  always_comb begin
    case (opcode)
      LOAD_OPCODE: begin
        reg_file_wen = 1;
        reg_file_src = 3'b000;
        
        data_mem_en = 1;
        data_mem_rw = 0;
        
        ext_cmd = 2'b00;
        
        alu_src_a = 1'b1;
        alu_src_b = 1'b0;
        alu_cmd = 3'b000;
        
        pc_inc_src = 2'b00;
        pc_branch = 1'b0;
        pc_jump_rel = 1'b0;
        
        data_mem_i_mask_ext_cmd = 3'b000;
        case (funct3)
          3'b000: data_mem_o_mask_ext_cmd = 3'b011;
          3'b001: data_mem_o_mask_ext_cmd = 3'b100;
          3'b010: data_mem_o_mask_ext_cmd = 3'b000;
          3'b100: data_mem_o_mask_ext_cmd = 3'b001;
          3'b101: data_mem_o_mask_ext_cmd = 3'b010;
          default: data_mem_o_mask_ext_cmd = 3'b000;
        endcase
      end
      STORE_OPCODE: begin
        reg_file_wen = 0;
        reg_file_src = 3'b000;
        
        data_mem_en = 1;
        data_mem_rw = 1;
        
        ext_cmd = 2'b00;
        
        alu_src_a = 1'b1;
        alu_src_b = 1'b0;
        alu_cmd = 3'b000;
        
        pc_inc_src = 2'b00;
        pc_branch = 1'b0;
        pc_jump_rel = 1'b0;
        
        data_mem_o_mask_ext_cmd = 3'b000;
        case (funct3)
          3'b000: data_mem_i_mask_ext_cmd = 3'b011;
          3'b001: data_mem_i_mask_ext_cmd = 3'b100;
          3'b010: data_mem_i_mask_ext_cmd = 3'b000;
          default: data_mem_i_mask_ext_cmd = 3'b000;
        endcase
      end
      BRANCH_OPCODE: begin
        reg_file_wen = 0;
        reg_file_src = 3'b000;
        
        data_mem_en = 1;
        data_mem_rw = 0;
        
        ext_cmd = 2'b10;
        
        alu_src_a = 1'b1;
        alu_src_b = 1'b1;
        alu_cmd = 3'b001;
        
        pc_inc_src = 2'b01;
        case (funct3)
          3'b000: pc_branch = alu_ab_eq;
          3'b001: pc_branch = ~alu_ab_eq;
          3'b100: pc_branch = alu_c_sign;
          3'b101: pc_branch = ~alu_c_sign;
          default: pc_branch = 1'b0;
        endcase
        pc_jump_rel = 1'b1;
        
        data_mem_i_mask_ext_cmd = 3'b000;
        data_mem_o_mask_ext_cmd = 3'b000;
      end
      IMM_INTOP_OPCODE: begin
        reg_file_wen = 1'b1;

        case (funct3)
          3'b010: reg_file_src = 3'b100;
          3'b011: reg_file_src = 3'b100;
          default: reg_file_src = 3'b001;
        endcase
        
        data_mem_en = 0;
        data_mem_rw = 0;
        
        ext_cmd = 2'b00;
        
        alu_src_a = 1'b1;
        alu_src_b = 1'b0;
        case (funct3)
          3'b000: alu_cmd = 3'b000;
          3'b001: alu_cmd = 3'b101;
          3'b010: alu_cmd = 3'b001;
          3'b011: alu_cmd = 3'b001;
          3'b100: alu_cmd = 3'b100;
          3'b101: alu_cmd = 3'b110;
          3'b110: alu_cmd = 3'b011;
          3'b111: alu_cmd = 3'b010;
        endcase
        
        pc_inc_src = 2'b00;
        pc_branch = 1'b0;
        pc_jump_rel = 1'b0;
        
        data_mem_i_mask_ext_cmd = 3'b000;
        data_mem_o_mask_ext_cmd = 3'b000;
      end
      REG_INTOP_OPCODE: begin
        reg_file_wen = 1'b1;
        case (funct3)
          3'b010: reg_file_src = 3'b100;
          3'b011: reg_file_src = 3'b100;
          default: reg_file_src = 3'b001;
        endcase
        
        data_mem_en = 0;
        data_mem_rw = 0;
        
        ext_cmd = 2'b11;
        
        alu_src_a = 1'b1;
        alu_src_b = 1'b1;

        case (funct3)
          3'b000: case (funct7)
            7'b0000000: alu_cmd = 3'b000;
            7'b0100000: alu_cmd = 3'b001;
            default: alu_cmd = 3'b000;
          endcase
          3'b001: alu_cmd = 3'b101;
          3'b010: alu_cmd = 3'b001;
          3'b011: alu_cmd = 3'b001;
          3'b100: alu_cmd = 3'b100;
          3'b101: alu_cmd = 3'b110;
          3'b110: alu_cmd = 3'b011;
          3'b111: alu_cmd = 3'b010;
        endcase
        
        pc_inc_src = 2'b00;
        pc_branch = 1'b0;
        pc_jump_rel = 1'b0;
        
        data_mem_i_mask_ext_cmd = 3'b000;
        data_mem_o_mask_ext_cmd = 3'b000;
      end
      JUMP_OPCODE: begin
        reg_file_wen = 1;
        reg_file_src = 3'b010;
        
        data_mem_en = 0;
        data_mem_rw = 0;
        
        ext_cmd = 2'b10;
        
        alu_src_a = 1'b0;
        alu_src_b = 1'b0;
        alu_cmd = 3'b000;
        
        pc_inc_src = 2'b10;
        pc_branch = 1'b1;
        pc_jump_rel = 1'b0;
        
        data_mem_i_mask_ext_cmd = 3'b000;
        data_mem_o_mask_ext_cmd = 3'b000;
      end
      JUMP_IND_OPCODE: begin
        reg_file_wen = 1;
        reg_file_src = 3'b010;
        
        data_mem_en = 0;
        data_mem_rw = 0;
        
        ext_cmd = 2'b00;
        
        alu_src_a = 1'b1;
        alu_src_b = 1'b0;
        alu_cmd = 3'b000;
        
        pc_inc_src = 2'b10;
        pc_branch = 1'b1;
        pc_jump_rel = 1'b0;
        
        data_mem_i_mask_ext_cmd = 3'b000;
        data_mem_o_mask_ext_cmd = 3'b000;
      end
      LUI_OPCODE: begin
        reg_file_wen = 1;
        reg_file_src = 3'b011;
        
        data_mem_en = 0;
        data_mem_rw = 0;
        
        ext_cmd = 2'b01;
        
        alu_src_a = 1'b0;
        alu_src_b = 1'b0;
        alu_cmd = 3'b000;
        
        pc_inc_src = 2'b00;
        pc_branch = 1'b0;
        pc_jump_rel = 1'b0;
        
        data_mem_i_mask_ext_cmd = 3'b000;
        data_mem_o_mask_ext_cmd = 3'b000;
      end
      AUIPC_OPCODE: begin
        reg_file_wen = 1'b1;
        reg_file_src = 3'b001;
        
        data_mem_en = 1'b0;
        data_mem_rw = 1'b0;
        
        ext_cmd = 2'b01;
        
        alu_src_a = 1'b1;
        alu_src_b = 1'b0;
        alu_cmd = 3'b000;
        
        pc_inc_src = 2'b00;
        pc_branch = 1'b0;
        pc_jump_rel = 1'b0;
        
        data_mem_i_mask_ext_cmd = 3'b000;
        data_mem_o_mask_ext_cmd = 3'b000;
      end
      default: begin
        reg_file_wen = 1'b0;
        reg_file_src = 3'b000;
        
        data_mem_en = 1'b0;
        data_mem_rw = 1'b0;
        
        ext_cmd = 2'b00;
        
        alu_src_a = 1'b0;
        alu_src_b = 1'b0;
        alu_cmd = 3'b000;
        
        pc_inc_src = 2'b00;
        pc_branch = 1'b0;
        pc_jump_rel = 1'b0;
        
        data_mem_i_mask_ext_cmd = 3'b000;
        data_mem_o_mask_ext_cmd = 3'b000;
      end
    endcase
  end
  
endmodule