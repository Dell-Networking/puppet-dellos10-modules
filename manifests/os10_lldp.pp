# Sample manifest file for os10_lldp resource

os10_lldp { 'lldpconf':
  holdtime_multiplier         => '3',
  reinit                      => '4',
  timer                       => '5',
  enable                      => 'true',
  med_fast_start_repeat_count => '6',
  med_network_policy          => [{'id'        =>'8',
                                    'app'      =>'voice',
                                    'vlan'     =>'3',
                                    'vlan-type'=>'tag',
                                    'priority' =>'3',
                                    'dscp'     =>'4'}]
}
