# Sample manifest file for os10_snmp resource

os10_snmp{'snmpconf':
  contact           => 'dellforce10@dell.com',
  location          => 'OTP1',
  community_strings => {'public'=>'ro', 'private'=>'ro','general'=>'ro'},
  enabled_traps     => {'envmon' =>['fan','power-supply'],
                        'snmp'   =>['linkdown','linkup']},
  trap_destination  => {'10.1.1.1:12'  =>['v1','public'],
  '10.2.2.2:123'  => ['v1','password']}
}

