/* Zhao Zongyi, xinshengzzy@foxmail.com */
/* #include "tofino/stateful_alu_blackbox.p4" */
/* #include "tofino/pktgen_headers.p4" */
/* #include <tofino/constants.p4> */
/* #include <tofino/intrinsic_metadata.p4> */

/* #include "includes/headers.p4" */
/* #include "includes/parser.p4" */
/* #include "includes/macro.p4" */
#define CPU_PORT 192
#define RECIRC_SESS_ID 20
#define RECIRC_PORT 68

/*--------- nop ----------*/
action nop() {}

/*---------- count_bb ----------*/
blackbox stateful_alu count_bb {
 reg: count;
 /* update_lo_1_value: m_meta.tmp_srcip; */
 /* update_lo_1_value: ig_intr_md_for_tm.ucast_egress_port; */
 update_lo_1_value: sf.srcip;
}

/*---------- calc_digest_t ----------*/
action calc_digest_ac()
{
    modify_field_with_hash_based_offset(m_meta.digest, 0, digest_hash, 65536);
}

/* @pragma stage 0 */
table calc_digest_t
{
    actions {
        calc_digest_ac;
    }
 default_action: calc_digest_ac;
}

/*---------- forward_t ----------*/
action set_egr(egress_spec) {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_spec);
}

/* @pragma stage 0 */
table forward_t {
  reads {
  ig_intr_md.ingress_port: exact;
  }
  actions {
    set_egr; nop;
  }
}

/*---------- export_t ----------*/
action export_ac() {
  /* count_bb.execute_stateful_alu(0); */
  modify_field(ig_intr_md_for_tm.ucast_egress_port, CPU_PORT);
  modify_field(sf.srcip, m_meta.tmp_srcip);
  modify_field(sf.dstip, m_meta.tmp_dstip);
  modify_field(sf.proto, m_meta.tmp_proto);
  modify_field(sf.count, m_meta.tmp_count);
}

@pragma 4
table export_t {
  actions {
    export_ac;
  }
 default_action: export_ac;
}

/*---------- update_M1_srcip_t ----------*/
blackbox stateful_alu update_M1_srcip_bb
{
 reg: M1_srcip;
 condition_lo: register_lo == 0;
 condition_hi: register_lo == ipv4.srcip;

 update_lo_1_predicate: condition_lo or condition_hi;
 update_lo_1_value: ipv4.srcip;

 output_value: predicate;
 output_dst: m_meta.M1_srcip_pred;
}

action update_M1_srcip_ac()
{
    update_M1_srcip_bb.execute_stateful_alu_from_hash(hash_1);
}

blackbox stateful_alu rewrite_M1_srcip_bb
{
 reg: M1_srcip;
 update_lo_1_value: sf.srcip;
 output_value: register_lo;
 output_dst: m_meta.tmp_srcip;
}

action rewrite_M1_srcip_ac()
{
    rewrite_M1_srcip_bb.execute_stateful_alu_from_hash(hash_1);
}

/* @pragma stage 0 */
table update_M1_srcip_t
{
  reads {
  sf: valid;
  sf.table_idx: exact;
  }
  actions {
    update_M1_srcip_ac;
    rewrite_M1_srcip_ac;
    nop;
  }
 /* default_action: nop; */
 max_size: 2;
}

/*---------- update_M1_dstip_t ----------*/
blackbox stateful_alu update_M1_dstip_bb
{
 reg: M1_dstip;
 condition_lo: register_lo == 0;
 condition_hi: register_lo == ipv4.dstip;

 update_lo_1_predicate: condition_lo or condition_hi;
 update_lo_1_value: ipv4.dstip;

 output_value: predicate;
 output_dst: m_meta.M1_dstip_pred;
}

action update_M1_dstip_ac()
{
    update_M1_dstip_bb.execute_stateful_alu_from_hash(hash_1);
}

blackbox stateful_alu rewrite_M1_dstip_bb
{
 reg: M1_dstip;
 update_lo_1_value: sf.dstip;
 output_value: register_lo;
 output_dst: m_meta.tmp_dstip;
}

action rewrite_M1_dstip_ac()
{
    rewrite_M1_dstip_bb.execute_stateful_alu_from_hash(hash_1);
}

