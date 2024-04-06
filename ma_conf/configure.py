# Copyright 2013-present Barefoot Networks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
Thrift PD interface basic tests
"""

from collections import OrderedDict

import time
import sys
import logging
import copy
import pdb
import datetime

import unittest
import random

import pd_base_tests

from ptf import config
from ptf.testutils import *
from ptf.thriftutils import *
import ptf.dataplane as dataplane

import os

from pal_rpc.ttypes import *
from FlowSensor.p4_pd_rpc.ttypes import *
from conn_mgr_pd_rpc.ttypes import *
from mirror_pd_rpc.ttypes import *
from mc_pd_rpc.ttypes import *
from devport_mgr_pd_rpc.ttypes import *
from res_pd_rpc.ttypes import *
from ptf_port import *


dev_id = 0
PORT_TBL_SIZE = 288
IFID_TBL_SIZE = 25000
SIP_SAMPLER_TBL_SIZE = 85000
SIP_SAMPLER_REG_SIZE = 143360
SCRATCH_REG_SIZE = 4096
NEXT_HOP_TBL_SIZE = 4096
IP_ROUTE_TBL_SIZE = 512
EGR_PORT_TBL_SIZE = 16384
BLOOM_FILTER_REG_SIZE = 256*1024
MAX_PORT_COUNT = 456
ECMP_REG_SIZE = 128*1024
LAG_REG_SIZE = 128*1024

RECIRC_TYPE_PG_PORT_DOWN = 1
RECIRC_TYPE_PG_RECIRC    = 2

def match(a, b, c):
      res1 = a in [2, 8] and b in [2, 8] and c in [2, 8]
      res2 = a in [4, 8] and b in [4, 8] and c in [4, 8]
      return res1 or res2

def mirror_session(mir_type, mir_dir, sid, egr_port=0, egr_port_v=False,
                   egr_port_queue=0, packet_color=0, mcast_grp_a=0,
                   mcast_grp_a_v=False, mcast_grp_b=0, mcast_grp_b_v=False,
                   max_pkt_len=0, level1_mcast_hash=0, level2_mcast_hash=0,
                   mcast_l1_xid=0, mcast_l2_xid=0, mcast_rid=0, cos=0,
                   c2c=0, extract_len=0, timeout=0, int_hdr=[], hdr_len=0):
      return MirrorSessionInfo_t(mir_type,
                                 mir_dir,
                                 sid,
                                 egr_port,
                                 egr_port_v,
                                 egr_port_queue,
                                 packet_color,
                                 mcast_grp_a,
                                 mcast_grp_a_v,
                                 mcast_grp_b,
                                 mcast_grp_b_v,
                                 max_pkt_len,
                                 level1_mcast_hash,
                                 level2_mcast_hash,
                                 mcast_l1_xid,
                                 mcast_l2_xid,
                                 mcast_rid,
                                 cos,
                                 c2c,
                                 extract_len,
                                 timeout,
                                 int_hdr,
                                 hdr_len)
  

def setup_random(seed_val=0):
    if 0 == seed_val:
        seed_val = int(time.time())
    print "Seed is:", seed_val
    sys.stdout.flush()
    random.seed(seed_val)

def make_port(pipe, local_port):
    assert(pipe >= 0 and pipe < 4)
    assert(local_port >= 0 and local_port < 72)
    return (pipe << 7) | local_port

def port_to_pipe(port):
    local_port = port & 0x7F
    assert(local_port < 72)
    pipe = (port >> 7) & 0x3
    assert(port == ((pipe << 7) | local_port))
    return pipe

# By default use 2 ports in each pipe
swports = []
for device, port, ifname in config["interfaces"]:
    pipe = port >> 7
    if pipe in range(int(test_param_get('num_pipes'))):
        swports.append(port)
        swports.sort()

if swports == []:
    for pipe in range(int(test_param_get('num_pipes'))):
        for port in range(2,4):
            swports.append( make_port(pipe,port) )
print "Using ports:", swports
sys.stdout.flush()

class TestPktGenClear(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ["FlowSensor"])

    def runTest(self):
        try:
            sess_hdl = self.conn_mgr.client_init()
            dev_tgt = DevTarget_t(dev_id, hex_to_i16(0xFFFF))
            self.num_pipes = int(test_param_get('num_pipes'))
            self.pipe_list = [x for x in range(self.num_pipes)]
            self.pipe_list_len = len(self.pipe_list)

            # configure the mirror session IDs of the traffic manager
            print("configure the traffic manager ...")
            recirc_sess_id = 20
            recirc_port = 68
            sids = [recirc_sess_id]
            # ports = [128, recirc_port]
            ports = [recirc_port]
            for port,sid in zip(ports, sids):
                info = mirror_session(MirrorType_e.PD_MIRROR_TYPE_NORM,
                                      Direction_e.PD_DIR_INGRESS,
                                      sid,
                                      port,
                                      True)
                self.mirror.mirror_session_create(sess_hdl, dev_tgt, info)
                print "Using session %d for port %d" % (sid, port)
                sys.stdout.flush()
                self.conn_mgr.complete_operations(sess_hdl)

            #---------- forward_t ----------#
            print("configure forward_t ...")
            self.client.forward_t_set_default_action_nop(sess_hdl, dev_tgt)
            match_spec = FlowSensor_forward_t_match_spec_t(128)
            action_spec = FlowSensor_set_egr_action_spec_t(144)
            self.client.forward_t_table_add_with_set_egr(sess_hdl,dev_tgt,match_spec, action_spec)
            match_spec = FlowSensor_forward_t_match_spec_t(144)
            action_spec = FlowSensor_set_egr_action_spec_t(128)
            self.client.forward_t_table_add_with_set_egr(sess_hdl,dev_tgt,match_spec, action_spec)
            match_spec = FlowSensor_forward_t_match_spec_t(160)
            action_spec = FlowSensor_set_egr_action_spec_t(176)
            self.client.forward_t_table_add_with_set_egr(sess_hdl,dev_tgt,match_spec, action_spec)
            match_spec = FlowSensor_forward_t_match_spec_t(176)
            action_spec = FlowSensor_set_egr_action_spec_t(160)
            self.client.forward_t_table_add_with_set_egr(sess_hdl,dev_tgt,match_spec, action_spec)
            match_spec = FlowSensor_forward_t_match_spec_t(60)
            action_spec = FlowSensor_set_egr_action_spec_t(44)
            self.client.forward_t_table_add_with_set_egr(sess_hdl,dev_tgt,match_spec, action_spec)
            match_spec = FlowSensor_forward_t_match_spec_t(44)
            action_spec = FlowSensor_set_egr_action_spec_t(60)
            self.client.forward_t_table_add_with_set_egr(sess_hdl,dev_tgt,match_spec, action_spec)
            #---------- test_t ----------#
            print("configure test_t ...")
            # mspec = FlowSensor_test_t_match_spec_t(True, 1)
            self.client.test_t_set_default_action_test_ac(sess_hdl, dev_tgt)
            #---------- calc_digest_t ----------#
            print("configure calc_digest_t ...")
            self.client.calc_digest_t_set_default_action_calc_digest_ac(sess_hdl, dev_tgt)

            #---------- update_M1_srcip_t ----------#
            print("configure update_M1_srcip_t ...")
            mspec = FlowSensor_update_M1_srcip_t_match_spec_t(False, 0)
            self.client.update_M1_srcip_t_table_add_with_update_M1_srcip_ac(sess_hdl, dev_tgt,
                                                                            mspec)
            mspec = FlowSensor_update_M1_srcip_t_match_spec_t(True, 1)
            self.client.update_M1_srcip_t_table_add_with_rewrite_M1_srcip_ac(sess_hdl, dev_tgt,
                                                                            mspec)
            #---------- update_M1_dstip_t ----------#
            print("configure update_M1_dstip_t ...")
            mspec = FlowSensor_update_M1_dstip_t_match_spec_t(False, 0)
            self.client.update_M1_dstip_t_table_add_with_update_M1_dstip_ac(sess_hdl, dev_tgt,
                                                                            mspec)
            mspec = FlowSensor_update_M1_dstip_t_match_spec_t(True, 1)
            self.client.update_M1_dstip_t_table_add_with_rewrite_M1_dstip_ac(sess_hdl, dev_tgt,
                                                                            mspec)
            #---------- update_M1_proto_t ----------#
            print("configure update_M1_proto_t ...")
            mspec = FlowSensor_update_M1_proto_t_match_spec_t(False, 0)
            self.client.update_M1_proto_t_table_add_with_update_M1_proto_ac(sess_hdl, dev_tgt,
                                                                            mspec)
            mspec = FlowSensor_update_M1_proto_t_match_spec_t(True, 1)
            self.client.update_M1_proto_t_table_add_with_rewrite_M1_proto_ac(sess_hdl, dev_tgt,
                                                                            mspec)
            #---------- update_M2_srcip_t ----------#
            print("configure update_M2_srcip_t ...")
            for a in [1, 2, 4, 8]:
                  for b in [1, 2, 4, 8]:
                        for c in [1, 2, 4, 8]:
                              if match(a, b, c):
                                    continue
                              mspec = FlowSensor_update_M2_srcip_t_match_spec_t(False, 0,
                                                                               a, b, c)
                              self.client.update_M2_srcip_t_table_add_with_update_M2_srcip_ac(
                                    sess_hdl, dev_tgt, mspec)
            mspec = FlowSensor_update_M2_srcip_t_match_spec_t(True, 2, 0, 0, 0)
            self.client.update_M2_srcip_t_table_add_with_rewrite_M2_srcip_ac(
                  sess_hdl, dev_tgt, mspec)
            #---------- update_M2_dstip_t ----------#
            print("configure update_M2_dstip_t ...")
            for a in [1, 2, 4, 8]:
                  for b in [1, 2, 4, 8]:
                        for c in [1, 2, 4, 8]:
                              if match(a, b, c):
                                    continue
                              mspec = FlowSensor_update_M2_dstip_t_match_spec_t(False, 0,
                                                                               a, b, c)
                              self.client.update_M2_dstip_t_table_add_with_update_M2_dstip_ac(
                                    sess_hdl, dev_tgt, mspec)
            mspec = FlowSensor_update_M2_dstip_t_match_spec_t(True, 2, 0, 0, 0)
            self.client.update_M2_dstip_t_table_add_with_rewrite_M2_dstip_ac(
                  sess_hdl, dev_tgt, mspec)
            #---------- update_M2_proto_t ----------#
            print("configure update_M2_proto_t ...")
            for a in [1, 2, 4, 8]:
                  for b in [1, 2, 4, 8]:
                        for c in [1, 2, 4, 8]:
                              if match(a, b, c):
                                    continue
                              mspec = FlowSensor_update_M2_proto_t_match_spec_t(False, 0,
                                                                               a, b, c)
                              self.client.update_M2_proto_t_table_add_with_update_M2_proto_ac(
                                    sess_hdl, dev_tgt, mspec)
            mspec = FlowSensor_update_M2_proto_t_match_spec_t(True, 2, 0, 0, 0)
            self.client.update_M2_proto_t_table_add_with_rewrite_M2_proto_ac(
                  sess_hdl, dev_tgt, mspec)
            #---------- update_M3_srcip_t ----------#
            print("configure update_M3_srcip_t ...")
            mspec = FlowSensor_update_M3_srcip_t_match_spec_t(True, 3, 0, 0, 0, 0)
            self.client.update_M3_srcip_t_table_add_with_rewrite_M3_srcip_ac(
                  sess_hdl, dev_tgt, mspec)
            for a in [1, 2, 4, 8]:
                  for b in [1, 2, 4, 8]:
                        for c in [1, 2, 4, 8]:
                              if match(a, b, c):
                                    continue
                              mspec = FlowSensor_update_M3_srcip_t_match_spec_t(False, 0, 0,
                                                                               a, b, c)
                              self.client.update_M3_srcip_t_table_add_with_update_M3_srcip_ac(
                                    sess_hdl, dev_tgt, mspec)
            #---------- update_M3_dstip_t ----------#
            print("configure update_M3_dstip_t ...")
            mspec = FlowSensor_update_M3_dstip_t_match_spec_t(True, 3, 0, 0, 0, 0)
            self.client.update_M3_dstip_t_table_add_with_rewrite_M3_dstip_ac(
                  sess_hdl, dev_tgt, mspec)
            for a in [1, 2, 4, 8]:
                  for b in [1, 2, 4, 8]:
                        for c in [1, 2, 4, 8]:
                              if match(a, b, c):
                                    continue
                              mspec = FlowSensor_update_M3_dstip_t_match_spec_t(False, 0, 0,
                                                                               a, b, c)
                              self.client.update_M3_dstip_t_table_add_with_update_M3_dstip_ac(
                                    sess_hdl, dev_tgt, mspec)
            #---------- update_M3_proto_t ----------#
            print("configure update_M3_proto_t ...")
            mspec = FlowSensor_update_M3_proto_t_match_spec_t(True, 3, 0, 0, 0, 0)
            self.client.update_M3_proto_t_table_add_with_rewrite_M3_proto_ac(
                  sess_hdl, dev_tgt, mspec)
            for a in [1, 2, 4, 8]:
                  for b in [1, 2, 4, 8]:
                        for c in [1, 2, 4, 8]:
                              if match(a, b, c):
                                    continue
                              mspec = FlowSensor_update_M3_proto_t_match_spec_t(False, 0, 0,
                                                                               a, b, c)
                              self.client.update_M3_proto_t_table_add_with_update_M3_proto_ac(
                                    sess_hdl, dev_tgt, mspec)
            #---------- update_M1_cnt_t ----------#
            print("configure update_M1_cnt_t ...")
            mspec = FlowSensor_update_M1_cnt_t_match_spec_t(True, 1, 0, 0, 0)
            self.client.update_M1_cnt_t_table_add_with_rewrite_M1_cnt_ac(
                  sess_hdl, dev_tgt, mspec)
            for a in [1, 2, 4, 8]:
                  for b in [1, 2, 4, 8]:
                        for c in [1, 2, 4, 8]:
                              mspec = FlowSensor_update_M1_cnt_t_match_spec_t(False, 0, a, b, c)
                              if match(a, b, c):
                                    self.client.update_M1_cnt_t_table_add_with_increase_M1_cnt_ac(
                                          sess_hdl, dev_tgt, mspec)
                              else:
                                    self.client.update_M1_cnt_t_table_add_with_read_M1_cnt_ac(
                                          sess_hdl, dev_tgt, mspec)
            #---------- update_M2_cnt_t ----------#
            print("configure update_M2_cnt_t ...")
            mspec = FlowSensor_update_M2_cnt_t_match_spec_t(True, 2, 0, 0, 0)
            self.client.update_M2_cnt_t_table_add_with_rewrite_M2_cnt_ac(
                  sess_hdl, dev_tgt, mspec)
            for a in [1, 2, 4, 8]:
                  for b in [1, 2, 4, 8]:
                        for c in [1, 2, 4, 8]:
                              mspec = FlowSensor_update_M2_cnt_t_match_spec_t(False, 0, a, b, c)
                              if match(a, b, c):
                                    self.client.update_M2_cnt_t_table_add_with_increase_M2_cnt_ac(
                                          sess_hdl, dev_tgt, mspec)
                              else:
                                    self.client.update_M2_cnt_t_table_add_with_read_M2_cnt_ac(
                                          sess_hdl, dev_tgt, mspec)
            #---------- update_M3_cnt_t ----------#
            print("configure update_M3_cnt_t ...")
            mspec = FlowSensor_update_M3_cnt_t_match_spec_t(True, 3, 0, 0, 0)
            self.client.update_M3_cnt_t_table_add_with_rewrite_M3_cnt_ac(
                  sess_hdl, dev_tgt, mspec)
            for a in [1, 2, 4, 8]:
                  for b in [1, 2, 4, 8]:
                        for c in [1, 2, 4, 8]:
                              mspec = FlowSensor_update_M3_cnt_t_match_spec_t(False, 0, a, b, c)
                              if match(a, b, c):
                                    self.client.update_M3_cnt_t_table_add_with_increase_M3_cnt_ac(
                                          sess_hdl, dev_tgt, mspec)
                              else:
                                    self.client.update_M3_cnt_t_table_add_with_read_M3_cnt_ac(
                                          sess_hdl, dev_tgt, mspec)
            #---------- update_M1_status_t ----------#
            print("configure update_M1_status_t ...")
            mspec = FlowSensor_update_M1_status_t_match_spec_t(True, 1, 0)
            self.client.update_M1_status_t_table_add_with_rewrite_M1_status_ac(
                  sess_hdl, dev_tgt, mspec)
            mspec = FlowSensor_update_M1_status_t_match_spec_t(False, 0, 1)
            self.client.update_M1_status_t_table_add_with_increase_M1_status_ac(
                  sess_hdl, dev_tgt, mspec)
            mspec = FlowSensor_update_M1_status_t_match_spec_t(False, 0, 0)
            self.client.update_M1_status_t_table_add_with_decrease_M1_status_ac(
                  sess_hdl, dev_tgt, mspec)
            #---------- update_M2_status_t ----------#
            print("configure update_M2_status_t ...")
            mspec = FlowSensor_update_M2_status_t_match_spec_t(True, 2, 0)
            self.client.update_M2_status_t_table_add_with_rewrite_M2_status_ac(
                  sess_hdl, dev_tgt, mspec)
            mspec = FlowSensor_update_M2_status_t_match_spec_t(False, 0, 1)
            self.client.update_M2_status_t_table_add_with_increase_M2_status_ac(
                  sess_hdl, dev_tgt, mspec)
            mspec = FlowSensor_update_M2_status_t_match_spec_t(False, 0, 0)
            self.client.update_M2_status_t_table_add_with_decrease_M2_status_ac(
                  sess_hdl, dev_tgt, mspec)
            #---------- update_M3_status_t ----------#
            print("configure update_M3_status_t ...")
            mspec = FlowSensor_update_M3_status_t_match_spec_t(True, 3, 0, 0, 0)
            self.client.update_M3_status_t_table_add_with_rewrite_M3_status_ac(
                  sess_hdl, dev_tgt, mspec)
            for a in [0, 1, 2, 4, 8]:
                  for b in [0, 1, 2, 4, 8]:
                        for c in [0, 1, 2, 4, 8]:
                              mspec = FlowSensor_update_M3_status_t_match_spec_t(False, 0, a, b, c)
                              if match(a, b, c):
                                    self.client.update_M3_status_t_table_add_with_increase_M3_status_ac(sess_hdl, dev_tgt, mspec)
                              else:
                                    self.client.update_M3_status_t_table_add_with_decrease_M3_status_ac(sess_hdl, dev_tgt, mspec)
            #---------- update_A_t ----------#
            print("configure update_A_t ...")
            mspec = FlowSensor_update_A_t_match_spec_t(0, 0, 0)
            self.client.update_A_t_table_add_with_update_A_ac(sess_hdl, dev_tgt, mspec)
            #---------- calc_delta_cnt_status_t ----------#
            print("configure calc_delta_cnt_status_t ...")
            mspec = FlowSensor_calc_delta_cnt_status_t_match_spec_t(0, 0, 0)
            self.client.calc_delta_cnt_status_t_table_add_with_calc_delta_cnt_status_ac(
                  sess_hdl, dev_tgt, mspec)
            #---------- calc_delta_cnt_A_2_t ----------#
            print("configure calc_delta_cnt_A_2_t ...")
            mspec = FlowSensor_calc_delta_cnt_A_2_t_match_spec_t(0, 0, 0)
            self.client.calc_delta_cnt_A_2_t_table_add_with_calc_delta_cnt_A_2_ac(
                  sess_hdl, dev_tgt, mspec)
            #---------- pick_min_status_t ----------#
            print("configure pick_min_status_t ...")
            mspec = FlowSensor_pick_min_status_t_match_spec_t(
                  hex_to_i16(0x8000), hex_to_i16(0x8000),
                  hex_to_i16(0x8000), hex_to_i16(0x8000),
                  hex_to_i16(0x0000), hex_to_i16(0x0000))
            self.client.pick_min_status_t_table_add_with_pick_min_status_1_ac(sess_hdl, dev_tgt,
                                                                              mspec, 1)
            mspec = FlowSensor_pick_min_status_t_match_spec_t(
                  hex_to_i16(0x0000), hex_to_i16(0x8000),
                  hex_to_i16(0x0000), hex_to_i16(0x0000),
                  hex_to_i16(0x8000), hex_to_i16(0x8000))
            self.client.pick_min_status_t_table_add_with_pick_min_status_2_ac(sess_hdl, dev_tgt,
                                                                              mspec, 1)
            mspec = FlowSensor_pick_min_status_t_match_spec_t(
                  hex_to_i16(0x0000), hex_to_i16(0x0000),
                  hex_to_i16(0x0000), hex_to_i16(0x8000),
                  hex_to_i16(0x0000), hex_to_i16(0x8000))
            self.client.pick_min_status_t_table_add_with_pick_min_status_3_ac(sess_hdl, dev_tgt,
                                                                              mspec, 1)
            #---------- pick_min_cnt_t ----------#
            print("configure pick_min_cnt_t ...")
            mspec = FlowSensor_pick_min_cnt_t_match_spec_t(
                  hex_to_i16(0x8000), hex_to_i16(0x8000),
                  hex_to_i16(0x8000), hex_to_i16(0x8000),
                  hex_to_i16(0x0000), hex_to_i16(0x0000))
            self.client.pick_min_cnt_t_table_add_with_pick_min_cnt_1_ac(sess_hdl, dev_tgt,
                                                                              mspec, 1)
            mspec = FlowSensor_pick_min_cnt_t_match_spec_t(
                  hex_to_i16(0x0000), hex_to_i16(0x8000),
                  hex_to_i16(0x0000), hex_to_i16(0x0000),
                  hex_to_i16(0x8000), hex_to_i16(0x8000))
            self.client.pick_min_cnt_t_table_add_with_pick_min_cnt_2_ac(sess_hdl, dev_tgt,
                                                                              mspec, 1)
            mspec = FlowSensor_pick_min_cnt_t_match_spec_t(
                  hex_to_i16(0x0000), hex_to_i16(0x0000),
                  hex_to_i16(0x0000), hex_to_i16(0x8000),
                  hex_to_i16(0x0000), hex_to_i16(0x8000))
            self.client.pick_min_cnt_t_table_add_with_pick_min_cnt_3_ac(sess_hdl, dev_tgt,
                                                                              mspec, 1)
            #---------- update_A_status_t ----------#
            print("configure update_A_status_t ...")
            mspec = FlowSensor_update_A_status_t_match_spec_t(1, 0, 0,
                                                             hex_to_i16(0x0000), hex_to_i16(0x0000))
            self.client.update_A_status_t_table_add_with_decrease_A_status_ac(sess_hdl, dev_tgt,
                                                                              mspec, 1)
            mspec = FlowSensor_update_A_status_t_match_spec_t(0, 1, 0,
                                                             hex_to_i16(0x0000), hex_to_i16(0x0000))
            self.client.update_A_status_t_table_add_with_decrease_A_status_ac(sess_hdl, dev_tgt,
                                                                              mspec, 1)
            mspec = FlowSensor_update_A_status_t_match_spec_t(0, 0, 1,
                                                             hex_to_i16(0x0000), hex_to_i16(0x0000))
            self.client.update_A_status_t_table_add_with_decrease_A_status_ac(sess_hdl, dev_tgt,
                                                                              mspec, 1)
            mspec = FlowSensor_update_A_status_t_match_spec_t(0, 0, 0,
                                                             hex_to_i16(0x0000), hex_to_i16(0x8000))
            self.client.update_A_status_t_table_add_with_increase_A_status_ac(sess_hdl, dev_tgt,
                                                                              mspec, 1)
            mspec = FlowSensor_update_A_status_t_match_spec_t(0, 0, 0,
                                                             hex_to_i16(0x8000), hex_to_i16(0x8000))
            self.client.update_A_status_t_table_add_with_set_A_status_ac(sess_hdl, dev_tgt,
                                                                              mspec, 1)
            #---------- compare_M_A_cnts_t ----------#
            print("configure compare_M_A_cnts_t ...")
            self.client.compare_M_A_cnts_t_set_default_action_compare_M_A_cnts_ac(sess_hdl, dev_tgt)
            #---------- compare_M_A_status_t ----------#
            print("configure compare_M_A_status_t ...")
            self.client.compare_M_A_status_t_set_default_action_compare_M_A_status_ac(sess_hdl,
                                                                                      dev_tgt)
            #---------- choose_promotion_table_idx_t ----------#
            print("configure choose_promotion_table_idx_t ...")
            mspec = FlowSensor_choose_promotion_table_idx_t_match_spec_t(
                  0, 0, 0,
                  hex_to_i16(0x0000), hex_to_i16(0x8000),
                  hex_to_i16(0x0000), hex_to_i16(0x8000),
                  hex_to_i16(0x0000), hex_to_i16(0x0000))
            self.client.choose_promotion_table_idx_t_table_add_with_choose_table_idx_min_count_ac(
                  sess_hdl, dev_tgt, mspec, 1)
            mspec = FlowSensor_choose_promotion_table_idx_t_match_spec_t(
                  0, 0, 0,
                  hex_to_i16(0x0000), hex_to_i16(0x8000),
                  hex_to_i16(0x8000), hex_to_i16(0x8000),
                  hex_to_i16(0x0000), hex_to_i16(0x8000))
            self.client.choose_promotion_table_idx_t_table_add_with_choose_table_idx_min_status_ac(
                  sess_hdl, dev_tgt, mspec, 2)
            mspec = FlowSensor_choose_promotion_table_idx_t_match_spec_t(
                  0, 0, 0,
                  hex_to_i16(0x8000), hex_to_i16(0x8000),
                  hex_to_i16(0x0000), hex_to_i16(0x0000),
                  hex_to_i16(0x0000), hex_to_i16(0x0000))
            self.client.choose_promotion_table_idx_t_table_add_with_clr_export_flag_ac(
                  sess_hdl, dev_tgt, mspec, 2)
            #---------- clone_t ----------#
            print("configure clone_t ...")
            mspec = FlowSensor_clone_t_match_spec_t(1, 0)
            self.client.clone_t_table_add_with_clone_ac(sess_hdl, dev_tgt, mspec)
            #---------- export_t ----------#
            print("configure export_t ...")
            self.client.export_t_set_default_action_export_ac(sess_hdl, dev_tgt)
            #---------- add_sf_header_t ----------#
            print("configure add_sf_header_t ...")
            self.client.add_sf_header_t_set_default_action_add_sf_header_ac(sess_hdl, dev_tgt)
            #---------- copy_flow_id_t ----------#
            print("configure copy_flow_id_t ...")
            self.client.copy_flow_id_t_set_default_action_copy_flow_id_ac(sess_hdl, dev_tgt)
        except:
            raise SystemExit("Configuration Failed.")
        finally:
#            self.conn_mgr.begin_batch(sess_hdl)
#            self.client.register_reset_all_bloom_filter_1(sess_hdl, dev_tgt)
#            self.client.register_reset_all_bloom_filter_2(sess_hdl, dev_tgt)
#            self.client.register_reset_all_bloom_filter_3(sess_hdl, dev_tgt)
#            self.conn_mgr.pktgen_app_disable( sess_hdl, dev_tgt, 3 )
#            self.conn_mgr.end_batch(sess_hdl, True)
            self.conn_mgr.client_cleanup(hex_to_i32(sess_hdl))
            # raise SystemExit("Configuration Failed.")
