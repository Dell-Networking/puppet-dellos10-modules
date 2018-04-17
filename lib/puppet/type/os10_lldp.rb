# Sample definition for os10_lldp resource:

# os10_lldp { 'lldpconf':
#   holdtime_multiplier => '3',
#   reinit              => '4',
#   timer               => '5',
#   enable              => 'true',
#   med_fast_start_repeat_count => '6',
#   med_network_policy => [{"id"=>'8', "app"=>"voice", "vlan"=>"3",
#                         "vlan-type"=> "tag", "priority"=>"3",
#                         "dscp"=>"4"}, {"id"=>'7', "app"=>"voice",
#                         "vlan"=>"5", "vlan-type"=> "tag",
#                         "priority"=>"3", "dscp"=>"4"}]
# }

Puppet::Type.newtype(:os10_lldp) do
  desc 'os10_lldp resource type is to used to manage LLDP configuration in
        OS10 EE switches'

  newparam(:name, namevar: true) do
    desc 'The name parameter for lldp resource. This will not be used in any
          configuration'
  end

  newproperty(:holdtime_multiplier) do
    desc 'Holdtime multipler value property of type string of LLDP
          Value with a range of <2-10>, empty string
          would remove the existing value'
  end

  newproperty(:reinit) do
    desc 'Reinit property of LLDP in seconds of type string,
          Value with a range <1-10>, empty string
          would remove the existing value'
  end

  newproperty(:timer) do
    desc 'Timer property of LLDP in seconds of type string
          Value with a range of <5-254>, empty string
          would remove the existing value'
  end

  newproperty(:med_fast_start_repeat_count) do
    desc 'Med fast start repeat count value property of type string of LLDP
          Value with a range of <1-10>, empty string
          would remove the existing value'
  end

  newproperty(:enable, boolean: true) do
    desc 'This property is a boolean value specifying
          whether to enable or disable lldp globally'

    newvalues(:true, :false)

    def insync?(is)
      info "is is #{is} of type #{is.class}"
      info "should is #{should} of type #{should.class}"
      is.to_s == should.to_s
    end

    munge do |v|
      notice "value is #{v} of type #{v.class}"
      @resource.munge_boolean(v)
    end
  end

  # We munge the boolean should values to string, because Puppet framework would
  # skip calling in_sync? if should is boolean false. This may be a bug in
  # Puppet. In the provider code we check for 'true'/'false' instead of boolean
  # true/false.
  def munge_boolean(value)
    case value
    when true, 'true', :true
      'true'
    when false, 'false', :false
      'false'
    else
      raise "Invalid value for munge_boolean #{value}"
    end
  end

  newproperty(:med_network_policy, array_matching: :all) do
    desc 'This will be a array of hash entries for network_policy
          id<1-32>, app, vlan_id<1-4093>, vlan_type<tag/untag>,
          priority<0-7>, dscp<0-63>'

    def insync?(isv)
      info "is value is #{isv} of type #{isv.class}"
      info "should is #{should} of type #{should.class}"
      isv == should
    end
  end
end