/* @pragma stage 0 */
table update_M1_dstip_t
{
  reads {
  sf: valid;
  sf.table_idx: exact;
  }
  actions {
    update_M1_dstip_ac;
    rewrite_M1_dstip_ac;
  }
 max_size: 2;
}

/*---------- update_M1_proto_t ----------*/
blackbox stateful_alu update_M1_proto_bb
{
 reg: M1_proto;
 condition_lo: register_lo == 0;
 condition_hi: register_lo == ipv4.proto;

 update_lo_1_predicate: condition_lo or condition_hi;
 update_lo_1_value: ipv4.proto;

 output_value: predicate;
 output_dst: m_meta.M1_proto_pred;
}

action update_M1_proto_ac()
{
    update_M1_proto_bb.execute_stateful_alu_from_hash(hash_1);
}

blackbox stateful_alu rewrite_M1_proto_bb
{
 reg: M1_proto;
 update_lo_1_value: sf.proto;
 /* update_lo_1_value: 199; */
 output_value: register_lo;
 output_dst: m_meta.tmp_proto;
}

action rewrite_M1_proto_ac()
{
    rewrite_M1_proto_bb.execute_stateful_alu_from_hash(hash_1);
}

/* @pragma stage 0 */
table update_M1_proto_t
{
  reads {
  sf: valid;
  sf.table_idx: exact;
  }
  actions {
    update_M1_proto_ac;
    rewrite_M1_proto_ac;
  }
 max_size: 2;
}

/*---------- update_M1_cnt_t ----------*/
blackbox stateful_alu increase_M1_cnt_bb
{
 reg: M1_cnt;
 update_lo_1_value: register_lo + 1;
}

action increase_M1_cnt_ac()
{
    increase_M1_cnt_bb.execute_stateful_alu_from_hash(hash_1);
    modify_field(m_meta.M1_match, 1);
}

blackbox stateful_alu read_M1_cnt_bb
{
 reg: M1_cnt;
 output_value: register_lo;
 output_dst: m_meta.M1_cnt;
}

action read_M1_cnt_ac()
{
    read_M1_cnt_bb.execute_stateful_alu_from_hash(hash_1);
}

blackbox stateful_alu rewrite_M1_cnt_bb
{
 reg: M1_cnt;
 update_lo_1_value: sf.count;
 output_value: register_lo;
 output_dst: m_meta.tmp_count;
}

action rewrite_M1_cnt_ac()
{
  rewrite_M1_cnt_bb.execute_stateful_alu_from_hash(hash_1);
}

/* @pragma stage 1 */
table update_M1_cnt_t
{
  reads {
  sf: valid;
  sf.table_idx: exact;
  m_meta.M1_srcip_pred: exact;
  m_meta.M1_dstip_pred: exact;
  m_meta.M1_proto_pred: exact;
  }
  actions {
    increase_M1_cnt_ac;
    read_M1_cnt_ac;
    rewrite_M1_cnt_ac;
    nop;
  }
 default_action: nop;
 max_size: 65;
}

/*---------- update_M1_status_t ----------*/
blackbox stateful_alu increase_M1_status_bb {
 reg: M1_status;
 condition_lo: register_lo < 0;

 update_lo_1_predicate: condition_lo;
 update_lo_1_value: 1;
 update_lo_2_predicate: not condition_lo;
 update_lo_1_value: register_lo + 1;
}

action increase_M1_status_ac() {
  increase_M1_status_bb.execute_stateful_alu_from_hash(hash_1);
}

blackbox stateful_alu decrease_M1_status_bb {
 reg: M1_status;
 update_lo_1_value: register_lo - 1;
 output_value: alu_lo;
 output_dst: m_meta.M1_status;
}

action decrease_M1_status_ac() {
  decrease_M1_status_bb.execute_stateful_alu_from_hash(hash_1);
}

blackbox stateful_alu rewrite_M1_status_bb {
 reg: M1_status;
 update_lo_1_value: 1;
}

action rewrite_M1_status_ac() {
  rewrite_M1_status_bb.execute_stateful_alu_from_hash(hash_1);
}

