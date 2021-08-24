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
# os10_privilege { "$mode:$priv_level:$command": }

Puppet::Type.newtype(:os10_privilege) do
  desc 'os10_privilege resource type is to used to manage privilege levels in
        OS10 EE switches'

  ensurable

  newparam(:name) do
    desc 'The ephemeral name of the resource.'
  end

  newproperty(:mode, namevar: true) do
    desc 'The privilege mode used to access CLI modes.'

    newvalues('exec', 'configure', 'interface', 'route-map', 'router', 'line')
  end

  newproperty(:priv_level, namevar: true) do
    desc 'An integer specifying the privilege level to use for the account.'

    munge do |value|
      info("Munging priv_level #{value} (#{value.class})")
      case value
      when Integer
        raise ArgumentError, 'priv_level must be an integer between 1-15 (inclusive)' unless 1 <= value and value <= 15
        return value
      when String
        if value =~ /^\d+$/
          int_value = value.to_i
          raise ArgumentError, 'priv_level must be an integer between 1-15 (inclusive)' unless 1 <= int_value and int_value <= 15
          return int_value
        else
          raise Puppet::Error, _("The priv_level specification is invalid: %{value}") % { value: value.inspect }
        end
      else
        raise Puppet::Error, _("The priv_level specification is invalid: %{value}") % { value: value.inspect }
      end
    end
  end

  newproperty(:command, namevar: true) do
    desc 'The command to be supported at the privilege level.'
  end

  newproperty(:permit_param, namevar: true) do
    desc 'The command parameter to be supported at the privilege level.'
  end

  def self.title_patterns
    [
      [
        /^(([^:]+):([^:]+):(\S+)\s(.*))$/,
        [
          [ :name ],
          [ :mode ],
          [ :priv_level ],
          [ :command ],
          [ :permit_param ],
        ]
      ],
      [
        /(.*)/,
        [
          [ :name ],
        ]
      ]
    ]
  end
end
