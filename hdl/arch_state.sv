module register_file(
  input clk,
  input rstn,
  input en,
  input wen,
  
  input [4:0] r_addr_a,
  input [4:0] r_addr_b,
  input [4:0] w_addr,
  input [31:0] w_data,
  
  output reg [31:0] r_data_a,
  output reg [31:0] r_data_b
);
  bit [31:0] x [0:31];
  
  always @(posedge clk) begin
    if (~rstn) begin
      for (int i = 0; i < 32; i++) x[i] = 32'h00;
    end
    else if (~en) begin
      r_data_a <= 32'h00;
      r_data_b <= 32'h00;
    end
    else begin
      r_data_a <= r_addr_a == 5'h00 ? 32'h00 : x[r_addr_a];
      r_data_b <= r_addr_b == 5'h00 ? 32'h00 : x[r_addr_b];
    end
  end
  
  always @(posedge clk) begin
    if (wen) x[w_addr] <= w_addr == 5'h00 ? 32'h00 : w_data;
  end
  
endmodule

module program_counter(
  input clk,
  input rstn,
  input en,
  
  input [31:0] next_cnt,
  output bit [31:0] cnt
);
  always @(posedge clk) begin
    if (~rstn) begin
      cnt = 32'h0;
    end
    else if (en) begin
      cnt = next_cnt;
    end
  end
endmodule

module instruction_memory #(
  parameter DEPTH = 512
) (
  input clk,
  input rstn,
  input en,
  input wen,
  
  input [31:0] addr,
  input [31:0] data_i,
  
  output [31:0] data_o
);
  bit [7:0] mem [0:DEPTH-1];
  bit [31:0] read_data;
  
  always @(posedge clk) begin
    if (~rstn) begin
      for (int i = 0; i < DEPTH; i++) mem[i] <= 8'h00;
    end
    else if (en) begin
      read_data <= {
        mem[addr[$clog2(DEPTH)-1:0]], 
        mem[addr[$clog2(DEPTH)-1:0]+1], 
        mem[addr[$clog2(DEPTH)-1:0]+2], 
        mem[addr[$clog2(DEPTH)-1:0]+3]
      };
    end
    else if (wen) begin
      mem[addr[$clog2(DEPTH)-1:0]] <= data_i[31:24];
      mem[addr[$clog2(DEPTH)-1:0]+1] <= data_i[23:16];
      mem[addr[$clog2(DEPTH)-1:0]+2] <= data_i[15:8];
      mem[addr[$clog2(DEPTH)-1:0]+3] <= data_i[7:0];
    end
  end
  
  assign data_o = read_data;
endmodule

module data_memory #(
  parameter DEPTH = 512
) (
  input clk,
  input rstn,
  input en,
  input wen,
  
  input [31:0] addr,
  input [31:0] data_i,
  
  output reg [31:0] data_o
);
  bit [7:0] mem [0:DEPTH-1];
  
  always @(posedge clk) begin
    if (~rstn) begin
      for (int i = 0; i < DEPTH; i++) mem[i] <= 8'h00;
    end
    else if (en) begin
      data_o <= {
        mem[addr[$clog2(DEPTH)-1:0]], 
        mem[addr[$clog2(DEPTH)-1:0]+1], 
        mem[addr[$clog2(DEPTH)-1:0]+2], 
        mem[addr[$clog2(DEPTH)-1:0]+3]
      };
    end
  end
  
  always @(posedge clk) begin
    if (wen) begin
      mem[addr[$clog2(DEPTH)-1:0]] <= data_i[31:24];
      mem[addr[$clog2(DEPTH)-1:0]+1] <= data_i[23:16];
      mem[addr[$clog2(DEPTH)-1:0]+2] <= data_i[15:8];
      mem[addr[$clog2(DEPTH)-1:0]+3] <= data_i[7:0];
    end
  end
endmodule