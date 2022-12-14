`default_nettype none
`timescale 1ns / 1ps

module reverse_bit_order(
    input wire clk,
    input wire rst,
    input wire [7:0] pixel,
    input wire [7:0] audio,
    input wire stall,

    output logic axiov,
    output logic [1:0] axiod,
    output logic [23:0] pixel_addr //made 24-bits rather than 17-bits to send 3 full bytes
);

logic [1:0] state;

logic [5:0] addr_bit_counter;
logic [3:0] byte_bit_counter;

logic [11:0] pixel_counter;
logic [8:0] audio_counter;

typedef enum {SendAddress, SendPixel, SendAudio} States;

//try combinational output
always_comb begin
    if (rst) begin
        axiod = 0;
    end else begin
        case (state)
            SendAddress: begin
                if (byte_bit_counter < 8) begin
                    // counts through addr length and outputs bits of addr one at a time in MSB, LSb order
                    if (addr_bit_counter < 4) begin //0, 2, 4, 6
                        axiod = {pixel_addr[17 + byte_bit_counter], pixel_addr[16 + byte_bit_counter]};
                    end else if (addr_bit_counter < 8) begin //8, 10, 12, 14
                        axiod = {pixel_addr[9 + byte_bit_counter], pixel_addr[8 + byte_bit_counter]};
                    end else if (addr_bit_counter < 12) begin // 16, 18, 20, 22
                        axiod = {pixel_addr[1 + byte_bit_counter], pixel_addr[byte_bit_counter]};
                    end else begin
                        axiod = 0;
                    end 
                    // axiod = 2'b11;
                end else axiod = 0;
            end

            SendPixel: begin
                axiod = {pixel[1 + byte_bit_counter], pixel[byte_bit_counter]};
            end

            SendAudio: begin
                axiod = {audio[1 + byte_bit_counter], audio[byte_bit_counter]};
            end
            default: axiod = 0;
        endcase
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        pixel_addr <= 0;
        state <= SendAddress;
        axiov <= 0;
        addr_bit_counter <= 0;
        byte_bit_counter <= 8; //for timing, will reset to 0 upon returning to send address
        pixel_counter <= 0;
        audio_counter <= 0;

    end else if (!stall) begin
        case(state)
        SendAddress: begin
            axiov <= 1;
            // counts through addr length and outputs bits of addr one at a time in MSB, LSb order
            // if (addr_bit_counter < 4) begin //0, 2, 4, 6
            //     axiod <= {pixel_addr[4 + byte_bit_counter], pixel_addr[16 + byte_bit_counter]};
            // end else if (addr_bit_counter < 8) begin //8, 10, 12, 14
            //     axiod <= {pixel_addr[9 + byte_bit_counter], pixel_addr[8 + byte_bit_counter]};
            // end else if (addr_bit_counter < 12) begin // 16, 18, 20, 22
            //     axiod <= {pixel_addr[1 + byte_bit_counter], pixel_addr[byte_bit_counter]};
            // end

            // cycles the byte counter every 8 bits
            if (byte_bit_counter >= 6 || addr_bit_counter >= 12) byte_bit_counter <= 0;
            else byte_bit_counter <= byte_bit_counter + 2;

            if (byte_bit_counter < 8) begin
                if (addr_bit_counter < 11) addr_bit_counter <= addr_bit_counter + 1;
                else begin
                    addr_bit_counter <= 0;
                    state <= SendPixel;
                    byte_bit_counter <= 0;
                end
            end
        end
        SendPixel: begin
            axiov <= 1;
            //switch to next pixel 2 cycles early to give BRAM time to change
            if (byte_bit_counter == 4) begin 
                if (pixel_addr < 76800) pixel_addr <= pixel_addr + 1;
                else pixel_addr <= 0;
            end

            // cycles the byte counter every 8 bits
            if (byte_bit_counter >= 6) byte_bit_counter <= 0;
            else byte_bit_counter <= byte_bit_counter + 2;

            //once 320 pixels sent, switch to sending Audio
            if (pixel_counter < 320 * 4 -1) pixel_counter <= pixel_counter + 1;
            else begin
                pixel_counter <= 0;
                addr_bit_counter <= 0;
                state <= SendAudio;
            end
        end
        // audio doesn't really "exist" rn, i am assuming we are cropping 12-bit -> 8-bit bytes >:)
        SendAudio: begin
            axiov <= 1;
            // QUESTION: How are we pumping audio into this module? 
            if (byte_bit_counter >= 6) byte_bit_counter <= 0;
            else byte_bit_counter <= byte_bit_counter + 2;

        end
        endcase
    end else if (stall) begin //same as everything in rst, except for reseting the pixel_addr
        state <= SendAddress;
        axiov <= 0;
        addr_bit_counter <= 0;
        byte_bit_counter <= 8; 
        pixel_counter <= 0;
        audio_counter <= 0;
    end
end

endmodule

`default_nettype wire