/* @pragma stage 3 */
table update_M1_status_t {
  reads {
  sf: valid;
  sf.table_idx: exact;
  m_meta.M1_match: exact;
  }
  actions {
    increase_M1_status_ac;
    decrease_M1_status_ac;
    rewrite_M1_status_ac;
  }
 max_size: 3;
}

/*---------- update_M2_srcip_t ----------*/
blackbox stateful_alu update_M2_srcip_bb
{
 reg: M2_srcip;
 condition_lo: register_lo == 0;
 condition_hi: register_lo == ipv4.srcip;

 update_lo_1_predicate: condition_lo or condition_hi;
 update_lo_1_value: ipv4.srcip;

 output_value: predicate;
 output_dst: m_meta.M2_srcip_pred;
}

action update_M2_srcip_ac()
{
    update_M2_srcip_bb.execute_stateful_alu_from_hash(hash_2);
}

blackbox stateful_alu rewrite_M2_srcip_bb
{
 reg: M2_srcip;
 update_lo_1_value: sf.srcip;
 output_value: register_lo;
 output_dst: m_meta.tmp_srcip;
}

action rewrite_M2_srcip_ac()
{
    rewrite_M2_srcip_bb.execute_stateful_alu_from_hash(hash_2);
}

/* @pragma stage 1 */
table update_M2_srcip_t {
  reads {
  sf: valid;
  sf.table_idx: exact;
  m_meta.M1_srcip_pred: exact;
  m_meta.M1_dstip_pred: exact;
  m_meta.M1_proto_pred: exact;
  }
  actions {
    update_M2_srcip_ac;
    rewrite_M2_srcip_ac;
    nop;
  }
 default_action: nop;
 max_size: 50;
}

/*---------- update_M2_dstip_t ----------*/
blackbox stateful_alu update_M2_dstip_bb
{
 reg: M2_dstip;
 condition_lo: register_lo == 0;
 condition_hi: register_lo == ipv4.dstip;

 update_lo_1_predicate: condition_lo or condition_hi;
 update_lo_1_value: ipv4.dstip;

 output_value: predicate;
 output_dst: m_meta.M2_dstip_pred;
}

action update_M2_dstip_ac()
{
    update_M2_dstip_bb.execute_stateful_alu_from_hash(hash_2);
}

blackbox stateful_alu rewrite_M2_dstip_bb
{
 reg: M2_dstip;
 update_lo_1_value: sf.dstip;
 output_value: register_lo;
 output_dst: m_meta.tmp_dstip;
}

action rewrite_M2_dstip_ac()
{
    rewrite_M2_dstip_bb.execute_stateful_alu_from_hash(hash_2);
}

/* @pragma stage 1 */
table update_M2_dstip_t {
  reads {
  sf: valid;
  sf.table_idx: exact;
  m_meta.M1_srcip_pred: exact;
  m_meta.M1_dstip_pred: exact;
  m_meta.M1_proto_pred: exact;
  }
  actions {
    update_M2_dstip_ac;
    rewrite_M2_dstip_ac;
    nop;
  }
 default_action: nop;
 max_size: 50;
}

/*---------- update_M2_proto_t ----------*/
blackbox stateful_alu update_M2_proto_bb
{
 reg: M2_proto;
 condition_lo: register_lo == 0;
 condition_hi: register_lo == ipv4.proto;

 update_lo_1_predicate: condition_lo or condition_hi;
 update_lo_1_value: ipv4.proto;

 output_value: predicate;
 output_dst: m_meta.M2_proto_pred;
}

action update_M2_proto_ac()
{
    update_M2_proto_bb.execute_stateful_alu_from_hash(hash_2);
}

blackbox stateful_alu rewrite_M2_proto_bb
{
 reg: M2_proto;
 update_lo_1_value: sf.proto;
 output_value: register_lo;
 output_dst: m_meta.tmp_proto;
}

action rewrite_M2_proto_ac()
{
    rewrite_M2_proto_bb.execute_stateful_alu_from_hash(hash_2);
}

/* @pragma stage 1 */
table update_M2_proto_t
{
  reads {
  sf: valid;
  sf.table_idx: exact;
  m_meta.M1_srcip_pred: exact;
  m_meta.M1_dstip_pred: exact;
  m_meta.M1_proto_pred: exact;
  }
  actions {
    update_M2_proto_ac;
    rewrite_M2_proto_ac;
    nop;
  }
 default_action: nop;
 max_size: 50;
}

