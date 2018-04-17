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
# Resource Definition for os10_bgp_af that is used to configure address family
# values in bgp configuration in OS10 switches. The address family configuraion
# gets applied to the bgp configuration with matching autonomous system number.
# Therefore it is mandatory to provide autonomous system number in address family
# configuration. Currently OS10 supports only one instance of bgp configuration.
# 
# Sample resource:
# 
#   os10_bgp_af{'trial_sub_conf':
#     require                => Os10_bgp['trial_bgp_conf'],
#     ensure                 => present,
#     asn                    => '65537',
#     ip_ver                 => 'ipv4',
#     aggregate_address      => ['1.1.1.1/24 suppress-map SDF', '1.1.1.3/24'],
#     dampening_state        => 'true',
#     dampening_half_life    => '10',
#     dampening_reuse        => '700',
#     dampening_suppress     => '1000',
#     dampening_max_suppress => '50',
#     dampening_route_map    => 'TEST1',
#     default_metric         => '75',
#     network                => ['2.2.2.2/30 N1', '1.1.1.1/32', '3.3.3.3/32    TEST'],
#     redistribute           => ['connected TEST1', 'static']
#   }

Puppet::Type.newtype(:os10_bgp_af) do
  desc 'os10_bgp_af resource type is used to manage ipv4 or ipv6 address '\
  'family configurations in OS10 bgp configuration.'

  ensurable

  newparam(:name, namevar: true)

  newparam(:asn) do
    desc 'Autonomous System number of the bgp configuration. Valid values
    are 1-4294967295 or 0.1-65535.65535'

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

  newproperty(:ip_ver) do
    desc 'Configures the IP version of this instance of address family
          configuration. Valid values are ipv4 and ipv6.'

    validate do |v|
      raise "Invalid ip address version #{v}" unless !v.empty? &&
                                                    (v.casecmp('ipv4').zero? ||
                                                     v.casecmp('ipv6').zero?)
    end
    newvalues(:ipv4, :ipv6)

    munge(&:downcase)
  end

  newproperty(:aggregate_address, array_matching: :all) do
    desc 'Configures ipv4/ipv6 BGP aggregate address and mask. The values
    should be of the same version as provided in ip_ver parameter.'

    def insync?(is)
      (is.size == should.size) && (is.sort == should.sort)
    end

    validate do |v|
    end
  end

  newproperty(:dampening_state) do
    desc 'Enable or disable route-flap dampening. When dampening_state is '\
    'true all the timers should be defined.'

    newvalues(:absent, :true, :false)
  end

  newproperty(:dampening_half_life) do
    desc 'Set dampening half-life time for the penalty. Valid values are '\
         '1-45.'

    validate do |v|
      raise "Invalid dampening half-life time #{v}." unless (v.to_i >= 1) &&
                                                            (v.to_i <= 45)
    end
  end

  newproperty(:dampening_reuse) do
    desc 'Set time value to start reusing a route. Valid values are 1-20000.'

    validate do |v|
      raise "Invalid dampening reuse time #{v}." unless (v.to_i >= 1) &&
                                                        (v.to_i <= 20000)
    end
  end

  newproperty(:dampening_suppress) do
    desc 'Set time value to start suppressing a route. Valid values are '\
         '1-20000.'

    validate do |v|
      raise "Invalid dampening suppress time #{v}." unless (v.to_i >= 1) &&
                                                           (v.to_i <= 20000)
    end
  end

  newproperty(:dampening_max_suppress) do
    desc 'Set maximum time duration to suppress a stable route. Valid values'\
         ' are 1-255.'

    validate do |v|
      raise "Invalid dampening max suppress time #{v}." unless (v.to_i >= 1) &&
                                                               (v.to_i <= 255)
    end
  end

  newproperty(:dampening_route_map) do
    desc 'Name of route-map to specify criteria for dampening. Valid value '\
         'is a string with a maximum of 140 characters.'

    validate do |v|
      raise "Invalid dampening route map value #{v}." unless v.length <= 140
    end
  end

  newproperty(:default_metric) do
    desc 'Set default metric of redistributed routes. Valid value is in the '\
         'range 1-4294967295'

    validate do |v|
      raise "Invalid default metric #{v}." unless ((v.to_i >= 1) &&
                                                  (v.to_i <= 4294967295)) ||
                                                   v.empty?
    end
  end

  newproperty(:network, array_matching: :all) do
    desc 'List of IPs and mask along with optional routemap string.'

    def insync?(is)
      (is.length == should.length) && (is.sort == should.sort)
    end

    munge do |v|
      # If there are more than one 'spaces' between network address and route
      # map, we will clean them up here.
      l = v.split(' ')
      "#{l[0]} #{l[1]}".strip
    end

    validate do |v|
    end
  end

  newproperty(:redistribute, array_matching: :all) do
    desc 'Configures routing protocols that need to be redistributed. Valid'\
         ' value is a list of (protocol value). Protocol can be '\
         'connected / ospf / static. Value can be blank or routemap string '\
         'incase of connected / static and blank or process-id incase of ospf.'

    munge do |v|
      # Trim unwanted spaces
      l = v.split(' ')
      "#{l[0]} #{l[1]}".strip
    end

    def insync?(is)
      (is.length == should.length) && (is.sort == should.sort)
    end

    validate do |v|
    end
  end

  # Do cross validation of parameters of the entire resource here
  validate do
    # Aggregate address format should match ip version
  end
end
