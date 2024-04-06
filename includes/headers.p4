#define FABRIC_HEADER_TYPE_CPU         5

/*---------- ethernet_h ----------*/
header_type ethernet_h {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header ethernet_h ethernet;

/*---------- vlan_tag_h ----------*/
header_type vlan_tag_h {
  fields {
  pri     : 3;
  cfi     : 1;
  vlan_id : 12;
  etherType : 16;
  }
}

header vlan_tag_h vlan_tag;

/*---------- ipv4_h ----------*/
header_type ipv4_h {
  fields {
  version : 4;
  ihl : 4;
  diffserv : 8;
  totalLen : 16;
  identification : 16;
  flags : 3;
  fragOffset : 13;
  ttl : 8;
  proto : 8;
  hdrChecksum : 16;
  srcip : 32;
  dstip: 32;
  }
}

header ipv4_h ipv4;

/*---------- fabric_h ----------*/
header_type fabric_h {
    fields {
        packetType : 3;
        headerVersion : 2;
        packetVersion : 2;
        pad1 : 1;
    	pad2: 8;

        fabricColor : 3;
        fabricQos : 5;

        dstDevice : 8;
        dstPortOrGroup : 16;
    }
}

header fabric_h fabric;

/*---------- fabric_cpu_h ----------*/
header_type fabric_cpu_h {
    fields {
        egressQueue : 5;
        txBypass : 1;
        reserved : 2;
    	pad: 8;

        ingressPort: 16;
        ingressIfindex : 16;
        ingressBd : 16;

        reasonCode : 16;
    }
}

header fabric_cpu_h fabric_cpu;

/*---------- fabric_payload_h ----------*/
header_type fabric_payload_h {
    fields {
    etherType : 16;
    test: 16;
    }
}

header fabric_payload_h fabric_payload;

/*---------- superflow_h ----------*/
header_type superflow_h {
  fields {
  srcip: 32;
  dstip: 32;
  srcport: 16;
  dstport: 16;
  count: 16;
  proto: 8;
  table_idx: 8;
  }
}

header superflow_h sf;
