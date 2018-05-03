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
# This is pure ruby implementation of provider for os_bgp_neighbor_af resource.
#

require '/opt/dell/os10/bin/devops/dellos10_shell.rb'

Puppet::Type.type(:os10_bgp_neighbor_af).provide(:dellos10) do
  desc 'Dell Networking OS BGP neighbor address family configuration provider'

  alias_method :esc, :execute_show_command
  alias_method :ecc, :execute_config_command

  start_os10_shell

  # Helper function to read BGP configuration and get it populated internally.
  # This is called only once during startup.
  # neighbor_ipname is an ip address when neighbor_type is ip.
  # neighbor_ipname is a name string when neighbor_type is template
  def init(nbr_ipname, nbr_type, ip_ver)
    begin
      ret = esc 'show running-configuration bgp | display-xml'
      bgp = extract(ret, :stdout, 'rpc-reply', :data, :'bgp-router')

      raise 'bgp configuration not present.' if !bgp

      # Fail if the asn differs at first place
      @property_hash[:asn] = extract(bgp, :vrf, :'local-as-number')
      if @property_hash[:asn] != resource[:asn]
        raise "asn #{@property_hash[:asn]} differs from #{resource[:asn]}"
      end

      # Fail if there is no neighbor configuration
      nbr = extract_peer(bgp, nbr_ipname, nbr_type)
      raise "neighbor #{nbr_ipname} not configured." if !nbr

      @nbr_af = extract(nbr, (ip_ver.to_s + '-unicast').to_sym)
      if !@nbr_af
        # There is no af configuration for the given ip type
        return
      end

      @property_hash[:activate]   = extract(@nbr_af, :'activate')
      @property_hash[:allowas_in] = extract(@nbr_af, :'allowas-in')
      @property_hash[:add_path]   = extract_add_path(@nbr_af)

      val = extract(@nbr_af, :'next-hop-self')
      val = :false if !val
      @property_hash[:next_hop_self] = val

      val = extract(@nbr_af, :'sender-side-loop-detection')
      val = :true if !val
      @property_hash[:sender_side_loop_detection] = val

      val = @nbr_af.has_key? :'soft-reconfiguration-inbound'
      val = :false if !val
      @property_hash[:soft_reconfiguration] = val

      val = extract(@nbr_af, :'distribute-list-name-in')
      val = '' if !val
      @property_hash[:distribute_list] = [val]

      val = extract(@nbr_af, :'distribute-list-name-out')
      val = '' if !val
      @property_hash[:distribute_list].push(val)

      val = extract(@nbr_af, :'route-map-in')
      val = '' if !val
      @property_hash[:route_map] = [val]

      val = extract(@nbr_af, :'route-map-out')
      val = '' if !val
      @property_hash[:route_map].push(val)

    rescue Exception => e
      err "Exception in #{__method__}"
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  def extract_add_path(nbr_af)
    apath = extract(nbr_af, :'add-path')
    ret = ''
    if apath
      ret = extract(apath, :'capability')
      if ret == 'send' || ret == 'both'
        ret += ' ' + extract(apath, :'count')
      end
    end
    ret
  end

  # ip_name is either ip address if type==ip or template name if type==template
  def extract_peer(bgp, ip_name, type)
    # rubocop:disable Style/Semicolon
    ret = nil
    if type == :ip
      vrf = extract(bgp, :vrf, :'peer-config')
      if vrf
        vrf = [vrf] if vrf.class != Array

        vrf.each { |v| (ret = v; break) if v[:'remote-address'] == ip_name }
      end
    elsif type == :template
      vrf = extract(bgp, :vrf, :'peer-group-config')
      if vrf
        vrf = [vrf] if vrf.class != Array

        vrf.each { |v| (ret = v; break) if v[:name] == ip_name }
      end
    else
      # This condition should not be hit.
      raise "Invalid neighbor type #{type}"
    end
    ret
    # rubocop:enable Style/Semicolon
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
    info "#{__method__} for #{resource[:asn]} #{resource[:neighbor]}"
    begin
      init(resource[:neighbor], resource[:type], resource[:ip_ver])
      ret = (@nbr_af != nil)
      info "exists? returning #{ret}"
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
      info "#{__method__} for #{resource[:asn]} #{resource[:neighbor]}"
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
      info "#{__method__} for #{resource[:asn]} #{resource[:neighbor]}"
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
      info "#{__method__} for #{resource[:asn]} #{resource[:neighbor]}"

      conf_lines = []

      if resource[:type].to_s == 'ip'
        type = 'neighbor'
      else
        type = 'template'
      end

      # flush is called even for ensure=>absent. In that case we would have
      # deleted the bgp neighbor af configuration in destroy method.
      if @property_flush[:ensure] == :absent
        conf_lines << "route bgp #{resource[:asn]}"
        conf_lines << "#{type} #{resource[:neighbor]}"
        conf_lines << "no address-family #{resource[:ip_ver]} unicast"

        info conf_lines
        ecc conf_lines
        return
      end

      conf_lines << "router bgp #{resource[:asn]}"
      conf_lines << "#{type} #{resource[:neighbor]}"
      conf_lines << "address-family #{resource[:ip_ver]} unicast"

      # Translate all the values available in property_flush to CLI. The values
      # in property_flush are the only ones that differ from manifest and
      # system.
      @property_flush.each do |attr, val|
        debug "applying #{attr} #{val}"
        case attr
        when :activate
          if val == 'false'
            conf_lines << 'no activate'
          else
            conf_lines << 'activate'
          end

        when :allowas_in
          if val.empty?
            conf_lines << 'no allowas-in'
          else
            conf_lines << "allowas-in #{val}"
          end

        when :add_path
          if val.empty?
            conf_lines << 'no add-path'
          else
            conf_lines << "add-path #{val}"
          end

        when :next_hop_self
          if val == 'false'
            conf_lines << 'no next-hop-self'
          else
            conf_lines << 'next-hop-self'
          end

        when :sender_side_loop_detection
          if val == 'false'
            conf_lines << 'no sender-side-loop-detection'
          else
            conf_lines << 'sender-side-loop-detection'
          end

        when :soft_reconfiguration
          if val == 'false'
            conf_lines << 'no soft-reconfiguration inbound'
          else
            conf_lines << 'soft-reconfiguration inbound'
          end

        when :distribute_list
          raise "Invalid distribute_list #{val}" if val.length != 2 ||
                                                    val[0].class != String ||
                                                    val[1].class != String
          if !val[0].empty?
            conf_lines << "distribute-list #{val[0]} in"
          else
            conf_lines << 'no distribute-list TEMP in'
          end

          if !val[1].empty?
            conf_lines << "distribute-list #{val[1]} out"
          else
            conf_lines << 'no distribute-list TEMP out'
          end

        when :route_map
          raise "Invalid route_map #{val}" if val.length != 2 ||
                                           val[0].class != String ||
                                           val[1].class != String
          if !val[0].empty?
            conf_lines << "route-map #{val[0]} in"
          else
            conf_lines << 'no route-map TEMP in'
          end

          if !val[1].empty?
            conf_lines << "route-map #{val[1]} out"
          else
            conf_lines << 'no route-map TEMP out'
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
