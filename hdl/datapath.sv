module instruction_decoder(
  input [31:0] instr,
  
  // for load and store instructions
  output bit [6:0] opcode,
  output bit [4:0] rd, 
  output bit [4:0] rs1, 
  output bit [4:0] rs2,
  output bit [2:0] funct3,
  output bit [6:0] funct7,
  output bit [19:0] imm20
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
  
  always_latch begin
    opcode = instr[6:0];
    
    case (opcode)
      LOAD_OPCODE: begin
        rd     = instr[11:7];
        funct3 = instr[14:12];
        rs1    = instr[19:15];
        imm20  = {8'h00, instr[31:20]};
      end
      STORE_OPCODE: begin
        funct3 = instr[14:12];
        rs1    = instr[19:15];
        rs2    = instr[24:20];
        imm20  = {8'h00, instr[31:25], instr[11:7]};
      end
      IMM_INTOP_OPCODE: begin
        rd     = instr[11:7];
        funct3 = instr[14:12];
        rs1    = instr[19:15];
        imm20  = {8'h00, instr[31:20]};
      end
      REG_INTOP_OPCODE: begin
        funct3 = instr[14:12];
        funct7 = instr[31:25];
        rd     = instr[11:7];
        rs1    = instr[19:15];
        rs2    = instr[24:20];
      end
      BRANCH_OPCODE: begin
        funct3 = instr[14:12];
        imm20  = {8'h00, instr[31], instr[7], instr[30:25], instr[11:8]};
        rs1    = instr[19:15];
        rs2    = instr[24:20];
      end
      JUMP_OPCODE: begin
        rd     = instr[11:7];
        imm20  = {instr[31], instr[19:12], instr[20], instr[30:21]};
      end
      JUMP_IND_OPCODE: begin
        rd     = instr[11:7];
        funct3 = instr[14:12];
        rs1    = instr[19:15];
        imm20  = {8'h00, instr[31:20]};
      end
      LUI_OPCODE: begin
        rd     = instr[11:7];
        imm20  = instr[31:12];
      end
      AUIPC_OPCODE: begin
        rd     = instr[11:7];
        imm20  = instr[31:12];
      end
      default: begin
        rd     = 0;
        rs1    = 0;
        rs2    = 0;
        funct3 = 0;
        funct7 = 0;
        imm20  = 0;
      end
    endcase
  end
endmodule

module extender(
  input [19:0] in,
  input [1:0] cmd,
  
  output reg [31:0] in_ext
);
  always_comb begin
    case (cmd)
      2'b00: in_ext = {{20{in[11]}}, in[11:0]};
      2'b01: in_ext = in << 12;
      2'b10: in_ext = {{11{in[19]}}, in, 1'b0}; 
      default: in_ext = 32'h0;
    endcase
  end
endmodule

module data_masker_extender(
  input [31:0] in,
  input [2:0] cmd,

  output reg [31:0] out
);
  always_comb begin
    case(cmd)
      3'b000: out = in; // no masking
      3'b001: out = {{24'h000000, in[7:0]}}; // mask to last 8 bits
      3'b010: out = {{16'h0000, in[15:0]}}; // mask to last 16 bits
      3'b011: out = in | {{24{in[7]}}, {8{1'b0}}}; // mask and sign extend last 8 bits
      3'b100: out = in | {{16{in[15]}}, {16{1'b0}}}; // mask and sign extend last 16 bits
      default: out = in;
    endcase
  end
endmodule

/* verilator lint_off UNOPTFLAT */
module alu(
  input [31:0] a,
  input [31:0] b,
  input [2:0] cmd,
  
  output [31:0] c,
  output ab_eq,
  output c_sign // 1 for neg, 0 for pos
);
  bit [32:0] c_ext;
  
  always_comb begin
    case (cmd)
      3'b000: c_ext = a + b; // add
      3'b001: c_ext = a - b; // sub
      3'b010: c_ext = {{1'b0, a & b}}; // bitwise and
      3'b011: c_ext = {{1'b0, a | b}}; // bitwise or
      3'b100: c_ext = {{1'b0, a ^ c}}; // bitwise xor
      3'b101: c_ext = {{1'b0, a << b[4:0]}}; // logical shift left
      3'b110: c_ext = b[10] ? {{1'b0, a >>> b[4:0]}} : {{1'b0, a >> b[4:0]}}; // arithmatic/logical shift right
      default: c_ext = 33'h00000000;
    endcase
  end
  
  assign c = c_ext[31:0];
  assign c_sign = c_ext[32];
  assign ab_eq = a == b;
endmodule
/* verilator lint_on UNOPTFLAT */