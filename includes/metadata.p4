/* Zhao Zongyi, xinshengzzy@foxmail.com */
/* #include "tofino/stateful_alu_blackbox.p4" */
/* #include "tofino/pktgen_headers.p4" */
/* #include <tofino/constants.p4> */
/* #include <tofino/intrinsic_metadata.p4> */

/* #include "includes/headers.p4" */
/* #include "includes/parser.p4" */
/* #include "includes/macro.p4" */


/*---------- metadata for measurement program ----------*/
header_type measurement_meta_t {
    fields {
    digest: 16; // digest for differentiating in ancillary table;
      /*---------- promotion information ----------*/
    promotion: 1;
    promotion_table_idx: 8;
    min_cnt_table_idx: 8;
    min_status_table_idx: 8;
      /*---------- counts and status of M and A tables ----------*/
    M1_cnt: 16;
    M2_cnt: 16;
    M3_cnt: 16;
    min_cnt: 16;
    M1_status: 16;
    M2_status: 16;
    M3_status: 16;
    min_status: 16;
    A_cnt: 16;
    A_status: 16;
      /*---------- compare the counts and status ----------*/
    delta_cnt_M1_M2: 16; // M1_cnt - M2_cnt
    delta_cnt_M1_M3: 16; // M1_cnt - M3_cnt
    delta_cnt_M2_M3: 16; // M2_cnt - M3_cnt
    delta_cnt_min_A: 16;
    delta_cnt_A_2: 16;
    delta_status_M1_M2: 16; // M1_status - M2_status
    delta_status_M1_M3: 16; // M1_status - M3_status
    delta_status_M2_M3: 16; // M2_status - M3_status
    delta_status_min_A: 16;
      /*---------- matching status in M ----------*/
    M1_srcip_pred: 4;
    M1_dstip_pred: 4;
    M1_proto_pred: 4;
    M2_srcip_pred: 4;
    M2_dstip_pred: 4;
    M2_proto_pred: 4;
    M3_srcip_pred: 4;
    M3_dstip_pred: 4;
    M3_proto_pred: 4;
    M1_match: 1;
    M2_match: 1;
    M3_match: 1;
      /*---------- evicted flow record ----------*/
    tmp_srcip: 32;
    tmp_dstip: 32;
    tmp_proto: 8;
    tmp_count: 16;
      /*---------- test ----------*/
    test: 16;
    export_flag: 1;
    }
}

metadata measurement_meta_t m_meta;

