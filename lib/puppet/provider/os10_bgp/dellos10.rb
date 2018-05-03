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
# This is pure ruby implementation of provider for os10_bgp resource.
#

require '/opt/dell/os10/bin/devops/dellos10_shell.rb'

Puppet::Type.type(:os10_bgp).provide(:dellos10) do
  desc 'Dell Networking OS BGP Configuration Provider'

  alias_method :esc, :execute_show_command
  alias_method :ecc, :execute_config_command

  start_os10_shell

  # Helper function to read BGP configuration and get it populated internally.
  # This is called only once during startup.
  def init(should_asn)
    begin
      ret = esc 'show running-configuration bgp | display-xml'
      bgp = extract(ret, :stdout, 'rpc-reply', :data, :'bgp-router')

      if bgp
        bgp = extract(bgp, :vrf)
        @property_hash[:asn] = extract(bgp, :'local-as-number')

        # Handle the case when there is already a BGP configuration with a
        # different asn.
        if should_asn != @property_hash[:asn]
          @is_asn = @property_hash[:asn]
          return false
        end

        @property_hash[:router_id] = extract(bgp, :'router-id')
        @property_hash[:max_path_ebgp] = extract(bgp, :'ebgp-number-of-path')
        @property_hash[:max_path_ibgp] = extract(bgp, :'ibgp-number-of-path')
        @property_hash[:graceful_restart] = extract(bgp, :'graceful-restart',
                                                    :'helper-only')
        @property_hash[:log_neighbor_changes] = extract(bgp,
                                                        :'log-neighbor-changes',
                                                        default_true = true)
        @property_hash[:fast_external_fallover] = extract(bgp,
                                                  :'fast-external-fallover')
        @property_hash[:always_compare_med] = bgp.has_key? :'always-compare-med'
        @property_hash[:default_loc_pref] = extract(bgp,
                                              :'default-local-pref')
        @property_hash[:confederation_identifier] = extract(bgp,
                                                    :'confederation-identifier')

        @property_hash[:confederation_peers] = extract(bgp,
                                                       :'confed-peer-as')
        # confederation peers are provided by CLI as array of strings
        @conf_peers = @property_hash[:confederation_peers]

        @property_hash[:route_reflector_client_to_client] = extract(bgp,
                                                :'client-to-client-reflection')
        @property_hash[:route_reflector_cluster_id] = extract(bgp,
                                                            :'cluster-id-value')
        init_bestpath(bgp)
      end
    rescue Exception => e
      err "Exception in #{__method__}"
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def init_bestpath(bgp)
    bp = extract(bgp, :bestpath)

    return if !bp

    if bp.has_key? :'aspath-ignore'
      @property_hash[:bestpath_as_path] = 'ignore'
    elsif bp.has_key? :'aspath-multipath-relax'
      @property_hash[:bestpath_as_path] = 'multipath_relax'
    end
    @bestpath_aspath = @property_hash[:bestpath_as_path]

    val = (bp.has_key? :'med-confed') ? :true : :false
    @property_hash[:bestpath_med_confed] = val

    val = (bp.has_key? :'missing-as-best') ? :true : :false
    @property_hash[:bestpath_med_missing_as_worst] = val

    val = (bp.has_key? :'ignore-routerid') ? :true : :false
    @property_hash[:bestpath_routerid_ignore] = val
  end

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  # Helper function to extract values from nested dictionary
  def extract(dict, *keys)
    begin
      ret = nil
      keys.each do |k|
        ret = dict[k]
        break if ret.class != Hash
        dict = ret
      end
      ret
    rescue Exception => e
      err "Exception in #{__method__}"
      err e.message
      err e.backtrace[0]
      nil
    end
  end

  # Have the framework generate getter and setter methods for our properties
  mk_resource_methods

  # Override the setter methods alone for optimizing flush
  resource_type.validproperties.each do |attr|
    define_method(attr.to_s + '=') do |val|
      begin
        # Assiging value to the property_hash is done in framework's set method,
        # we too do the same so as not to break framework's expectation
        @property_hash[attr] = val

        # After assigning values, we will use the overridden setter method to
        # track the properties that was set. We will use only THESE attributes
        # in flush method to write to system CLI.
        @property_flush[attr] = val
      rescue Exception => e
        err "Exception in #{__method__}"
        err e.message
        err e.backtrace[0]
        raise
      end
    end
  end

  def exists?
    info "#{__method__} for #{resource[:asn]}"
    begin
      init resource[:asn]
      ret = @property_hash[:asn] == resource[:asn]
      info "returning #{ret}"
      ret
    rescue Exception => e
      err "Exception in #{__method__}"
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def create
    begin
      info "#{__method__} for #{resource[:asn]}"
      # We don't handle anything here since we have the entire code in flush
      # Since the entire configuration doesn't exist, property_flush would be
      # empty (as no setters are called) and property_hash would be synced by
      # framework
      @property_flush = Hash(resource)
    rescue Exception => e
      err "Exception in #{__method__}"
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def destroy
    begin
      info "#{__method__} for #{resource[:asn]}"
      @property_flush[:ensure] = :absent
    rescue Exception => e
      err "Exception in #{__method__}"
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def flush
    # flush is called for destroy also!
    begin
      info "#{__method__} for #{resource[:asn]}"

      # flush is called even for ensure=>absent. In that case we would have
      # deleted the bgp configuration in destroy method.
      if @property_flush[:ensure] == :absent
        ecc ['no router bgp']
        return
      end

      # Handle the case when there is already a BGP configuration with a
      # different asn. We should remove the existing BGP configuration before
      # creating the SHOULD one.
      ecc ['no router bgp'] if @is_asn

      conf_lines = []
      conf_lines << "router bgp #{resource[:asn]}"

      # Translate all the values available in property_flush to CLI. The values
      # in property_flush are the only ones that differ from manifest and
      # system.
      @property_flush.each do |attr, val|
        debug "applying #{attr} #{val}"

        case attr
        when :router_id
          if !val.empty?
            conf_lines << "router-id #{val}"
          else
            conf_lines << 'no router-id'
          end

        when :max_path_ebgp
          if !val.empty?
            conf_lines << "maximum-paths ebgp #{val}"
          else
            conf_lines << 'no maximum-paths ebgp'
          end

        when :max_path_ibgp
          if !val.empty?
            conf_lines << "maximum-paths ibgp #{val}"
          else
            conf_lines << 'no maximum-paths ibgp'
          end

        when :graceful_restart
          if val == 'true'
            conf_lines << 'graceful-restart role receiver-only'
          else
            conf_lines << 'no graceful-restart role receiver-only'
          end

        when :log_neighbor_changes
          if val == 'true'
            conf_lines << 'log-neighbor-changes'
          else
            conf_lines << 'no log-neighbor-changes'
          end

        when :fast_external_fallover
          if val == 'true'
            conf_lines << 'fast-external-fallover'
          else
            conf_lines << 'no fast-external-fallover'
          end

        when :always_compare_med
          if val == 'true'
            conf_lines << 'always-compare-med'
          else
            conf_lines << 'no always-compare-med'
          end

        when :default_loc_pref
          if !val.empty?
            conf_lines << "default local-preference #{val}"
          else
            conf_lines << 'no default local-preference'
          end

        when :confederation_identifier
          if !val.empty?
            conf_lines << "confederation identifier #{val}"
          else
            conf_lines << 'no confederation identifier'
          end

        when :confederation_peers
          # Handle case when creating from blank config
          @conf_peers = [] if !@conf_peers
          add = val - @conf_peers
          del = @conf_peers - val
          add.each { |v| conf_lines << "confederation peers #{v}" }
          del.each { |v| conf_lines << "no confederation peers #{v}" }

        when :route_reflector_client_to_client
          if val == 'true'
            conf_lines << 'client-to-client reflection'
          else
            conf_lines << 'no client-to-client reflection'
          end

        when :route_reflector_cluster_id
          if !val.empty?
            conf_lines << "cluster-id #{val}"
          else
            # Bug in OS10 CLI expects a number to clear the cluster-id.
            conf_lines << 'no cluster-id 1'
          end

        when :bestpath_as_path
          if val != :absent
            val = 'multipath-relax' if val.to_s == 'multipath_relax'
            conf_lines << "bestpath as-path #{val}"
          else
            @bestpath_aspath = 'multipath-relax' if @bestpath_aspath.to_s ==
                                                    'multipath_relax'
            # Clear bestpath only if something was present
            conf_lines << "no bestpath as-path #{@bestpath_aspath}" \
                                                 if @bestpath_aspath
          end

        when :bestpath_med_confed
          if val == 'true'
            conf_lines << 'bestpath med confed'
          else
            conf_lines << 'no bestpath med confed'
          end

        when :bestpath_med_missing_as_worst
          if val == 'true'
            conf_lines << 'bestpath med missing-as-worst'
          else
            conf_lines << 'no bestpath med missing-as-worst'
          end

        when :bestpath_routerid_ignore
          if val == 'true'
            conf_lines << 'bestpath router-id ignore'
          else
            conf_lines << 'no bestpath router-id ignore'
          end

        else
          debug "skipping translating #{attr} to CLI"
        end
      end
      info conf_lines.to_s
      ecc conf_lines
    rescue Exception => e
      err "Exception in #{__method__}"
      err e.message
      err e.backtrace[0]
      raise
    end
  end
end