/*---------- update_M2_cnt_t ----------*/
blackbox stateful_alu increase_M2_cnt_bb
{
 reg: M2_cnt;
 update_lo_1_value: register_lo + 1;
}

action increase_M2_cnt_ac()
{
    increase_M2_cnt_bb.execute_stateful_alu_from_hash(hash_2);
    modify_field(m_meta.M2_match, 1);
}

blackbox stateful_alu read_M2_cnt_bb
{
 reg: M2_cnt;

 output_value: register_lo;
 output_dst: m_meta.M2_cnt;
}

action read_M2_cnt_ac()
{
  read_M2_cnt_bb.execute_stateful_alu_from_hash(hash_2);
}

blackbox stateful_alu rewrite_M2_cnt_bb
{
 reg: M2_cnt;
 update_lo_1_value: sf.count;
 output_value: register_lo;
 output_dst: m_meta.tmp_count;
}

action rewrite_M2_cnt_ac()
{
    rewrite_M2_cnt_bb.execute_stateful_alu_from_hash(hash_2);
}

/* @pragma stage 2 */
table update_M2_cnt_t
{
  reads {
  sf: valid;
  sf.table_idx: exact;
  m_meta.M2_srcip_pred: exact;
  m_meta.M2_dstip_pred: exact;
  m_meta.M2_proto_pred: exact;
  }
  actions {
    nop;
    read_M2_cnt_ac;
    increase_M2_cnt_ac;
    rewrite_M2_cnt_ac;
  }
 default_action: nop;
 max_size: 65;
}

/*---------- update_M2_status_t ----------*/
blackbox stateful_alu increase_M2_status_bb {
 reg: M2_status;
 condition_lo: register_lo < 0;

 update_lo_1_predicate: condition_lo;
 update_lo_1_value: 1;
 update_lo_2_predicate: not condition_lo;
 update_lo_1_value: register_lo + 1;
}

action increase_M2_status_ac() {
  increase_M2_status_bb.execute_stateful_alu_from_hash(hash_2);
}

blackbox stateful_alu decrease_M2_status_bb {
 reg: M2_status;
 update_lo_1_value: register_lo - 1;
 output_value: register_lo;
 output_dst: m_meta.M2_status;
}

action decrease_M2_status_ac() {
  decrease_M2_status_bb.execute_stateful_alu_from_hash(hash_2);
}

blackbox stateful_alu rewrite_M2_status_bb {
 reg: M2_status;
 update_lo_1_value: 1;
}

action rewrite_M2_status_ac() {
  rewrite_M2_status_bb.execute_stateful_alu_from_hash(hash_2);
}

/* @pragma stage 3 */
table update_M2_status_t {
  reads {
  sf: valid;
  sf.table_idx: exact;
  m_meta.M2_match: exact;
  }
  actions {
    increase_M2_status_ac;
    decrease_M2_status_ac;
    rewrite_M2_status_ac;
  }
 max_size: 3;
}

/*---------- update_M3_srcip_t ----------*/
blackbox stateful_alu update_M3_srcip_bb
{
 reg: M3_srcip;
 condition_lo: register_lo == 0;
 condition_hi: register_lo == ipv4.srcip;

 update_lo_1_predicate: condition_lo or condition_hi;
 update_lo_1_value: ipv4.srcip;

 output_value: predicate;
 output_dst: m_meta.M3_srcip_pred;
}

action update_M3_srcip_ac()
{
    update_M3_srcip_bb.execute_stateful_alu_from_hash(hash_3);
}

blackbox stateful_alu rewrite_M3_srcip_bb
{
 reg: M3_srcip;
 update_lo_1_value: sf.srcip;
 output_value: register_lo;
 output_dst: m_meta.tmp_srcip;
}

action rewrite_M3_srcip_ac()
{
    rewrite_M3_srcip_bb.execute_stateful_alu_from_hash(hash_3);
}

