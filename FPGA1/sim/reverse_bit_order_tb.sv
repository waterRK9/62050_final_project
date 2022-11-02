`default_nettype none

module reverse_bit_order_tb;

    logic clk;
    logic rst;
    logic [7:0] pixel;
    logic stall;

    logic axiov;
    logic [1:0] axiod;
    logic [23:0] pixel_addr;

    reverse_bit_order reverse_bit_order (
    .clk(clk),
    .rst(rst),
    .pixel(pixel),
    .stall(stall),
    .axiov(axiov), 
    .axiod(axiod),
    .pixel_addr(pixel_addr)
    );

    always begin
    #10;
    clk = !clk;
    end

    initial begin
        $dumpfile("obj/reverse_bit_order.vcd");
        $dumpvars(0, reverse_bit_order_tb);
        $display("Starting Sim");
        clk = 0;
        rst = 0;
        #20;
        rst = 1;
        #20;
        rst = 0;
        #10
        
        //Test 1: sending one pixel
        // how in the world am I going to account for the 2 cycle BRAM lag? let's ignore it for a second
        stall = 0;
        for (int i = 0; i < 20; i = i + 1) begin
            if (pixel_addr == 0) pixel = 8'b10101010;
            else if (pixel_addr == 1) pixel = 8'b01010101;
            #20;
        end
        stall = 1;
        #20;

        clk = 0;
        rst = 0;
        #20;
        rst = 1;
        #20;
        rst = 0;

        #40;
        $display("Finishing Sim");
        $finish;
    end

endmodule

`timescale 1ns / 1ps
`default_nettype wire