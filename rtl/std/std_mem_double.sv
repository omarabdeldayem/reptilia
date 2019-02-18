`timescale 1ns/1ps

`include "../../lib/std/std_util.svh"
`include "../../lib/std/std_mem.svh"

/*
 * Implements a single cycle memory with two input streams for commands and two
 * output streams for the results of those commands. Adding a single register 
 * stage immediately after this will allow for the block memory output 
 * register to be used.
 */
module std_mem_double #(
    parameter MANUAL_ADDR_WIDTH = 0 // Set other than zero to override
)(
    input logic clk, rst,
    std_mem_intf.in command0, command1, // Inbound Commands
    std_mem_intf.out result0, result1 // Outbound Results
);

    `STATIC_MATCH_MEM(command0, result0)
    `STATIC_MATCH_MEM(command0, command1)
    `STATIC_MATCH_MEM(command0, result1)

    localparam DATA_WIDTH = $bits(command0.data);
    localparam ADDR_WIDTH = (MANUAL_ADDR_WIDTH == 0) ? $bits(command0.addr) : MANUAL_ADDR_WIDTH;
    localparam MASK_WIDTH = DATA_WIDTH / 8;
    localparam DATA_LENGTH = 2**ADDR_WIDTH;

    /*
     * Custom flow control is used here since the block RAM cannot be written
     * to without changing the read value.
     */
    logic enable0, enable1;

    std_block_ram_double #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) std_block_ram_double_inst (
        .clk, .rst,
        // Avoid writing to memory values during reset, since they are not reset
        .enable0(!rst && enable0),
        .write_enable0(command0.write_enable),
        .addr_in0(command0.addr),
        .data_in0(command0.data),
        .data_out0(result0.data),

        // Avoid writing to memory values during reset, since they are not reset
        .enable1(!rst && enable1),
        .write_enable1(command1.write_enable),
        .addr_in1(command1.addr),
        .data_in1(command1.data),
        .data_out1(result1.data)
    );

    always_ff @ (posedge clk) begin
        if (rst) begin
            result0.valid <= 'b0;
            result1.valid <= 'b0;
        end else begin
            if (enable0) begin
                result0.valid <= command0.read_enable;
            end else if (result0.ready) begin
                result0.valid <= 'b0;
            end

            if (enable1) begin
                result1.valid <= command1.read_enable;
            end else if (result1.ready) begin
                result1.valid <= 'b0;
            end
        end
    end

    always_comb begin
        command0.ready = result0.ready || !result0.valid;
        enable0 = command0.valid && command0.ready;

        command1.ready = result1.ready || !result1.valid;
        enable1 = command1.valid && command1.ready;
    end

endmodule
