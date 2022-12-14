`default_nettype none
`timescale 1ns / 1ps

module frame_packager(
    input wire clk,
    input wire rst,
    input wire addr_axiiv,
    input wire [23:0] addr_axiid,
    input wire pixel_axiiv,
    input wire [7:0] pixel_axiid,

    output logic axiov, //for wea on BRAM
    output logic [16:0] addr_axiod,
    output logic [7:0] pixel_axiod
);

// note: might add an always comb block and do everything but the count up combinationally
logic firstBit;

always_ff @(posedge clk) begin
    if (rst) begin
        axiov <= 0;
        addr_axiod <= 0;
        pixel_axiod <= 0;
        firstBit <= 1;
    end else begin
        if (addr_axiiv) begin
            addr_axiod <= addr_axiid[16:0]; //trunate from 24bit transmittion to 17bit BRAM address
            firstBit <= 1;
        end
        else if (addr_axiod >= 76800) addr_axiod <= 0;
        else if (pixel_axiiv && !firstBit) addr_axiod <= addr_axiod + 1;

        if (pixel_axiiv) begin
            pixel_axiod <= pixel_axiid;
            axiov <= 1'b1;
            firstBit <= 0;
        end else axiov <= 1'b0;
    end
end

endmodule

`default_nettype wire
