`default_nettype none

module vga_mux (
    input wire ethclk_in,
    output wire [7:0] pixel_for_bram,
    output wire [16:0] pixel_addr_for_bram,
    output wire pixel_for_bram_valid
);

    logic [10:0] hcount = 0;
    logic [9:0] vcount = 0;
    logic [1:0] counter = 0;
    logic [1:0] line_counter = 2'b00;

    //color params
    localparam YELLOW = 6'b11000000; // 11 is MSBs indicates that it is written on
    localparam PINK = 8'b11000001;
    localparam GREEN = 8'b11000010;
    localparam RED = 8'b11000011;

    always_ff @(ethclk_in ) begin
        if (counter < 3) begin 
            counter <= counter + 1;
            pixel_for_bram_valid <= 0;
        end else begin
            counter <= 0;
            pixel_addr_for_bram <= (vcount*320) + hcount;
            pixel_for_bram <= {6'b110000, line_counter};
            pixel_for_bram_valid <= 1;
            if (hcount == 0) begin
                if (line_counter == 3) line_counter <= 0;
                else line_counter <= line_counter + 1;
            end
            if (hcount < 320) hcount <= hcount + 1;
            else hcount <= 0;

            if (vcount < 240) vcount <= vcount + 1;
            else vcount <= 0;
                
            end
        end

    end


endmodule

`default_nettype wire
