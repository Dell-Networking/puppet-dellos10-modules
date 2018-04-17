# Sample manifest file for os10_itnerface resource

os10_interface{'ethernet 1/1/12':
  desc            => 'Interface reconfigured by puppet',
  mtu             => '3005',
  switchport_mode => 'false',
  admin           => 'up',
  ip_address      => '192.168.1.2/24',
  ipv6_address    => '2001:4898:5808:ffa2::5/126',
  ipv6_autoconfig => 'true',
  ip_helper       => ['10.0.0.4'],
}
