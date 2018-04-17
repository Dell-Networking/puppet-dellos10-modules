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
# Resource type definition for configuring an os10 monitor session in Dell EMC
# Networking device.
#
# Sample definition:
#
# os10_monitor{'session1':
#   id          => 1,
#   source      => ['ethernet 1/1/7', 'ethernet 1/1/8'],
#   destination => 'ethernet 1/1/10',
#   flow_based  => false,
#   shutdown    => false,
#   ensure      => present,
# }

Puppet::Type.newtype(:os10_monitor) do
  desc 'os10_monitor resource type is to used to manage port monitor
        (mirroring) session configuration in OS10 EE switches'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name parameter for the monitor resource. This can be
    any string to uniquely identify the monitoring resource in a manifest.
    This value will not be used in any configuration'
  end

  newparam(:id) do
    desc "This property is an integer that is configured as the id of the
    monitor session in the switch. The id needs to be unique and should be an
    integer between 1 and 18."

    validate do |value|
      unless (Integer(value) >= 1) && (Integer(value) <= 18)
        raise "Invalid value of id: #{value}"
      end
    end

    munge do |v|
      Integer v
    end
  end

  newproperty(:source, array_matching: :all) do
    desc "This property is an array of string values of the interfaces that
    will be configured as source interfaces for this monitoring session.
    eg) ['ethernet 1/1/9', 'ethernet 1/1/10']"

    def insync?(is)
      info "is is #{is} of type #{is.class}"
      info "should is #{should} of type #{should.class}"
      is.sort == should.sort
    end

    munge do |value|
      info "value is #{value} of type #{value.class}"
      value
    end
  end

  newproperty(:destination) do
    desc "This property is a string name of the destination interface to which
    traffic has to be mirrored.
    eg) 'ethernet 1/1/10'"
  end

  newproperty(:flow_based, boolean: true) do
    desc "This property is a boolean value specifying whether to enable or
    disable flow based monitoring. This is an optional attribute defaulted to
    false."

    defaultto false
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

  # We munge the boolean should values to string
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

  newproperty(:shutdown) do
    desc "This property will decide whether to enable or disable the monitor
    session. If the shutdown is false, the session will be configured but in
    shutdown state. This is an optional attribute defaulted to true."

    defaultto true

    def insync?(is)
      info "is is #{is} of type #{is.class}"
      info "should is #{should} of type #{should.class}"
      is.to_s == should.to_s
    end

    munge do |v|
      notice "value is #{v} of type #{v.class}"
      @resource.munge_boolean(v)
    end

    newvalues(true, false)
  end
end
