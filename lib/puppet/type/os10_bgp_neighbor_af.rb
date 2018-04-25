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
# Resource definition for os10_bgp_neighbor_af that is used to configure address
# family sub-configuration (for both ipv4 and ipv6) under bgp neighbor sub-
# configuration.
# 
# Sample resource:
# 
#   os10_bgp_neighbor_af{'testdc1-af':
#     require    => Os10_bgp_neighbor['testdc1'],
#     ensure     => present,
#     asn        => '65537',
#     neighbor   => '1.1.1.3',
#     type       => 'ip',
#     ip_ver     => 'ipv4',
#     activate   => 'true',
#     allowas_in => '9',
#   }
# 
#   os10_bgp_neighbor_af{'TEMP1-af':
#     require    => Os10_bgp_neighbor['testdc1'],
#     ensure     => present,
#     asn        => '65537',
#     neighbor   => 'TEMP1',
#     type       => 'template',
#     ip_ver     => 'ipv4',
#     activate   => 'true',
#   }

Puppet::Type.newtype(:os10_bgp_neighbor_af) do
  desc 'os10_bgp_neighbor_af resource type is used to manage address family '\
  'sub-configuration under neighbor sub-configuration of bgp configuration.'

  ensurable

  newparam(:name, :namevar => true)

  newparam(:asn) do
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

  newparam(:neighbor) do
    desc 'The neighbor route IP address to which the current address family '\
    'sub-configuration.'
  end

  newparam(:type) do
    desc 'Specify whether the neighbor configuration is of type ip or template.'

    newvalues(:ip, :template)
  end

  newparam(:ip_ver) do
    desc 'Configures either ipv4 or ipv6 address family'

    newvalues(:ipv4, :ipv6)
  end

  newproperty(:activate) do
    desc 'Enable the Address Family for this Neighbor.'

    newvalues(:absent, :true, :false)

    # Generate insync? method which will compare considering true as default
    Utils::Codegen.mk_insync(self, :true)
  end

  newproperty(:allowas_in) do
    desc 'Configure allowed local AS number in as-path. Valid values are 1-10.'
  end
end
