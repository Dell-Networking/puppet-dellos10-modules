# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# Author::     Neil Hemingway (neil.hemingway@greyhavens.org.uk)
# Copyright::  Copyright (c) 2018, Dell Inc. All rights reserved.
# License::    [Apache License] (http://www.apache.org/licenses/LICENSE-2.0)
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Resource definition for managing NTP configuration in OS10 operating system
# running in a Dell EMC Networking device.
#
# Sample configuration:
#
# os10_ntp_server {'time.domain.com':
#   ensure => present,
#   key    => 123,
#   prefer => true,
# }

require 'puppet/property/boolean'

Puppet::Type.newtype(:os10_ntp_server) do
  desc 'os10_ntp_server resource type is to used to manage NTP servers in
        OS10 EE switches'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name parameter for the NTP server.  This will be used as the
          address of the NTP server'
    munge do |value|
      value.downcase
    end
    def insync?(is)
      is.downcase == should.downcase
    end
  end

  newproperty(:prefer, :boolean => true, :parent => Puppet::Property::Boolean) do
    desc 'This property is a boolean value specifying whether the ntp server
          will be preferred. This is an optional attribute defaulted to false.'

    defaultto false
  end

  newproperty(:key) do
    desc 'This property is an integer specifying the key to use for the ntp server.
          This is an optional attribute and will be omitted if not present.'

    newvalues(/^\d+$/)
  end
end
