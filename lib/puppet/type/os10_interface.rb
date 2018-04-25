# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# Author::     Balaji Thope Janakiram (balaji_janakiram@dell.com)
# Copyright::  Copyright (c) 2018, Dell Inc. All rights reserved.
# License::    [Apache License] (http://www.apache.org/licenses/LICENSE-2.0)
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Resource definition for the os10_interface type that is used to configure
# interfaces in Dell EMC Networking devices running os10 operating system.
# 
# Sample definition:
# 
# os10_interface{'ethernet 1/1/12':
#   desc            => 'Interface reconfigured by puppet',
#   mtu             => '3005',
#   switchport_mode => 'false',
#   admin           => 'up',
#   ip_address      => '192.168.1.2/24',
#   ipv6_address    => '2001:4898:5808:ffa2::5/126',
#   ipv6_autoconfig => 'true',
#   ip_helper       => ['10.0.0.4'],
# }

Puppet::Type.newtype(:os10_interface) do
  desc 'os10_interface resource type is used to manage interface '\
  'configuration  in OS10 switches'

  newparam(:name, namevar: true) do
    desc 'Name of the interface that requires configuring. This should '
    'be a valid OS10 interface.'
  end

  newproperty(:desc) do
    desc 'String containing description of the interface.'
  end

  newproperty(:mtu) do
    desc 'String containing Maximum Transmission Unit of the interface.'
  end

  newproperty(:switchport_mode) do
    desc 'Switchport mode of the interface. Can be either trunk or access '\
    'in case of switchport. Or can be false when not in L2 mode.'

    newvalues(:trunk, :access, :false)

    # It should be noted that validate method gets called before munge
    validate do |v|
      # Switchport mode can be trunk or access (L2) only if there is no ip
      # address provided. If there is an IP address existing in the
      # configuration, it will be cleared by the provider code.
      if v == :access || v == :trunk
      end
    end
  end

  newproperty(:admin) do
    desc 'Administrative state of the interface. Can be up or down.'

    newvalues(:up, :down)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:ip_address) do
    desc 'String containing ipv4 address and mask in ip/prefixlen format.'

    validate do |v|
      begin
        ipadd = IPAddr.new(v.to_s)
        raise "Invalid ipv4 address #{v}" unless ipadd.ipv4?
      rescue IPAddr::Error
        raise "Invalid ip_address #{v}"
      end
    end
  end

  newproperty(:ipv6_address) do
    desc 'String containing ipv4 address and mask in ip/prefixlen format.'

    validate do |v|
      begin
        ipadd = IPAddr.new(v.to_s)
        raise "Invalid ipv6 address #{v}" unless ipadd.ipv6?
      rescue IPAddr::Error
        raise "Invalid ipv6_address #{v}"
      end
    end
  end

  newproperty(:ipv6_autoconfig) do
    desc 'Boolean value to enable or disable ipv6 autoconfig.'

    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:ip_helper, array_matching: :all) do
    desc 'List containing string of IP address for the interface to which'\
    ' UDP broadcasts need to be forwarded.'

    # We override insync? to handle the case when the NHL is in an unsorted
    # way and does not match the sequence as returned by provider
    def insync?(is)
      (is.size == should.size && is.sort == should.sort)
    end
  end

  # We can do cross-validateion of parameters for the given resource here.
  validate do
    # Do switchport_mode validation
    failmode = false
    if self[:switchport_mode] == 'access' || self[:switchport_mode] == 'trunk'
      failmode = true if !self[:ip_address].nil? && !self[:ip_address].empty?

      failmode = true if !self[:ipv6_address].nil? &&
                         !self[:ipv6_address].empty?

      failmode = true if !self[:ipv6_autoconfig].nil? &&
                         !self[:ipv6_autoconfig].empty?

      failmode = true if !self[:ip_helper].nil? && !self[:ip_helper].empty?
    end

    raise 'Invalid combination of switchport_mode and ip config' if failmode
  end
end
