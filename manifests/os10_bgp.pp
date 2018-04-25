# Sample manifest file for os10 bgp configuration. This includes os10_bgp,
# os10_bgp_af, os10_bgp_neighbor and os10_bgp_neighbor_af resources.


os10_bgp{'trial_bgp_conf':
  ensure                           => present,
  asn                              => '65537',
  router_id                        => '10.10.10.10',
  max_path_ebgp                    => '20',
  max_path_ibgp                    => '30',
  graceful_restart                 => 'false',
  log_neighbor_changes             => 'absent',
  fast_external_fallover           => 'false',
  always_compare_med               => 'false',
  default_loc_pref                 => '22',
  confederation_identifier         => '3',
  confederation_peers              => [2,33,4],
  route_reflector_client_to_client => 'absent',
  route_reflector_cluster_id       => '1.1.1.1',
  bestpath_as_path                 => 'ignore',
  bestpath_med_confed              => 'absent',
  bestpath_med_missing_as_worst    => 'true',
  bestpath_routerid_ignore         => 'false',
}

os10_bgp_af{'trial_sub_conf':
  ensure                 => present,
  require                => Os10_bgp['trial_bgp_conf'],
  asn                    => '65537',
  ip_ver                 => 'ipv4',
  aggregate_address      => ['1.1.1.1/24 suppress-map SDF', '1.1.1.3/24'],
  dampening_state        => 'true',
  dampening_half_life    => '10',
  dampening_reuse        => '700',
  dampening_suppress     => '1000',
  dampening_max_suppress => '50',
  dampening_route_map    => 'TEST1',
  default_metric         => '75',
  network                => ['2.2.2.2/30 N1', '1.1.1.1/32', '3.3.3.3/32    TEST'],
  redistribute           => ['connected TEST1', 'static']
}

os10_bgp_neighbor{'testdc1':
  ensure                  => present,
  require                 => Os10_bgp['trial_bgp_conf'],
  asn                     => '65537',
  neighbor                => '1.1.1.3',
  type                    => 'ip',
  advertisement_interval  => '40',
  advertisement_start     => '50',
  timers                  => ['30', '40'],
  connection_retry_timer  => '70',
  remote_as               => '25.255',
  remove_private_as       => 'true',
  shutdown                => 'true',
  password                => '',
  send_community_standard => 'absent',
  send_community_extended => 'false',
  peergroup               => 'TEMP1',
  ebgp_multihop           => '100',
  fall_over               => 'true',
  local_as                => '1.255',
  route_reflector_client  => 'absent',
  weight                  =>  '120',
}

os10_bgp_neighbor{'temp1':
  ensure   => present,
  require  => Os10_bgp['trial_bgp_conf'],
  asn      => '65537',
  neighbor => 'TEMP1',
  type     => 'template',
  timers   => ['10', '20'],
}

os10_bgp_neighbor{'test2':
  ensure    => present,
  require   => [ Os10_bgp['trial_bgp_conf'], Os10_bgp_neighbor['temp1']],
  asn       => '65537',
  neighbor  => 'DERIVEDTEMPLATE',
  type      => 'template',
  timers    => ['30', '40'],
  peergroup => 'TEMP1',
}


os10_bgp_neighbor_af{'testdc1-af':
  ensure     => present,
  require    => Os10_bgp_neighbor['testdc1'],
  asn        => '65537',
  neighbor   => '1.1.1.3',
  type       => 'ip',
  ip_ver     => 'ipv4',
  activate   => 'true',
  allowas_in => '9',
}