/* @pragma stage 2 */
table update_M3_srcip_t
{
  reads {
  sf: valid;
  sf.table_idx: exact;
  m_meta.M1_match: exact;
  m_meta.M2_srcip_pred: exact;
  m_meta.M2_dstip_pred: exact;
  m_meta.M2_proto_pred: exact;
  }
  actions {
    update_M3_srcip_ac;
    rewrite_M3_srcip_ac;
    nop;
  }
 default_action: nop;
 max_size: 65;
}

/*---------- update_M3_dstip_t ----------*/
blackbox stateful_alu update_M3_dstip_bb
{
 reg: M3_dstip;
 condition_lo: register_lo == 0;
 condition_hi: register_lo == ipv4.dstip;

 update_lo_1_predicate: condition_lo or condition_hi;
 update_lo_1_value: ipv4.dstip;

 output_value: predicate;
 output_dst: m_meta.M3_dstip_pred;
}

action update_M3_dstip_ac()
{
    update_M3_dstip_bb.execute_stateful_alu_from_hash(hash_3);
}

blackbox stateful_alu rewrite_M3_dstip_bb
{
 reg: M3_dstip;
 update_lo_1_value: sf.dstip;
 output_value: register_lo;
 output_dst: m_meta.tmp_dstip;
}

action rewrite_M3_dstip_ac()
{
    rewrite_M3_dstip_bb.execute_stateful_alu_from_hash(hash_3);
}

/* @pragma stage 2 */
table update_M3_dstip_t
{
  reads {
  sf: valid;
  sf.table_idx: exact;
  m_meta.M1_match: exact;
  m_meta.M2_srcip_pred: exact;
  m_meta.M2_dstip_pred: exact;
  m_meta.M2_proto_pred: exact;
  }
  actions {
    update_M3_dstip_ac;
    rewrite_M3_dstip_ac;
    nop;
  }
 default_action: nop;
 max_size: 65;
}

/*---------- update_M3_proto_t ----------*/
blackbox stateful_alu update_M3_proto_bb
{
 reg: M3_proto;
 condition_lo: register_lo == 0;
 condition_hi: register_lo == ipv4.proto;

 update_lo_1_predicate: condition_lo or condition_hi;
 update_lo_1_value: ipv4.proto;

 output_value: predicate;
 output_dst: m_meta.M3_proto_pred;
}

action update_M3_proto_ac()
{
    update_M3_proto_bb.execute_stateful_alu_from_hash(hash_3);
}

blackbox stateful_alu rewrite_M3_proto_bb
{
 reg: M3_proto;
 update_lo_1_value: sf.proto;
 output_value: register_lo;
 output_dst: m_meta.tmp_proto;
}

action rewrite_M3_proto_ac()
{
    rewrite_M3_proto_bb.execute_stateful_alu_from_hash(hash_3);
}

/* @pragma stage 2 */
table update_M3_proto_t
{
  reads {
  sf: valid;
  sf.table_idx: exact;
  m_meta.M1_match: exact;
  m_meta.M2_srcip_pred: exact;
  m_meta.M2_dstip_pred: exact;
  m_meta.M2_proto_pred: exact;
  }
  actions {
    update_M3_proto_ac;
    rewrite_M3_proto_ac;
    nop;
  }
 default_action: nop;
 max_size: 65;
}

/*---------- update_M3_cnt_t ----------*/
blackbox stateful_alu increase_M3_cnt_bb
{
 reg: M3_cnt;
 update_lo_1_value: register_lo + 1;
}

action increase_M3_cnt_ac()
{
    increase_M3_cnt_bb.execute_stateful_alu_from_hash(hash_3);
    modify_field(m_meta.M3_match, 1);
}

blackbox stateful_alu read_M3_cnt_bb
{
 reg: M3_cnt;

 output_value: register_lo;
 output_dst: m_meta.M3_cnt;
}

action read_M3_cnt_ac()
{
    read_M3_cnt_bb.execute_stateful_alu_from_hash(hash_3);
}

blackbox stateful_alu rewrite_M3_cnt_bb
{
 reg: M3_cnt;
 update_lo_1_value: sf.count;
 output_value: register_lo;
 output_dst: m_meta.tmp_count;
}

action rewrite_M3_cnt_ac()
{
    rewrite_M3_cnt_bb.execute_stateful_alu_from_hash(hash_3);
}

