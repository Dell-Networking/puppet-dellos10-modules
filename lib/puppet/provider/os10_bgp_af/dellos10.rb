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
# This is pure ruby implementation of provider for os10_bgp_af resource.

require '/opt/dell/os10/bin/devops/dellos10_shell.rb'

Puppet::Type.type(:os10_bgp_af).provide(:dellos10) do
  desc 'Dell Networking OS Address family sub-configuration for BGP '\
  'Configuration Provider'

  alias_method :esc, :execute_show_command
  alias_method :ecc, :execute_config_command

  start_os10_shell

  # Helper function to read BGP configuration and get it populated internally.
  # This is called only once during startup.
  def init(ipver)
    begin
      ret = esc 'show running-configuration bgp | display-xml'
      bgp = extract(ret, :stdout, 'rpc-reply', :data, :'bgp-router')

      if bgp
        @property_hash[:asn] = extract(bgp, :vrf, :'local-as-number')
        # If the asn of the configuration is not same as our resource's asn, we
        # can't do much from bgp-af.
        raise "asn in config is #{@property_hash[:asn]} mismatches with asn "\
             "provided #{resource[:asn]}" unless (@property_hash[:asn] ==
                                                   resource[:asn])
        @property_hash[:ip_ver] = ipver

        # We proceed further ONLY if asn matches
        if ipver == 'ipv4'
          @af = extract(bgp, :vrf, :'ipv4-unicast')
        elsif ipver == 'ipv6'
          @af = extract(bgp, :vrf, :'ipv6-unicast')
        else
          raise "Invalid ipversion #{ipver}"
        end

        if !@af
          # There is no address family configuration present
          return
        end

        @property_hash[:asn] = extract(bgp, :'local-as-number')
        @property_hash[:ip_ver] = ipver

        @property_hash[:aggregate_address] = @aggr_addr = \
                                               extract_aggregate_addr(@af)

        @property_hash[:dampening_state] = extract(@af, :dampening, :enable)

        @property_hash[:default_metric] = extract(@af, :'default-metric')

        @property_hash[:network] = @net_addr = extract_network_address_list(@af)

        @property_hash[:redistribute] = @redis = extract_redistribute(@af)
      end
    rescue Exception => e
      err "Exception in #{__method__}"
      err e.message
      err e.backtrace[0]
      end_os10_shell
      raise
    end
  end

  def extract_redistribute(af)
    ret = []

    if af.has_key? :'redistribute-connected'
      ret << "connected #{af[:'redistribute-connected']\
                          [:'redistribute-route-map']}".strip

    end

    if af.has_key? :'redistribute-static'
      ret << "static #{af[:'redistribute-static'][:'route-map']}".strip
    end

    ret << "ospf #{af[:'redistribute-ospf'][:id]}" if af.has_key? :'redistribute-ospf'

    ret
  end

  def extract_aggregate_addr(af)
    addrlist = extract(af, :'aggregate-address-list')

    if addrlist && (addrlist.class != Array)
      addrlist = [addrlist] # Not an array in case of only one entry
    end

    ret = []
    if addrlist
      # Ignoring aggregate-options, this will result in one additional config
      # set if aggregate options are provided in resource and it already exists.
      addrlist.each { |v| ret << v[:prefix] }
    end
    ret
  end

  def extract_network_address_list(af)
    addrlist = extract(af, :'network-address-list')

    if addrlist && (addrlist.class != Array)
      addrlist = [addrlist] # Not an array in case of only one entry
    end

    ret = []

    addrlist.each { |v| ret << "#{v[:prefix]} #{v[:'route-map']}".strip } if addrlist

    ret
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
        end_os10_shell
        raise
      end
    end
  end

  def exists?
    info "#{__method__} for #{resource[:asn]}"
    begin
      init(resource[:ip_ver])
      ret = (@af != nil)
      info "returning #{ret}"
      ret
    rescue Exception => e
      err "Exception in #{__method__}"
      err e.message
      err e.backtrace[0]
      end_os10_shell
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
      @property_flush[:ensure] = :present
    rescue Exception => e
      err "Exception in #{__method__}"
      err e.message
      err e.backtrace[0]
      end_os10_shell
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
      end_os10_shell
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
        conf_lines = ["router bgp #{resource[:asn]}"]
        conf_lines << "no address-family #{resource[:ip_ver]} unicast"
        info conf_lines.to_s
        ecc conf_lines
        return
      end

      conf_lines = []
      conf_lines << "router bgp #{resource[:asn]}"
      conf_lines << "address-family #{resource[:ip_ver]} unicast"

      # Translate all the values available in property_flush to CLI. The values
      # in property_flush are the only ones that differ from manifest and
      # system.
      @property_flush.each do |attr, val|
        info "applying #{attr} #{val}"

        case attr
        when :aggregate_address
          # Handle case when creating from blank config
          @aggr_addr = [] if !@aggr_addr

          add = val - @aggr_addr
          del = @aggr_addr - val

          # Process del first to handle case of aggregate ip options change
          del.each { |v| conf_lines << "no aggregate-address #{v}" }
          add.each { |v| conf_lines << "aggregate-address #{v}" }

        when :dampening_state
          # If half-life is defined, we assume all others are also defined ;
          # when dampening_state is enabled.
          if (val == :true) && !@property_flush.has_key?(:dampening_half_life)
            # when dampening is set to true but no values are provided, just
            # set it to defaults
            conf_lines << 'dampening'
          elsif val == :false or val == :absent
            # When the value is false or absent
            conf_lines << 'no dampening'
          else
            # When the value is set to true and values are provided, do-nothing
            # as dampening would be configured when handling the values.
          end

          if val == :false
            # If dampening state is set to false, ignore the rest of the
            # dampening parameters, even if they are set
            @property_flush.delete_if { |k, _v|
              k == :dampening_half_life ||
              k == :dampening_reuse ||
              k == :dampening_suppress ||
              k == :dampening_max_suppress ||
              k == :dampening_route_map
            }
          end

        when :dampening_half_life,
             :dampening_reuse,
             :dampening_suppress,
             :dampening_max_suppress,
             :dampening_route_map
          dampconf = "dampening #{@property_flush[:dampening_half_life]} "\
                        "#{@property_flush[:dampening_reuse]} "\
                        "#{@property_flush[:dampening_suppress]} "\
                        "#{@property_flush[:dampening_max_suppress]} "

          if !@property_flush[:dampening_route_map].empty?
            dampconf += 'route-map '\
                        "#{@property_flush[:dampening_route_map]}"
          end

          conf_lines << dampconf

          # delete the keys after using them, so that we won't iterate again
          @property_flush.delete_if { |k, _v|
            k == :dampening_half_life ||
            k == :dampening_reuse ||
            k == :dampening_suppress ||
            k == :dampening_max_suppress ||
            k == :dampening_route_map
          }

        when :default_metric
          if !val.empty?
            conf_lines << "default-metric #{val}"
          else
            conf_lines << 'no default-metric'
          end

        when :network
          # Handle case when creating from blank config
          @net_addr = [] if !@net_addr

          add = val - @net_addr
          del = @net_addr - val

          add.each do |v|
            l = v.split(' ')
            if l.length == 2
              conf_lines << "network #{l[0]} route-map #{l[1]}"
            else
              conf_lines << "network #{l[0]}"
            end
          end

          del.each do |v|
            l = v.split(' ')
            if l.length == 2
              conf_lines << "no network #{l[0]} route-map #{l[1]}"
            else
              conf_lines << "no network #{l[0]}"
            end
          end

        when :redistribute
          # Handle the case of creating from blank
          @redis = [] if !@redis

          add = val - @redis
          del = @redis - val

          # First we need to delete then add!
          del.each do |v|
            l = v.split(' ')
            conf = "no redistribute #{l[0]}"
            conf += " route-map #{l[1]}" if l[1]
            conf_lines << conf
          end

          add.each do |v|
            l = v.split(' ')
            conf = "redistribute #{l[0]}"
            conf += " route-map #{l[1]}" if l[1]
            conf_lines << conf
          end

        else
          debug "skipping translating #{attr} to CLI"
        end
      end
      info conf_lines.to_s
      ecc conf_lines
      end_os10_shell
    rescue Exception => e
      err "Exception in #{__method__}"
      err e.message
      err e.backtrace[0]
      end_os10_shell
      raise
    end
  end
end
