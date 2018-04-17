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
# Resource definition for managing SNMP coniguration in OS10 operating system
# running in a Dell EMC Networking device.
# 
# Sample configuration:
#
# os10_snmp{'snmpconf':
#   contact           => 'dellforce10@dell.com',
#   location          => 'OTP1',
#   community_strings => {'public'=>'ro', 'private'=>'ro','general'=>'ro'},
#   enabled_traps     => {'envmon'=>['fan','power-supply'],
#                         'snmp'=>['linkdown','linkup']},
#   trap_destination  => {'10.1.1.1:12'=>['v1','public'],
#                            '10.2.2.2:123'   => ['v1','password']}
# }

Puppet::Type.newtype(:os10_snmp) do
  desc 'os10_snmp resource type is to used to manage SNMP configuration in
        OS10 EE switches'

  newparam(:name, namevar: true) do
    desc 'The name parameter for SNMP resource. This will not be used in any
          configuration'
  end

  newproperty(:community_strings) do
    desc "This property is a dictionary of community string with its access
          right. These will be the only list of community string entries
          prsent in the SNMP configuration. eg:
          {'public'=>'ro', 'private'=>'rw'}"
  end

  newproperty(:contact) do
    desc 'Contact property of SNMP server. There can be only one
          entry for contact. An empty string for contact will remove the
          contact entry from the SNMP configuration.'
  end

  newproperty(:location) do
    desc 'Location property of the SNMP server. There can be only one
          entry for location. An empty string for location will remove the
          location entry '
  end

  newproperty(:enabled_traps) do
    desc 'This will be a dictionary of entries where the key is trap
          category and values are the list of subcategory or :all to enable
          traps for all sub category items'

    # Do minimal munging here as OS10 trap list will keep growing with
    # releases
    # The sub options list will need to be sorted here as the provider
    # returns the sub options list as a sorted one.
    munge do |value|
      # This will sort the values in each element of the hash
      value.update(value) do |_k, v|
        v.map!(&:downcase)
        v.sort
      end
    end
  end

  newproperty(:trap_destination) do
    desc 'This will be a dictionary of entries where the key is list of
    [ip,Port] and value is a list with version string ("v1"/"v2") and
    community string'
  end
end