/* @pragma stage 3 */
table update_M3_cnt_t
{
  reads {
  sf: valid;
  sf.table_idx: exact;
  m_meta.M3_srcip_pred: exact;
  m_meta.M3_dstip_pred: exact;
  m_meta.M3_proto_pred: exact;
  }
  actions {
    increase_M3_cnt_ac;
    read_M3_cnt_ac;
    rewrite_M3_cnt_ac;
    nop;
  }
 default_action: nop;
 max_size: 65;
}

/*---------- update_M3_status_t ----------*/
blackbox stateful_alu increase_M3_status_bb {
 reg: M3_status;
 condition_lo: register_lo < 0;

 update_lo_1_predicate: condition_lo;
 update_lo_1_value: 1;
 update_lo_2_predicate: not condition_lo;
 update_lo_1_value: register_lo + 1;
}

action increase_M3_status_ac() {
  increase_M3_status_bb.execute_stateful_alu_from_hash(hash_3);
}

blackbox stateful_alu decrease_M3_status_bb {
 reg: M3_status;
 update_lo_1_value: register_lo - 1;
 output_value: register_lo;
 output_dst: m_meta.M3_status;
}

action decrease_M3_status_ac() {
  decrease_M3_status_bb.execute_stateful_alu_from_hash(hash_3);
}

blackbox stateful_alu rewrite_M3_status_bb {
 reg: M3_status;
 update_lo_1_value: 1;
}

action rewrite_M3_status_ac() {
  rewrite_M3_status_bb.execute_stateful_alu_from_hash(hash_3);
}

/* @pragma stage 3 */
table update_M3_status_t {
  reads {
  sf: valid;
  sf.table_idx: exact;
  m_meta.M3_srcip_pred: exact;
  m_meta.M3_dstip_pred: exact;
  m_meta.M3_proto_pred: exact;
  }
  actions {
    increase_M3_status_ac;
    decrease_M3_status_ac;
    rewrite_M3_status_ac;
    nop;
  }
 default_action: nop;
 max_size: 126;
}

/*---------- calc_delta_cnt_status_t ----------*/
action calc_delta_cnt_status_ac() {
  subtract(m_meta.delta_cnt_M1_M2, m_meta.M1_cnt, m_meta.M2_cnt);
  subtract(m_meta.delta_cnt_M1_M3, m_meta.M1_cnt, m_meta.M3_cnt);
  subtract(m_meta.delta_cnt_M2_M3, m_meta.M2_cnt, m_meta.M3_cnt);
  subtract(m_meta.delta_status_M1_M2, m_meta.M1_status, m_meta.M2_status);
  subtract(m_meta.delta_status_M1_M3, m_meta.M1_status, m_meta.M3_status);
  subtract(m_meta.delta_status_M2_M3, m_meta.M2_status, m_meta.M3_status);
}

/* @pragma stage 4 */
table calc_delta_cnt_status_t {
  reads {
  m_meta.M1_match: exact;
  m_meta.M2_match: exact;
  m_meta.M3_match: exact;
  }
  actions {
    calc_delta_cnt_status_ac;
    nop;
  }
 default_action: nop;
 max_size: 1;
}

/*---------- test_t ----------*/
action test_ac() {
  /* modify_field(m_meta.test, 128); */
  count_bb.execute_stateful_alu(0);
}

/* @pragma stage 4 */
table test_t {
  /* reads { */
  /* sf: valid; */
  /* sf.table_idx: exact; */
  /* } */
  actions {
    /* nop; */
    test_ac;
  }
 default_action: test_ac;
}

/*---------- update_A_t ----------*/
blackbox stateful_alu update_A_bb
{
 reg: A;
 condition_lo: register_lo == m_meta.digest;

 update_lo_1_value: m_meta.digest;
  
 update_hi_1_predicate: condition_lo;
 update_hi_1_value: register_hi + 1;

 update_hi_2_predicate: not condition_lo;
 update_hi_2_value: 1;

 output_value: alu_hi;
 output_dst: m_meta.A_cnt;
}

action update_A_ac()
{
    update_A_bb.execute_stateful_alu_from_hash(hash_4);
}

