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
# Resource definition to configure a static route in OS10 operating system
# running in a Dell EMC Networking device.
# 
# Sample resource:
# 
#   os10_route{'route1':
#     destination   => '1.11.13.0',
#     prefix_len    => '16',
#     next_hop_list => ['127.0.0.2', 'interface ethernet1/1/1 255',
#                       'interface vlan3'],
#     ensure        => present,
#   }
# 
#   os10_route{'route2':
#     destination   => '2001::',
#     prefix_len    => '126',
#     next_hop_list => ['2000::1', '2000::2'],
#     ensure        => present,
#   }
# 

Puppet::Type.newtype(:os10_route) do
  desc 'os10_route resource type is used to manage static routes in OS10
  switches'

  ensurable

  newparam(:name, namevar: true) do
    desc 'Name of the route resource type. This namevar does not get updated to
    the device'
  end

  newparam(:destination) do
    desc 'Target IP address to which the route must be configured'
  end

  newparam(:prefix_len) do
    desc 'Netmask of the target IP address'
  end

  newproperty(:next_hop_list, array_matching: :all) do
    desc 'List of next hop IP address for the route to be configured'
    defaultto([])

    # We override insync? to handle the case when the NHL is in an unsorted
    # way and does not match the sequence as returned by provider
    def insync?(is)
      (is.size == should.size && is.sort == should.sort)
    end
  end
end
