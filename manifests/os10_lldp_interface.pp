# Sample manifest file for os10_lldp_interface resource

 os10_lldp_interface { 'ethernet 1/1/1':
   receive                  => 'true',
   transmit                 => 'true',
   med                      => 'true',
   med_network_policy       => ["7", "8"],
   med_tlv_select_inventory => 'false',
   med_tlv_select_network_policy => 'true',
   tlv_select              => {"dcbxp"=>[""],"dot1tlv"=>["link-aggregation"],
                              "dot3tlv"=>["max-framesize"]}
}
