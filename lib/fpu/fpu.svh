`ifndef __FPU__
`define __FPU__

package fpu;

    typedef logic [31:0] fpu_float_t;
    typedef logic        fpu_float_sign_t;
    typedef logic [7:0]  fpu_float_exponent_t;
    typedef logic [22:0] fpu_float_mantissa_t;
    typedef logic [22:0] fpu_float_mantissa_complete_t;

    typedef logic [63:0] fpu_double_t;
    typedef logic        fpu_double_sign_t;
    typedef logic [10:0] fpu_double_exponent_t;
    typedef logic [51:0] fpu_double_mantissa_t;
    typedef logic [52:0] fpu_double_mantissa_complete_t;

    parameter fpu_float_t FPU_FLOAT_ZERO    = 32'h0000_0000;
    parameter fpu_float_t FPU_FLOAT_NAN     = 32'hFFFF_FFFF;
    parameter fpu_float_t FPU_FLOAT_POS_INF = 32'h7F80_0000;
    parameter fpu_float_t FPU_FLOAT_NEG_INF = 32'hFF80_0000;

    // typedef struct packed {
    //     fpu_instr_t instr_info;
    //     logic add_en, mult_en, div_en, sqrt_en, encoder_en, decoder_en;
    //     logic rd_we;
    //     logic round_en;
    //     logic invert_sign;
    //     logic compare;
    //     logic max;
    //     logic int_signed;
    //     logic move;
    // }

    typedef struct packed {
        fpu_float_sign_t sign;
        fpu_float_exponent_t exponent;
        fpu_float_mantissa_t mantissa;
    } fpu_float_fields_t;

    typedef struct packed {
        fpu_double_sign_t sign;
        fpu_double_exponent_t exponent;
        fpu_double_mantissa_t mantissa;
    } fpu_double_fields_t;

    typedef struct packed {
        logic inf;
        logic nan;
        logic norm;
        logic zero;
    } fpu_float_conditions_t;

    typedef struct packed {
        logic [1:0] guard;
        logic       sticky;
    } fpu_guard_bits_t;

    typedef enum logic [1:0] {
        FPU_ROUND_MODE_EVEN = 2'd0,
        FPU_ROUND_MODE_DOWN = 2'd1,
        FPU_ROUND_MODE_UP = 2'd2,
        FPU_ROUND_MODE_ZERO = 2'd3
    } fpu_round_mode_t;

    typedef struct packed {
        logic sign;
        logic nan, inf, zero;
        logic [2:0] guard;
        logic [7:0] exponent;
        logic [23:0] mantissa;
        logic valid;
        fpu_round_mode_t mode;
    } fpu_result_t;

    typedef struct packed {
        fpu_float_mantissa_t mantissa;
        fpu_guard_bits_t guard;
    } fpu_float_mantissa_result_t;

    typedef struct packed {
        fpu_double_mantissa_t mantissa;
        fpu_guard_bits_t guard;
    } fpu_double_mantissa_result_t;

    function automatic fpu_float_fields_t fpu_decode_float(
        input fpu_float_t raw
    );
        return '{
            sign: raw[31], 
            exponent: raw[30:23], 
            mantissa: raw[22:0]
        };
    endfunction

    function automatic fpu_float_t fpu_encode_float(
        input fpu_float_fields_t decoded
    );
        return {decoded.sign, decoded.exponent, decoded.mantissa};
    endfunction

    function automatic fpu_double_fields_t fpu_decode_double(
        input fpu_float_t raw
    );
        return '{
            sign: raw[63], 
            exponent: raw[62:52], 
            mantissa: raw[51:0]
        };
    endfunction

    function automatic fpu_double_t fpu_encode_double(
        input fpu_double_fields_t decoded
    );
        return {decoded.sign, decoded.exponent, decoded.mantissa};
    endfunction

    function automatic fpu_float_mantissa_complete_t fpu_float_get_mantissa(
        input fpu_float_fields_t fields
    );
        logic denormalized = (fields.exponent == 8'h00);
        return {~denormalized, fields.mantissa};
    endfunction

    function automatic fpu_float_conditions_t fpu_get_conditions(
        input fpu_float_fields_t a
    );
        return '{
            zero: (a.exponent == 0 && a.mantissa == 0),
            norm: (a.exponent != 0),
            nan: (a == FPU_FLOAT_NAN),
            inf: (a == FPU_FLOAT_POS_INF || a == FPU_FLOAT_NEG_INF)
        };
    endfunction

endpackage

`endif
