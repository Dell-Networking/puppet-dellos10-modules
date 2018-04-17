# Sample manifest file for os10_route resource.


os10_route{'route1':
  ensure        => present,
  destination   => '2001::',
  prefix_len    => '126',
  next_hop_list => ['2000::1', '2000::2'],
}

os10_route{'route2':
  ensure        => present,
  destination   => '2.1.1.0',
  prefix_len    => '24',
  next_hop_list => ['interface ethernet1/1/1 255', 'interface vlan3'],
}
