module hex_7_segment(
  input  logic clk,
  input  logic rst,
  input  logic [31:0] binary_in,
  output logic [6:0] seg [3:0]  // 4 digits, each 7 segments
);
  // Extract the lower 16 bits (4 hex digits)
  logic [15:0] hex_value;
  logic [3:0] hex_digit [3:0];

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      hex_value <= 16'h0000;
    end else begin
      hex_value <= binary_in[15:0];
    end
  end

  // Break into 4 hex digits
  always_comb begin
    hex_digit[0] = hex_value[3:0];
    hex_digit[1] = hex_value[7:4];
    hex_digit[2] = hex_value[11:8];
    hex_digit[3] = hex_value[15:12];
  end

  // Hex to 7-segment decoder (common cathode)
  function logic [6:0] hex_to_7seg(input logic [3:0] hex);
    case (hex)
      4'h0: hex_to_7seg = 7'b100_0000;
      4'h1: hex_to_7seg = 7'b111_1001;
      4'h2: hex_to_7seg = 7'b010_0100;
      4'h3: hex_to_7seg = 7'b011_0000;
      4'h4: hex_to_7seg = 7'b001_1001;
      4'h5: hex_to_7seg = 7'b001_0010;
      4'h6: hex_to_7seg = 7'b000_0010;
      4'h7: hex_to_7seg = 7'b111_1000;
      4'h8: hex_to_7seg = 7'b000_0000;
      4'h9: hex_to_7seg = 7'b001_0000;
      4'hA: hex_to_7seg = 7'b000_1000;
      4'hB: hex_to_7seg = 7'b000_0011;
      4'hC: hex_to_7seg = 7'b100_0110;
      4'hD: hex_to_7seg = 7'b010_0001;
      4'hE: hex_to_7seg = 7'b000_0110;
      4'hF: hex_to_7seg = 7'b000_1110;
      default: hex_to_7seg = 7'b111_1111; // blank
    endcase
  endfunction

  // Apply decoder to all 4 digits
  always_comb begin
    for (int i = 0; i < 4; i++) begin
      seg[i] = hex_to_7seg(hex_digit[i]);
    end
  end

endmodule
