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
#

require '/opt/dell/os10/bin/devops/dellos10_shell.rb'

Puppet::Type.type(:os10_bgp_neighbor).provide(:dellos10) do
  desc 'Dell Networking OS Address family sub-configuration for BGP '\
  'Configuration Provider'

  alias_method :esc, :execute_show_command
  alias_method :ecc, :execute_config_command

  start_os10_shell

  # Helper function to read BGP configuration and get it populated internally.
  # This is called only once during startup.
  def init(ip_name, type)
    begin
      ret = esc 'show running-configuration bgp | display-xml'
      bgp = extract(ret, :stdout, 'rpc-reply', :data, :'bgp-router')

      if bgp
        @nbr = extract_peer(bgp, ip_name, type)

        if !@nbr
          # There is no neighbor with the given ipaddr/name
          debug "no neighbor configuration with #{ip_name}"
          return
        end

        # Fail if the asn differs at first place

        @property_hash[:asn] = extract(bgp, :vrf, :'local-as-number')
        if @property_hash[:asn] != resource[:asn]
          raise "asn #{@property_hash[:asn]} differs from #{resource[:asn]}"
        end

        @property_hash[:type] = resource[:type]
        @property_hash[:neighbor] = resource[:neighbor] # neighbor is Key
        @property_hash[:advertisement_interval] = extract(@nbr,
                                                    :'advertisement-interval')
        @property_hash[:advertisement_start]    = extract(@nbr,
                                                    :'advertisement-start')
        @property_hash[:connection_retry_timer] = extract(@nbr,
                                                    :'connection-retry-timer')
        @property_hash[:remote_as]              = extract(@nbr,
                                                    :'remote-as')
        @property_hash[:remove_private_as]      = extract(@nbr,
                                                    :'remove-private-as')
        @property_hash[:shutdown]               = extract(@nbr,
                                                    :'shutdown-status')
        @property_hash[:password]               = extract(@nbr,
                                                    :password)
        @property_hash[:send_community_standard] = extract(@nbr,
                                                    :'send-community-standard')
        @property_hash[:send_community_extended] = extract(@nbr,
                                                    :'send-community-extended')

        @property_hash[:peergroup]               = extract(@nbr,
                                                    :'associate-peer-group')

        val                                      = extract(@nbr,
                                                    :'ebgp-multihop-count')
        val = '' if !val
        @property_hash[:ebgp_multihop]           = val

        @property_hash[:fall_over]               = @nbr.has_key? :'fall-over'

        val                                      = extract(@nbr,
                                                    :'local-as', :'as-number')
        val = '' if !val
        @property_hash[:local_as]                = val

        val                                      = extract(@nbr,
                                                    :'route-reflector-client')
        val = :absent if !val
        @property_hash[:route_reflector_client]  = val

        val                                      = extract(@nbr, :weight)
        val = '' if !val
        @property_hash[:weight] = val

        if @nbr.has_key? :'timers'
          @property_hash[:timers] = [
            extract(@nbr, :timers, :'config-keepalive'),
            extract(@nbr, :timers, :'config-hold-time')
          ]
        else
          @property_hash[:timers] = []
        end
      end
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
      init(resource[:neighbor], resource[:type])
      ret = (@nbr != nil)
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
      info "#{__method__} for #{resource[:asn]} #{resource[:neighbor]}"
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
      raise
    end
  end

  def destroy
    begin
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

      if resource[:type].to_s == 'ip'
        type = 'neighbor'
      else
        type = 'template'
      end

      # flush is called even for ensure=>absent. In that case we would have
      # deleted the bgp configuration in destroy method.
      if @property_flush[:ensure] == :absent
        conf_lines = ["router bgp #{resource[:asn]}"]
        conf_lines << "no #{type} #{resource[:neighbor]}"
        info conf_lines.to_s
        ecc conf_lines
        return
      end

      conf_lines = []
      conf_lines << "router bgp #{resource[:asn]}"
      conf_lines << "#{type} #{resource[:neighbor]}"

      # Translate all the values available in property_flush to CLI. The values
      # in property_flush are the only ones that differ from manifest and
      # system.
      @property_flush.each do |attr, val|
        info "applying #{attr} #{val}"

        case attr

        when :asn # rubocop:disable Lint/EmptyWhen
          # Do nothing. We are already inside sub-configuration. #

        when :advertisement_interval
          if !val.empty?
            conf_lines << "advertisement-interval #{val}"
          else
            conf_lines << 'no advertisement-interval'
          end

        when :advertisement_start
          if !val.empty?
            conf_lines << "advertisement-start #{val}"
          else
            conf_lines << 'no advertisement-start'
          end

        when :timers
          if val.empty?
            conf_lines << 'no timers'
          elsif val.length == 2
            conf_lines << "timers #{val[0]} #{val[1]}"
          else
            raise "Timers should have only no or two values. #{val}"
          end

        when :connection_retry_timer
          if !val.empty?
            conf_lines << "connection-retry-timer #{val}"
          else
            conf_lines << 'no connection-retry-timer'
          end

        when :remote_as
          if !val.empty?
            conf_lines << "remote-as #{val}"
          else
            conf_lines << 'no remote-as'
          end

        when :remove_private_as
          # remove-private-as is defaulted to false
          if val.to_s == 'true'
            conf_lines << 'remove-private-as'
          else
            conf_lines << 'no remove-private-as'
          end

        when :shutdown
          # shutdown is defaulted to true
          if val.to_s == 'false'
            conf_lines << 'no shutdown'
          else
            conf_lines << 'shutdown'
          end

        when :password
          if !val.empty?
            conf_lines << "password #{val}"
          else
            conf_lines << 'no password 1'
          end

        when :send_community_standard
          # send community standard is defaulted to false
          if val.to_s == 'true'
            conf_lines << 'send-community standard'
          else
            conf_lines << 'no send-community standard'
          end

        when :send_community_extended
          # send community extended is defaulted to false
          if val.to_s == 'true'
            conf_lines << 'send-community extended'
          else
            conf_lines << 'no send-community extended'
          end

        when :peergroup
          if !val.empty?
            conf_lines << "inherit template #{val}"
          else
            conf_lines << 'no inherit template dummy'
          end

        when :ebgp_multihop
          if !val.empty?
            conf_lines << "ebgp-multihop #{val}"
          else
            conf_lines << 'no ebgp-multihop'
          end

        when :fall_over
          if val.to_s == 'true'
            conf_lines << 'fall-over'
          else
            conf_lines << 'no fall-over'
          end

        when :local_as
          if !val.empty?
            conf_lines << "local-as #{val}"
          else
            conf_lines << 'no local-as'
          end

        when :route_reflector_client
          if val.to_s == 'true'
            conf_lines << 'route-reflector-client'
          else
            conf_lines << 'no route-reflector-client'
          end

        when :weight
          if !val.empty?
            conf_lines << "weight #{val}"
          else
            conf_lines << 'no weight'
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
