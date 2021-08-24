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
# os10_user {'my_username':
#   ensure       => present,
#   password     => 'my_secret_password',
#   role         => 'netadmin',
#   priv_level   => 15,
#   ssh_key_type => key,
#   ssh_key      => 'ssh-rsa jhghgdjhgdjvgjvgh',
# }

def randomPassword
  alphabet = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
  32.times.map { alphabet[rand(alphabet.length)] }.join
end

Puppet::Type.newtype(:os10_user) do
  desc 'os10_ntp_server resource type is to used to manage NTP servers in
        OS10 EE switches'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name parameter for the user.'
  end

  newparam(:password) do
    desc 'If set, this value will be used as the new password. This is an
          optional attribute defaulted to a random value.  Note: this only takes
          effect when a user is created, as it is not possible to capture the
          current value in order to know if it needs to be changed.'

    defaultto(randomPassword())
  end

  newproperty(:role) do
    desc 'One of "netoperator", "netadmin", "secadmin", "sysadmin".'

    newvalues('netoperator', 'netadmin', 'secadmin', 'sysadmin')
  end

  newproperty(:priv_level) do
    desc 'An integer specifying the privilege level to use for the account.'

    validate do |value|
      raise ArgumentError, 'priv_level must be an integer between 1-15 (inclusive)' unless value.kind_of?(Integer) and 1 <= value and value <= 15
    end
  end

  newproperty(:ssh_key) do
    desc 'This property is a boolean value specifying whether the ntp server
          will be preferred. This is an optional attribute defaulted to false.'

    newvalues(/^ssh-rsa /)
  end

  newproperty(:ssh_key_type) do
    desc 'Whether the ssh_key value is a key or a reference to an on-disk file.
          It is the user\'s responsibility to create such a file.'

    newvalues(:file, :key)
  end
end
