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
# Resource definition for os10_bgp_neighbor that is used to apply neighbor sub-
# configuration on top of existing base bgp configuration in OS10 switches.
# 
# Sample resource:
#   os10_bgp_neighbor{'testdc1':
#     require  => Os10_bgp['trial_bgp_conf'],
#     ensure                  => present,
#     asn                     => '65537',
#     neighbor                => '1.1.1.3',
#     advertisement_interval  => '40',
#     advertisement_start     => '50',
#     timers                  => ['30', '40'],
#     connection_retry_timer  => '70',
#     remote_as               => '25.255',
#     remove_private_as       => 'absent',
#     shutdown                => 'true',
#     password                => 'absent',
#     send_community_standard => 'true',
#     send_community_extended => 'false',
#     peergroup               => 'TEMP1',
#     ebgp_multihop           => '100',
#     fall_over               => 'true',
#     local_as                => '1.255',
#     route_reflector_client  => 'absent',
#     weight                  => '120',
# 
#   os10_bgp_neighbor{'temp1':
#     require  => Os10_bgp['trial_bgp_conf'],
#     ensure   => present,
#     asn      => '65537',
#     neighbor => 'TEMP1',
#     type     => 'template',
#     timers   => ['20', '20'],
#   }
# 
#   os10_bgp_neighbor{'testdc2':
#     require   => [ Os10_bgp['trial_bgp_conf'], Os10_bgp_neighbor['template1']],
#     ensure    => present,
#     asn       => '65537',
#     type      => 'template',
#     timers    => ['20', '20'],
#     peergroup => 'TEMP1',
#   }
# 

require 'ipaddr'

Puppet::Type.newtype(:os10_bgp_neighbor) do
  desc 'os10_bgp_neighbor resource type is used to manage neighbor bgp sub-'\
  ' configuration on top of existing bgp configuration.'

  ensurable

  newproperty(:asn) do
    desc 'Autonomous System number of the bgp configuration. Valid values '\
    'are 1-4294967295 or 0.1-65535.65535'

    validate do |v|
      raise "Unrecognized value for asn #{v}" unless
                             /^(\d+|\d+\.\d+)$/.match(v.to_s)
    end

    munge do |v|
      l = v.split('.')
      if l.length == 2
        (l[0].to_i * 65536 + l[1].to_i).to_s
      else
        v
      end
    end
  end

  newparam(:neighbor, namevar: true) do
    desc 'Specify a neighbor router IP address or template name for the '\
    'given configuration. Valid values can be a valid ipv4 or ipv6 address '\
    'or string with maximum of 16 characters.'
  end

  newproperty(:type) do
    desc 'Specify whether the configuration is for neighbor ip or template.'

    newvalues(:ip, :template)
  end

  newproperty(:advertisement_interval) do
    desc 'Minimum interval between sending BGP routing updates'
  end

  newproperty(:advertisement_start) do
    desc 'Delay initiating OPEN message for the specified time'
  end

  newproperty(:timers, array_matching: :all) do
    desc 'Array of two timer values. Keepalive interval and Holdtime values'

    # We shouldn't sort the array, because the array index is significant
    def insync?(is)
      is == should
    end
  end

  newproperty(:connection_retry_timer) do
    desc 'Configure peer connection retry timer.'
  end

  newproperty(:remote_as) do
    desc 'Specify autonomous system number of the BGP neighbor'

    validate do |v|
      raise "Unrecognized value for remote_as #{v}" unless
                             v.empty? ||
                             /^(\d+|\d+\.\d+)$/.match(v.to_s)
    end

    munge do |v|
      l = v.split('.')
      if l.length == 2
        (l[0].to_i * 65536 + l[1].to_i).to_s
      else
        v
      end
    end
  end

  newproperty(:remove_private_as) do
    desc 'Enables or disables configuration to remove private AS number'\
         ' from outbound updates.'

    newvalues(:absent, :true, :false)

    # Generate insync? method which will compare considering false as default
    Utils::Codegen.mk_insync(self, :false)
  end

  newproperty(:shutdown) do
    desc 'Set the shutdown state of the neighbor.'

    newvalues(:absent, :true, :false)

    # Generate insync? method which will compare considering true as default
    Utils::Codegen.mk_insync(self, :true)
  end

  newproperty(:password) do
    desc 'Set MD5 password for authentication with maximum of 128 characters.'

    # 'absent' cannot be a valid password, because absent is considered as a
    # way to remove the password CLI.
    validate do |v|
      raise "Invalid password #{v}" unless v.length <= 128
    end

    # Generate insync? method which will compare considering '' as default
    Utils::Codegen.mk_insync(self, '')
  end

  newproperty(:send_community_standard) do
    desc 'Enables or disables sending standard community attribute.'

    newvalues(:absent, :true, :false)

    # Generate insync? method which will compare considering false as default
    Utils::Codegen.mk_insync(self, :false)
  end

  newproperty(:send_community_extended) do
    desc 'Enables or disables sending extended community attribute.'

    newvalues(:absent, :true, :false)

    # Generate insync? method which will compare considering false as default
    Utils::Codegen.mk_insync(self, :false)
  end

  newproperty(:peergroup) do
    desc 'Configures neighbor to BGP peer-group. Inherit configuration of '\
    'peer-group template. The template should be an existing configuration.'

    validate do |v|
      raise "Invalid peergroup name #{v}" unless v.length <= 16
    end
  end

  newproperty(:ebgp_multihop) do
    desc 'Configures the maximum-hop count value allowed in eBGP neighbors '\
     'that are not directly connected. This takes an integer value between '\
     '1-255.'

    validate do |v|
      raise "Invalid ebpg_multihop value #{v}" unless v.empty? || 
                                                      (v.to_i >= 1 &&
                                                      v.to_i <= 255)
    end
  end

  newproperty(:fall_over) do
    desc 'Configures the session fall on peer-route loss.'

    newvalues(:absent, :true, :false)
    # Generate insync? method which will compare considering false as default
    Utils::Codegen.mk_insync(self, :false)
  end

  newproperty(:local_as) do
    desc 'Configure local autonomous system number for the BGP peer.'

    validate do |v|
      raise "Unrecognized value for local_as #{v}" unless
                             v.empty? ||
                             /^(\d+|\d+\.\d+)$/.match(v.to_s)
    end

    munge do |v|
      l = v.split('.')
      if l.length == 2
        (l[0].to_i * 65536 + l[1].to_i).to_s
      else
        v
      end
    end
  end

  newproperty(:route_reflector_client) do
    desc 'Configures a BGP neighbor as route reflector client.'

    newvalues(:absent, :true, :false)
    # Generate insync? method which will compare considering false as default
    Utils::Codegen.mk_insync(self, :false)
  end

  newproperty(:weight) do
    desc 'Configure default weight for routes from the neighbor interface. '\
      'Value can be between 1-4294967295.'

    validate do |v|
      raise "Invalid weight #{v}" unless v.empty? || 
                                         (v.to_i >= 1 && 
                                          v.to_i <= 4294967295)
    end
  end

  # Inter-properties validation
  validate do
    # Validate template name
    if self[:type] == :template
      raise "Invalid neighbor template name #{self[:neighbor]}" unless
                                              self[:neighbor].length <= 16

      raise "Template #{self[:neighbor]} can't have shutdown property" unless
                                             !(self[:shutdown])
    else
      begin
        IPAddr.new(self[:neighbor])
      rescue IPAddr::Error
        raise "Invalid neighbor ip address #{self[:neighbor]}"
      end
    end
  end
end
