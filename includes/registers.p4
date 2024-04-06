/* Zhao Zongyi, xinshengzzy@foxmail.com */
/* #include "tofino/stateful_alu_blackbox.p4" */
/* #include "tofino/pktgen_headers.p4" */
/* #include <tofino/constants.p4> */
/* #include <tofino/intrinsic_metadata.p4> */

/* #include "includes/headers.p4" */
/* #include "includes/parser.p4" */
/* #include "includes/macro.p4" */


/*---------- Registers for M1 ----------*/
register M1_srcip
{
    width: 32;
    instance_count: M1_SIZE;
}
register M1_dstip
{
    width: 32;
    instance_count: M1_SIZE;
}

register M1_ips {
 width: 64;
 instance_count: M1_SIZE;
}

register M1_proto
{
    width: 8;
    instance_count: M1_SIZE;
}
register M1_cnt
{
    width: 16;
    instance_count: M1_SIZE;
}
register M1_status
{
    width: 16;
    instance_count: M1_SIZE;
}

/*---------- Registers for M2 ----------*/
register M2_srcip
{
    width: 32;
    instance_count: M2_SIZE;
}
register M2_dstip
{
    width: 32;
    instance_count: M2_SIZE;
}
register M2_ips {
 width: 64;
 instance_count: M2_SIZE;
}
register M2_proto
{
    width: 8;
    instance_count: M2_SIZE;
}
register M2_cnt
{
    width: 16;
    instance_count: M2_SIZE;
}
register M2_status
{
    width: 16;
    instance_count: M2_SIZE;
}

/*---------- Registers for M3 ----------*/
register M3_srcip
{
    width: 32;
    instance_count: M3_SIZE;
}
register M3_dstip
{
    width: 32;
    instance_count: M3_SIZE;
}
register M3_ips {
 width: 64;
 instance_count: M3_SIZE;
}
register M3_proto
{
    width: 8;
    instance_count: M3_SIZE;
}
register M3_cnt
{
    width: 16;
    instance_count: M3_SIZE;
}
register M3_status
{
    width: 16;
    instance_count: M3_SIZE;
}

/*---------- Registers for A ----------*/
register A
{
 width: 32; // register_lo is for the digest field, and register_hi is for the count field 
 instance_count: A_SIZE;
}

register A_status {
 width: 16;
 instance_count: A_SIZE;
}

/*---------- counts for test ----------*/
register count {
 width: 32;
 instance_count: 1;
}

/*---------- export_flag ----------*/
register export_flag {
 width: 1;
 instance_count: A_SIZE;
}
