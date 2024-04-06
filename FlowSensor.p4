/* Zhao Zongyi, xinshengzzy@foxmail.com*/
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/pktgen_headers.p4>
#include <tofino/stateful_alu_blackbox.p4>
#include <tofino/wred_blackbox.p4>

#include "includes/fieldlists.p4"
#include "includes/headers.p4"
#include "includes/metadata.p4"
#include "includes/parsers.p4"
#include "includes/registers.p4"
#include "includes/tables.p4"


/*---------- ingress ----------*/
/* It seems that at most four MA tables accessing the registers are allowed in each stage. */
control ingress {
  apply(forward_t);
  if(valid(ipv4)) {
    // stage 0
    apply(calc_digest_t);
    apply(update_M1_srcip_t);
    apply(update_M1_dstip_t);
    apply(update_M1_proto_t);
    // stage 1
    apply(update_M2_srcip_t);
    apply(update_M2_dstip_t);
    apply(update_M2_proto_t);
    apply(update_M1_cnt_t);
    // stage 2
    apply(update_M3_srcip_t);
    apply(update_M3_dstip_t);
    apply(update_M3_proto_t);
    apply(update_M2_cnt_t);
    // stage 3
    apply(update_M3_cnt_t);
    apply(update_M1_status_t);
    apply(update_M2_status_t);
    apply(update_M3_status_t);
    if(not valid(sf)) {
      // stage 4
      apply(update_A_t);
      apply(calc_delta_cnt_status_t);
      apply(copy_flow_id_t);
      // stage 5
      apply(calc_delta_cnt_A_2_t);
      apply(pick_min_status_t);
      apply(pick_min_cnt_t);
      // stage 6
      apply(update_A_status_t);
      // stage 7
      apply(compare_M_A_cnts_t);
      apply(compare_M_A_status_t);
      // stage 8
      apply(choose_promotion_table_idx_t);
      // stage 9
      apply(clone_t);
    }
    else {// export the packet
      // stage 4
      apply(export_t);
    }
  }
}

/*---------- egress ----------*/
control egress
{
  if(valid(ipv4) and not valid(sf)) {
  }
  if(pkt_is_mirrored) {
    apply(test_t);
    apply(add_sf_header_t);
  }
}
