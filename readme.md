This is the P4 code implementation of the paper FlowSensor. It runs on a P4 switch with the type of Wedge-100BF-32x.

FlowSensor is a new data plane flow monitoring tool which senses flow activeness and exports inactive flow records accordingly. 

Author：ZHAO Zongyi

The more important files are described as follows:

- FlowSensor.p4 is the main function file.
- /includes/table.p4 contains the implementation details of each function (namely match-action table).
- /ma_conf/configure.py contains entries that are wrote in the match-action table before the algorithm runs.