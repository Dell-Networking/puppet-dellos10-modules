# Sample manifest file for os10_monitor resource.

os10_monitor{'session1':
  ensure      => present,
  id          => 1,
  source      => ['ethernet 1/1/7', 'ethernet 1/1/8'],
  destination => 'ethernet 1/1/10',
  flow_based  => false,
  shutdown    => false,
}
