`include "core.sv"

module single_cycle_r32i_tb;
  bit clk = 0;
  bit en = 1;
  bit prog = 1;
  bit [31:0] addr = 32'h00000000;
  bit [31:0] instr = 32'h55555555;
  
  bit [31:0] instrs[$] = {
    // lui test
    {{20'hfffff, 5'b00101, 7'b0110111}},

    // auipc test
    {{20'hffff4, 5'b00101, 7'b0010111}},
    
    // jal test
    {{20'h00400, 5'b00101, 7'b1101111}},

    // jalr test
    {{12'h004, 5'b00101, 3'b000, 5'b00111, 7'b1100111}},

    // beq test
    {{7'b0000000, 5'b01000, 5'b01001, 3'b000, 5'b00100, 7'b1100011}},

    // bne test
    {{7'b0000000, 5'b01000, 5'b01001, 3'b001, 5'b01000, 7'b1100011}},

    // blt/bltu test (contd.)
    {{7'b0000000, 5'b00101, 5'b00000, 3'b100, 5'b00100, 7'b1100011}},

    // bge/bgeu test (contd.)
    {{7'b0000000, 5'b00000, 5'b00101, 3'b101, 5'b00100, 7'b1100011}},

    // sb test
    {{7'b0000000, 5'b00101, 5'b00101, 3'b000, 5'b00100, 7'b0100011}},

    // sh test
    {{7'b0000000, 5'b00101, 5'b00101, 3'b001, 5'b01000, 7'b0100011}},

    // sw test
    {{7'b0000000, 5'b00101, 5'b00101, 3'b010, 5'b01100, 7'b0100011}},

    // lb test
    {{12'h004, 5'b00101, 3'b000, 5'b00111, 7'b0000011}},
    
    // lh test
    {{12'h008, 5'b00101, 3'b001, 5'b00111, 7'b0000011}},

    // lw test
    {{12'h00c, 5'b00101, 3'b010, 5'b00111, 7'b0000011}},

    // lbu test
    {{12'h004, 5'b00101, 3'b100, 5'b00111, 7'b0000011}},
    
    // lhu test
    {{12'h008, 5'b00101, 3'b101, 5'b00111, 7'b0000011}},

    // addi test
    {{12'h040, 5'b00101, 3'b000, 5'b00101, 7'b0010011}},

    // slti test
    {{12'h040, 5'b00101, 3'b010, 5'b00101, 7'b0010011}},

    // sltiu test
    {{12'h040, 5'b00101, 3'b011, 5'b00101, 7'b0010011}},

    // xori test (will ruin sim)
    // {{12'hfff, 5'b00101, 3'b100, 5'b00101, 7'b0010011}},

    // andi test
    {{12'h000, 5'b00101, 3'b111, 5'b00101, 7'b0010011}},

    // ori test
    {{12'hfff, 5'b00101, 3'b110, 5'b00101, 7'b0010011}},

    // srli test
    {{12'h004, 5'b00101, 3'b101, 5'b00101, 7'b0010011}},

    // slli test
    {{12'h004, 5'b00101, 3'b001, 5'b00101, 7'b0010011}},

    // srai test (not passed)
    {{12'h404, 5'b00101, 3'b101, 5'b00101, 7'b0010011}},

    // sub test
    {{7'b0100000, 5'b00101, 5'b00101, 3'b000, 5'b00101, 7'b0110011}},

    // add test
    {{7'b0000000, 5'b00111, 5'b00101, 3'b000, 5'b00101, 7'b0110011}},

    // sll test
    {{7'b0000000, 5'b00111, 5'b00101, 3'b001, 5'b00101, 7'b0110011}},

    // srl test
    {{7'b0000000, 5'b00111, 5'b00101, 3'b101, 5'b00101, 7'b0110011}},

    // sra test (not passing)
    // {{7'b0100000, 5'b00111, 5'b00101, 3'b101, 5'b00101, 7'b0110011}},

    // slt test
    {{7'b0000000, 5'b00111, 5'b00101, 3'b010, 5'b00101, 7'b0110011}},

    // sltu test
    {{7'b0000000, 5'b00111, 5'b00101, 3'b011, 5'b00101, 7'b0110011}},

    // xor test
    // {{7'b0100000, 5'b00111, 5'b00101, 3'b100, 5'b00101, 7'b0110011}}

    // and test
    {{7'b0000000, 5'b00111, 5'b00101, 3'b111, 5'b00101, 7'b0110011}},

    // or test
    {{7'b0000000, 5'b00111, 5'b00101, 3'b110, 5'b00101, 7'b0110011}}


    // 0000000 rs2 rs1 000 rd 0110011 ADD
    // 0100000 rs2 rs1 000 rd 0110011 SUB
    // 0000000 rs2 rs1 001 rd 0110011 SLL
    // 0000000 rs2 rs1 010 rd 0110011 SLT
    // 0000000 rs2 rs1 011 rd 0110011 SLTU
    // 0000000 rs2 rs1 100 rd 0110011 XOR
    // 0000000 rs2 rs1 101 rd 0110011 SRL
    // 0100000 rs2 rs1 101 rd 0110011 SRA
    // 0000000 rs2 rs1 110 rd 0110011 OR
    // 0000000 rs2 rs1 111 rd 0110011 AND

    // load 32 bit integer to x9
    // {{20'h77777, 5'b01001, 7'b0110111}},
    // {{12'h777, 5'b01001, 3'b000, 5'b01001, 7'b0010011}},
    
    // load x1 with 0x4
    // {{12'h004, 5'b00000, 3'b000, 5'b00001, 7'b0010011}}, 
    
    // load x2 with 0xf
    // {{12'h00F, 5'b00000, 3'b000, 5'b00010, 7'b0010011}},
    
    // load x4 with 0x7
    // {{12'h007, 5'b00000, 3'b000, 5'b00100, 7'b0010011}},
    
    // store contents of x1 to 0xf
    // {{7'h00, 5'b00001, 5'b00010, 3'b010, 5'b00000, 7'b0100011}},
    
    // load contents of 0xf to x3
    // {{12'h000, 5'b00010, 3'b010, 5'b00011, 7'b0000011}},
    
    // add x3 with 0x3
    // {{12'h003, 5'b00011, 3'b000, 5'b00011, 7'b0010011}},
    
    // load x5 with x3 + x4
    // {{7'h003, 5'b00100, 5'b00011, 3'b000, 5'b00101, 7'b0110011}},
    
    // // jump 12 address ahead
    // {{20'b00000000110000000000, 5'b00111, 7'b1101111}},
    
    // // jump 4 address back if x3 is equal to x4
    // {{7'hff, 5'b00100, 5'b00011, 3'b000, 5'b11101, 7'b1100011}},
    
    // // jump 8 address back if x3 is not equal to x4
    // {{7'hff, 5'b00100, 5'b00011, 3'b001, 5'b11001, 7'b1100011}},
    
    // add x3 with 0x3
    // {{12'h000, 5'b00111, 3'b000, 5'b00000, 7'b1100111}},
    
    // load x10 with PC + 1
    // {{20'h00001, 5'b01010, 7'b0010111}}
  };
  
  single_cycle_r32i dut(
    .clk(clk),
    .en(en),
    .prog(prog),
    .addr(addr),
    .instr(instr)
  );
  
  initial forever begin
    for (int i = 0; i < instrs.size; i++) begin
      instr = instrs[i];
      
      @(negedge clk);
      
      addr = addr + 4;
    end
    prog = 0;
  end
  
  // clock generator
  initial forever #5 clk = ~clk;
  
  // maximum simulation duration
  initial #1500 $finish;
  
  // dump waveform
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
endmodule