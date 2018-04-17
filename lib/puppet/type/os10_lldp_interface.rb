# Sample definition for os10_lldp_interface resource:

# os10_lldp_interface { 'ethernet 1/1/1':
#   receive                  => 'true',
#   transmit                 => 'true',
#   med                      => 'true',
#   med_network_policy       => ["7", "8"],
#   med_tlv_select_inventory => 'false',
#   med_tlv_select_network_policy => 'true',
#   tlv_select              => {"dcbxp"=>[""],"dot1tlv"=>["link-aggregation"],
#                              "dot3tlv"=>["max-framesize"]}
# }

Puppet::Type.newtype(:os10_lldp_interface) do
  desc 'os10_lldp_interface resource type is to used to manage per interface
        LLDP configuration in OS10 EE switches'

  newparam(:name, namevar: true) do
    desc 'The name parameter for lldp interface resource.
          This will not be used in any configuration'
  end

  newproperty(:interface_name) do
    desc 'Name of the interface
           Ex: ethernet 1/1/1'
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
    
  newproperty(:receive, boolean: true) do
    desc 'This property is a boolean value specifying whether to enable or
          disable lldp receive for the interface'

    newvalues(:true, :false)

    def insync?(isv)
      info "is value is #{isv} of type #{isv.class}"
      info "should is #{should} of type #{should.class}"
      isv.to_s == should.to_s
    end

    munge do |v|
      notice "value is #{v} of type #{v.class}"
      @resource.munge_boolean(v)
    end
  end

  newproperty(:transmit, boolean: true) do
    desc 'This property is a boolean value specifying whether to enable or
          disable lldp transmit for the interface'

    newvalues(:true, :false)

    def insync?(isv)
      info "is value is #{isv} of type #{isv.class}"
      info "should is #{should} of type #{should.class}"
      isv.to_s == should.to_s
    end

    munge do |v|
      notice "value is #{v} of type #{v.class}"
      @resource.munge_boolean(v)
    end
  end

  newproperty(:med, boolean: true) do
    desc 'This property is a boolean value specifying whether to enable or
          disable lldp med for the interface'

    newvalues(:true, :false)

    def insync?(isv)
      info "is value is #{isv} of type #{isv.class}"
      info "should is #{should} of type #{should.class}"
      isv.to_s == should.to_s
    end

    munge do |v|
      notice "value is #{v} of type #{v.class}"
      @resource.munge_boolean(v)
    end
  end

  newproperty(:med_tlv_select_inventory, boolean: true) do
    desc 'This property is a boolean value specifying whether to enable or
          disable lldp med tlv select inventory for the interface'

    newvalues(:true, :false)

    def insync?(isv)
      info "is value is #{isv} of type #{isv.class}"
      info "should is #{should} of type #{should.class}"
      isv.to_s == should.to_s
    end

    munge do |v|
      notice "value is #{v} of type #{v.class}"
      @resource.munge_boolean(v)
    end
  end

  newproperty(:med_tlv_select_network_policy, boolean: true) do
    desc 'This property is a boolean value specifying whether to enable or
          disable lldp med tlv select network policy for the interface'

    newvalues(:true, :false)

    def insync?(isv)
      info "is value is #{isv} of type #{isv.class}"
      info "should is #{should} of type #{should.class}"
      isv.to_s == should.to_s
    end

    munge do |v|
      notice "value is #{v} of type #{v.class}"
      @resource.munge_boolean(v)
    end
  end

  newproperty(:med_network_policy, array_matching: :all) do
    desc 'This will be a array of network policy id
          id<1-32>'

    def insync?(isv)
      info "is value is #{isv} of type #{isv.class}"
      info "should is #{should} of type #{should.class}"
      isv == should
    end
  end

  newproperty(:tlv_select) do
    desc 'This will be a hash of key value pair with lldp tlv select option as
          key and sub option as values, the tlv_select in the device is enabled
          by default, so the new given configuration will disable the
          specified tlv-select options'

    def insync?(isv)
      info "is value is #{isv} of type #{isv.class}"
      info "should is #{should} of type #{should.class}"
      isv == should
    end
  end
end