/* @pragma stage 4 */
table update_A_t
{
  reads {
  m_meta.M1_match: exact;
  m_meta.M2_match: exact;
  m_meta.M3_match: exact;
  }
  actions {
    update_A_ac;
    nop;
  }
 default_action: nop;
 max_size: 1;
}

/*---------- calc_A_status_t ----------*/
action calc_delta_cnt_A_2_ac() {
  subtract(m_meta.delta_cnt_A_2, m_meta.A_cnt, 2);
}

/* @pragma stage 5 */
table calc_delta_cnt_A_2_t{
  reads {
  m_meta.M1_match: exact;
  m_meta.M2_match: exact;
  m_meta.M3_match: exact;
  }
  actions {
    calc_delta_cnt_A_2_ac;
    nop;
  }
 default_action: nop;
 max_size: 1;
}

/*---------- pick_min_cnt_t ----------*/
action pick_min_cnt_1_ac() {
  modify_field(m_meta.min_cnt, m_meta.M1_cnt);
  modify_field(m_meta.min_cnt_table_idx, 1);
}

action pick_min_cnt_2_ac() {
  modify_field(m_meta.min_cnt, m_meta.M2_cnt);
  modify_field(m_meta.min_cnt_table_idx, 2);
}

action pick_min_cnt_3_ac() {
  modify_field(m_meta.min_cnt, m_meta.M3_cnt);
  modify_field(m_meta.min_cnt_table_idx, 3);
}

/* @pragma stage 5 */
table pick_min_cnt_t {
  reads {
  m_meta.delta_cnt_M1_M2: ternary;
  m_meta.delta_cnt_M1_M3: ternary;
  m_meta.delta_cnt_M2_M3: ternary;
  }
  actions {
    pick_min_cnt_1_ac;
    pick_min_cnt_2_ac;
    pick_min_cnt_3_ac;
  }
 max_size: 8;
}

/*---------- pick_min_status_t ----------*/
action pick_min_status_1_ac() {
  modify_field(m_meta.min_status, m_meta.M1_status);
  modify_field(m_meta.min_status_table_idx, 1);
}

action pick_min_status_2_ac() {
  modify_field(m_meta.min_status, m_meta.M2_status);
  modify_field(m_meta.min_status_table_idx, 2);
}

action pick_min_status_3_ac() {
  modify_field(m_meta.min_status, m_meta.M3_status);
  modify_field(m_meta.min_status_table_idx, 3);
}

/* @pragma stage 5 */
table pick_min_status_t {
  reads {
  m_meta.delta_status_M1_M2: ternary;
  m_meta.delta_status_M1_M3: ternary;
  m_meta.delta_status_M2_M3: ternary;
  }
  actions {
    pick_min_status_1_ac;
    pick_min_status_2_ac;
    pick_min_status_3_ac;
  }
 max_size: 3;
}

/*---------- update_A_status_t ----------*/
blackbox stateful_alu increase_A_status_bb {
 reg: A_status;
 update_lo_1_value: register_lo + 1;
 output_value: alu_lo;
 output_dst: m_meta.A_status;
}

action increase_A_status_ac() {
  increase_A_status_bb.execute_stateful_alu_from_hash(hash_4);
}

blackbox stateful_alu decrease_A_status_bb {
 reg: A_status;
 update_lo_1_value: register_lo - 1;
}

action decrease_A_status_ac() {
  decrease_A_status_bb.execute_stateful_alu_from_hash(hash_4);
}

blackbox stateful_alu set_A_status_bb {
 reg: A_status;
 update_lo_1_value: m_meta.min_status;
}

action set_A_status_ac() {
  set_A_status_bb.execute_stateful_alu_from_hash(hash_4);
}

/* @pragma stage 6 */
table update_A_status_t {
  reads {
  m_meta.M1_match: exact;
  m_meta.M2_match: exact;
  m_meta.M3_match: exact;
  m_meta.delta_cnt_A_2: ternary;
  }
  actions {
    increase_A_status_ac;
    decrease_A_status_ac;
    set_A_status_ac;
  }
 max_size: 5;
}

/*---------- compare_M_A_cnts_t ----------*/
action compare_M_A_cnts_ac()
{
    subtract(m_meta.delta_cnt_min_A, m_meta.min_cnt, m_meta.A_cnt);
}

