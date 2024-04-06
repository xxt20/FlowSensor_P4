#define ETHERTYPE_BF_FABRIC     0x9000
#define FABRIC_HEADER_TYPE_CPU 5
#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_VLAN 0x8100
#define IPV4_SF 99

/*---------- start ----------*/
parser start {
    return parse_ethernet;
}

/*---------- parse_ethernet ----------*/
parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
    ETHERTYPE_IPV4 : parse_ipv4;
    ETHERTYPE_VLAN: parse_vlan_tag;
    ETHERTYPE_BF_FABRIC : parse_fabric;
    default: ingress;
    }
}

/*---------- parse_vlan_tag ----------*/
parser parse_vlan_tag {
  extract(vlan_tag);
  return select(latest.etherType) {
  ETHERTYPE_IPV4 : parse_ipv4;
  default : ingress;
  }
}

/*---------- parse_ipv4 ----------*/
parser parse_ipv4 {
  extract(ipv4);
  return select(latest.proto) {
  IPV4_SF: parse_sf;
  default: ingress;
  }
}

/*---------- parse_sf ---------*/
parser parse_sf {
  extract(sf);
  return ingress;
}

/*---------- parse_fabric ----------*/
parser parse_fabric {
  extract(fabric);
  return select(latest.packetType)  {
  default : parse_fabric_cpu;
  }
}

/*---------- parse_fabric_cpu ----------*/
parser parse_fabric_cpu {
  extract(fabric_cpu);
  return select(latest.ingressPort) {
  	default: parse_fabric_payload;
  }
}

/*---------- parse_fabric_payload ----------*/
parser parse_fabric_payload {
  extract(fabric_payload);
  return select(latest.etherType) {
  ETHERTYPE_IPV4 : parse_ipv4;
	  default: ingress;
  }
}
