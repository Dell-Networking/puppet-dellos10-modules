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
# Resource Definition for os10_bgp that is used to configure base bgp
# configuration in OS10 switches.
# 
# Sample resource:
# 
#   os10_bgp{'trial_bgp_conf':
#     ensure                           => present,
#     asn                              => '65537',
#     router_id                        => '10.10.10.10',
#     max_path_ebgp                    => '11',
#     max_path_ibgp                    => '',
#     graceful_restart                 => 'absent',
#     log_neighbor_changes             => 'true',
#     fast_external_fallover           => 'true',
#     always_compare_med               => 'false',
#     default_loc_pref                 => '22',
#     confederation_identifier         => '3',
#     confederation_peers              => [2,33,4],
#     route_reflector_client_to_client => 'false',
#     route_reflector_cluster_id       => '1.1.1.1',
#     bestpath_as_path                 => 'ignore',
#     bestpath_med_confed              => 'true',
#     bestpath_med_missing_as_worst    => 'true',
#     bestpath_routerid_ignore         => 'absent',
#   }

module Utils
  class Codegen
    # This is a generator method which will add insync? code to the given klass
    # instance which defaults to the provided "def_val" if either IS is :absent
    # or SHOULD is :absent
    def self.mk_insync(klass, def_val)
      klass.instance_eval do
        define_method('insync?') do |is|
          # If either IS or SHOULD is :absent, we compare IS and SHOULD against
          # their default values taking place of :absent
          my_is = is.to_s == 'absent' ? def_val : is
          my_should = should.to_s == 'absent' ? def_val : should

          debug "insync? #{is}==#{should} returning "\
                "#{my_is.to_s == my_should.to_s}"

          my_is.to_s == my_should.to_s
        end

        define_method('munge') do |v|
          v = def_val if v.to_s == 'absent'
          v.to_s
        end
      end
    end
  end
end

Puppet::Type.newtype(:os10_bgp) do
  desc 'os10_bgp resource type is used to manage bgp configuration '\
  'in OS10 switches'

  ensurable

  newparam(:asn, namevar: true) do
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

  newproperty(:router_id) do
    desc 'Configures the IP address of the local BGP router instance.'

    validate do |v|
      begin
        IPAddr.new(v.to_s)
      rescue IPAddr::Error
        raise "Invalid router_id #{v}"
      end
    end
  end

  newproperty(:max_path_ebgp) do
    desc 'Configures the maximum number of paths to forward packets through
          eBGP. Valid values are 1-64.'

    validate do |v|
      raise "Invalid max_path_ebgp #{v}" unless v.empty? ||
                                               ((Integer(v) > 1) &&
                                                (Integer(v) < 64))
    end
  end

  newproperty(:max_path_ibgp) do
    desc 'Configures the maximum number of paths to forward packets through
          iBGP. Valid values are 1-64.'

    validate do |v|
      raise "Invalid max_path_ibgp #{v}" unless v.empty? ||
                                               ((Integer(v) > 1) &&
                                                (Integer(v) < 64))
    end
  end

  newproperty(:graceful_restart) do
    desc 'Configures graceful restart capability.'

    newvalues(:absent, :true, :false)

    # Generate insync? method which will compare considering false as default
    Utils::Codegen.mk_insync(self, :false)
  end

  newproperty(:log_neighbor_changes) do
    desc 'Configures logging of neighbors up/down.'

    newvalues(:absent, :true, :false)

    # Generate insync? method which will compare considering true as default
    Utils::Codegen.mk_insync(self, :true)
  end

  newproperty(:fast_external_fallover) do
    desc 'Configures reset session if a link to a directly connected external
          peer goes down.'

    newvalues(:absent, :true, :false)

    # Generate insync? method which will compare considering true as default
    Utils::Codegen.mk_insync(self, :true)
  end

  newproperty(:always_compare_med) do
    desc 'Configure comparing MED from different neighbors.'

    newvalues(:absent, :true, :false)

    # Generate insync? method which will compare considering false as default
    Utils::Codegen.mk_insync(self, :false)
  end

  newproperty(:default_loc_pref) do
    desc 'Configure default local preference value. Valid values are
    1-4294967295.'

    validate do |v|
      raise "Invalid default_loc_pref #{v}" unless v.empty? ||
                                               ((Integer(v) > 1) &&
                                                (Integer(v) < 4294967295))
    end
  end

  newproperty(:confederation_identifier) do
    desc 'Set the autonomous system identifier for confederation routing
    domain. Valid values are integer 1-4294967295 and dotted decimal format
    0.1-65535.65535'

    validate do |v|
      raise "Unrecognized value for confederation_identifier #{v}" unless
                             /^(\d+|\d+\.\d+)$/.match(v.to_s)
    end
  end

  newproperty(:confederation_peers, array_matching: :all) do
    desc 'Configure peer autonomous system numbers in BGP confederation as
    a list. Valid values for each entry are integer 1-4294967295 and dotted
    decimal format 0.1-65535.65535'

    validate do |v|
      raise "Unrecognized value for confederation_identifier #{v}" unless
                             /^(\d+|\d+\.\d+)$/.match(v.to_s)
    end

    def insync?(is)
      is = [] if is == :absent
      is.sort == should.sort
    end

    # confederation peers are provided by CLI as array of strings
    munge do |v|
      String(v)
    end
  end

  newproperty(:route_reflector_client_to_client) do
    desc 'Configure client to client route reflection.'

    newvalues(:absent, :true, :false)

    # Generate insync? method which will compare considering true as default
    Utils::Codegen.mk_insync(self, :true)
  end

  newproperty(:route_reflector_cluster_id) do
    desc 'Configure Route-Reflector Cluster-id. Valid values are 32 bit
    integer 1-4294967295 or A.B.C.D IPV4 address format.'

    validate do |v|
      begin
        IPAddr.new(v.to_s)
      rescue IPAddr::Error
        raise "Invalid route_reflector_cluster_id #{v}"
      end
    end
  end

  newproperty(:bestpath_as_path) do
    desc 'Configures the bestpath selection to either ignore or include
    prefixes received from different AS path during multipath calculation.'

    newvalues(:absent, :ignore, :multipath_relax)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:bestpath_med_confed) do
    desc 'Configures bestpath to compare MED among confederation paths.'

    newvalues(:absent, :true, :false)

    # Generate insync? method which will compare considering false as default
    Utils::Codegen.mk_insync(self, :false)
  end

  newproperty(:bestpath_med_missing_as_worst) do
    desc 'Configures bestpath to treat missing MED as the least preferred
    one.'

    newvalues(:absent, :true, :false)

    # Generate insync? method which will compare considering false as default
    Utils::Codegen.mk_insync(self, :false)
  end

  newproperty(:bestpath_routerid_ignore) do
    desc 'Configures bestpath computation to ignore router identifier.'

    newvalues(:absent, :true, :false)

    # Generate insync? method which will compare considering false as default
    Utils::Codegen.mk_insync(self, :false)
  end
end