/* @pragma stage 7 */
table compare_M_A_cnts_t
{
  actions {
    compare_M_A_cnts_ac;
  }
 default_action: compare_M_A_cnts_ac;
}

/*---------- compare_M_A_status_t ----------*/
action compare_M_A_status_ac() {
  subtract(m_meta.delta_status_min_A, m_meta.min_status, m_meta.A_status);
}

/* @pragma stage 7 */
table compare_M_A_status_t {
  actions {
    compare_M_A_status_ac;
  }
 default_action: compare_M_A_status_ac;
}

/*---------- choose_promotion_table_idx_t ----------*/
action choose_table_idx_min_count_ac() {
  modify_field(m_meta.promotion, 1);
  set_export_flag_bb.execute_stateful_alu_from_hash(hash_4);
  modify_field(m_meta.promotion_table_idx, m_meta.min_cnt_table_idx);
}

action choose_table_idx_min_status_ac() {
  modify_field(m_meta.promotion, 1);
  set_export_flag_bb.execute_stateful_alu_from_hash(hash_4);
  modify_field(m_meta.promotion_table_idx, m_meta.min_status_table_idx);
}

/* @pragma stage 8 */
table choose_promotion_table_idx_t {
  reads {
  m_meta.M1_match: exact;
  m_meta.M2_match: exact;
  m_meta.M3_match: exact;
  m_meta.delta_cnt_A_2: ternary;
  m_meta.delta_cnt_min_A: ternary;
  m_meta.delta_status_min_A: ternary;
  }
  actions {
    choose_table_idx_min_count_ac;
    choose_table_idx_min_status_ac;
    clr_export_flag_ac;
    nop;
  }
 default_action: nop;
}
/*---------- clone_t ----------*/
field_list clone_fields
{
    m_meta.promotion_table_idx;
    m_meta.A_cnt; //16 bits
    m_meta.tmp_srcip;
    m_meta.tmp_dstip;
    m_meta.tmp_proto;
}

action clone_ac()
{
  clone_ingress_pkt_to_egress(RECIRC_SESS_ID, clone_fields);
  /* modify_field(); */
}

/* @pragma stage 9 */
table clone_t
{
    reads {
    m_meta.promotion: exact;
    m_meta.export_flag: exact;
    }
    actions {
      clone_ac;
      nop;
    }
 max_size: 1;
}

/*---------- add_sf_header_t ----------*/
action add_sf_header_ac() {
  modify_field(sf.table_idx, m_meta.promotion_table_idx);
  modify_field(sf.srcip, m_meta.tmp_srcip);
  modify_field(sf.dstip, m_meta.tmp_dstip);
  modify_field(sf.proto, m_meta.tmp_proto);
  modify_field(sf.count, m_meta.A_cnt);
  modify_field(ipv4.proto, IPV4_SF);
  add_header(sf);
}

table add_sf_header_t {
  actions {
    add_sf_header_ac;
  }
 default_action: add_sf_header_ac;
}

/*---------- copy_flow_id_t ----------*/
action copy_flow_id_ac() {
  /* count_bb.execute_stateful_alu(0); */
  modify_field(m_meta.tmp_srcip, ipv4.srcip);
  modify_field(m_meta.tmp_dstip, ipv4.dstip);
  modify_field(m_meta.tmp_proto, ipv4.proto);
}

/* @pragma stage 4 */
table copy_flow_id_t {
  actions {
    copy_flow_id_ac;
  }
 default_action: copy_flow_id_ac;
}

/*---------- manage_export_flag_t ----------*/
blackbox stateful_alu set_export_flag_bb {
 reg: export_flag;
 update_lo_1_value: set_bit;
 output_value: register_lo;
 output_dst: m_meta.export_flag;
}
action set_export_flag_ac() {
  set_export_flag_bb.execute_stateful_alu_from_hash(hash_4);
}

blackbox stateful_alu clr_export_flag_bb {
 reg: export_flag;
 update_lo_1_value: clr_bit;
 output_value: register_lo;
 output_dst: m_meta.export_flag;
}
action clr_export_flag_ac() {
  clr_export_flag_bb.execute_stateful_alu_from_hash(hash_4);
}
