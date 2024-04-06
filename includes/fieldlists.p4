/* Zhao Zongyi, xinshengzzy@foxmail.com */
/* #include "tofino/stateful_alu_blackbox.p4" */
/* #include "tofino/pktgen_headers.p4" */
/* #include <tofino/constants.p4> */
/* #include <tofino/intrinsic_metadata.p4> */

/* #include "headers.p4" */
/* #include "parser.p4" */
#include "macro.p4"

field_list flow {
    ipv4.srcip;
    ipv4.dstip;
    ipv4.proto;
}

/*---------- hash function for table M1 ----------*/
field_list_calculation hash_1 {
    input {
        flow;
    }
    algorithm: crc32;
    output_width: M1_IDX_WIDTH;
}

/*---------- hash function for table M2 ----------*/
field_list_calculation hash_2 {
    input {
        flow;
    }
    algorithm: crc32_extend;
    output_width: M2_IDX_WIDTH;
}

/*---------- hash function for table M3 ----------*/
field_list_calculation hash_3 {
    input {
        flow;
    }
    algorithm: crc32_lsb;
    output_width: M3_IDX_WIDTH;
}

/*---------- hash function for table A ----------*/
field_list_calculation hash_4 {
    input {
        flow;
    }
    algorithm: crc32_msb;
    output_width: A_IDX_WIDTH;
}

/*---------- hash function for digest generation ----------*/
field_list_calculation digest_hash {
    input {
        flow;
    }
    algorithm: identity;
    output_width: DIGEST_WIDTH;
}
