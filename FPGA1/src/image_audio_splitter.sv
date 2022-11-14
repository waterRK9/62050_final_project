`default_nettype none
`timescale 1ns / 1ps

module image_audio_splitter(
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [1:0] axiid,

    output logic addr_axiov,
    output logic pixel_axiov,
    output logic audio_axiov,

    output logic [23:0] addr,
    output logic [7:0] pixel,
    output logic [7:0] audio
);

typedef enum {Idle, RecieveAddr, RecievePixels, RecieveAudio} States;

logic [8:0] output_counter; //going to 320 at the max

logic [1:0] state;
logic [2:0] byte_bit_counter;

always_ff @(posedge clk) begin
    if (rst) begin
        state <= RecieveAddr;
        output_counter <= 0;
        byte_bit_counter <= 0;
        addr <= 0;
        pixel <= 0;
        audio <= 0;
        addr_axiov <= 0;
        pixel_axiov <= 0;
        audio_axiov <= 0;

    end else if (axiiv) begin
        if (byte_bit_counter == 6) byte_bit_counter <= 0;
        else byte_bit_counter <= byte_bit_counter + 2;

        case(state)
        RecieveAddr: begin
            if (output_counter <= 6) begin //0, 2, 4, 6
                addr[17+byte_bit_counter] <= axiid[1];
                addr[16+byte_bit_counter] <= axiid[0];
            end else if (output_counter <= 14) begin //8, 10, 12, 14
                addr[9+byte_bit_counter] <= axiid[1];
                addr[8+byte_bit_counter] <= axiid[0];  
            end else if (output_counter <= 22) begin // 16, 18, 20, 22
                addr[1+byte_bit_counter] <= axiid[1];
                addr[byte_bit_counter] <= axiid[0];
            end 

            if (output_counter < 22) output_counter <= output_counter + 2;
            else begin
                addr_axiov <= 1; //raise high for one cycle

                output_counter <= 0;
                state <= RecievePixels;
            end
        end
        RecievePixels: begin
            //TODO: add output counting here for 320 pixels
            addr_axiov <= 0;
            if (byte_bit_counter == 6) pixel_axiov <= 1;
            else pixel_axiov <= 0;

            pixel <= {axiid, pixel[7:2]};
        end
        RecieveAudio: begin
            //TODO: add output counting for audio? will i ever violate expected packet size?
            addr_axiov <= 0;
            pixel_axiov <= 0;

            if (byte_bit_counter == 6) audio_axiov <= 1;
            else audio_axiov <= 0;

            audio <= {axiid, audio[7:2]};
        end
        endcase
    end else begin
        state <= RecieveAddr;
        output_counter <= 0;
        byte_bit_counter <= 0;
    end
end

endmodule

`default_nettype wire