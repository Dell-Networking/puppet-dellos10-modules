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
# This is pure ruby implementation of provider for os10_interface resource.
# Sample definition for the interface resource:
#

require 'ipaddr'
require '/opt/dell/os10/bin/devops/dellos10_shell.rb'

Puppet::Type.type(:os10_interface).provide(:dellos10) do
  desc 'Dell Networking OS Interface Provider'

  alias_method :esc, :execute_show_command
  alias_method :ecc, :execute_config_command

  attr_reader :desc
  attr_reader :mtu
  attr_reader :switchport_mode
  attr_reader :admin
  attr_reader :ip_address
  attr_reader :ipv6_address
  attr_reader :ipv6_autoconfig
  attr_reader :ip_helper

  start_os10_shell

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

  def initialize(*args)
    intf_name = args[0].name
    super(*args)

    info "Reading interface configuration for #{intf_name}"

    ret = esc "show running-configuration interface #{intf_name} "\
             ' | display-xml'
    intf = ret[:stdout]['rpc-reply'][:data][:interfaces][:interface]

    @desc = extract(intf, :description)
    @mtu  = extract(intf, :mtu)

    @ip_helper = extract(intf, :'dhcp-relay-if-cfgs', :'server-address')
    @ip_helper = [] if !@ip_helper
    @ip_helper = [@ip_helper] if @ip_helper.class != Array

    @ip_address = extract(intf, :ipv4, :address, :'primary-addr')
    @ipv6_address = extract(intf, :ipv6, :'ipv6-addresses', :address,
                            :'ipv6-address')

    @ipv6_autoconfig = extract(intf, :ipv6, :autoconfig)

    # When the interface is shutdown, there will be enabled key set to 'false'
    # Otherwise there will not be enabled key.
    enabled = extract(intf, :enabled)
    if enabled == 'false'
      @admin = 'down'
    else
      @admin = 'up'
    end

    # Intf is in L3 when mode is MODE_L2DISABLED ('no switchport')
    # In L2, mode will not be there for vlan-access and mode will be set to
    # MODE_L2HYBRID for trunk port.
    mode = extract(intf, :mode)
    case mode
    when nil
      @switchport_mode = 'access'
    when 'MODE_L2DISABLED'
      @switchport_mode = 'false'
    when 'MODE_L2HYBRID'
      @switchport_mode = 'trunk'
    else
      err "Invalid switchport mode read from device #{mode}"
    end
  end

  def desc=(val)
    info "#{__method__} for #{resource[:name]}"
    begin
      conf_lines = ["interface #{resource[:name]}"]
      conf_lines << "description \"#{val}\""
      ecc conf_lines
    rescue Exception => e
      err "Exception in #{__method__}"
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def mtu=(val)
    info "#{__method__} for #{resource[:name]}"
    begin
      conf_lines = ["interface #{resource[:name]}"]
      if !val.empty?
        conf_lines << "mtu #{val}"
      else
        conf_lines << 'no mtu'
      end
      ecc conf_lines
    rescue Exception => e
      err "Exception in #{__method__}"
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def switchport_mode=(val)
    info "#{__method__} for #{resource[:name]}"
    begin
      # When switchport mode is access or trunk, we will clear the ip_addresses
      # before changing the mode. We can assume there won't be any further set
      # of ip_address from the config, as the validation is already done in the
      # resource type definition itself.
      conf_lines = ["interface #{resource[:name]}"]
      if (val == 'access') || (val == 'trunk')
        conf_lines << 'no ip address'
        conf_lines << 'no ipv6 address'

        @ip_helper.each { |v| conf_lines << "no ip helper-address #{v}" } \
            if @ip_helper

        conf_lines << "switchport mode #{val}"
      elsif val == 'false'
        conf_lines << 'no switchport'
      end
      debug conf_lines
      ecc conf_lines
    rescue Exception => e
      err "Exception in #{__method__}"
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def admin=(val)
    info "#{__method__} for #{resource[:name]}"
    begin
      conf_lines = ["interface #{resource[:name]}"]
      case val
      when :up
        conf_lines << 'no shutdown'
      when :down
        conf_lines << 'shutdown'
      else
        err "Invalid value passed to admin= #{val}"
      end

      ecc conf_lines
    rescue Exception => e
      err "Exception in #{__method__}"
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def ip_address=(val)
    info "#{__method__} for #{resource[:name]}"
    begin
      conf_lines = ["interface #{resource[:name]}"]

      if !val.empty?
        conf_lines << "ip address #{val}"
      else
        conf_lines << 'no ip address'
      end
      ecc conf_lines
    rescue Exception => e
      err "Exception in #{__method__}"
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def ipv6_address=(val)
    info "#{__method__} for #{resource[:name]}"
    begin
      conf_lines = ["interface #{resource[:name]}"]

      if val.length
        conf_lines << "ipv6 address #{val}"
      else
        conf_lines << 'no ipv6 address'
      end
      ecc conf_lines
    rescue Exception => e
      err "Exception in #{__method__}"
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def ipv6_autoconfig=(val)
    info "#{__method__} for #{resource[:name]}"
    begin
      conf_lines = ["interface #{resource[:name]}"]
      case val
      when :true
        conf_lines << 'ipv6 address autoconfig'
      when :false
        conf_lines << 'no ipv6 address autoconfig'
      else
        err "Invalid value for ipv6 autoconfig=#{val}"
      end

      ecc conf_lines
    rescue Exception => e
      err "Exception in #{__method__}"
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def ip_helper=(val)
    info "#{__method__} for #{resource[:name]}"
    begin
      rem = @ip_helper - val
      add = val - @ip_helper
      conf_lines = ["interface #{resource[:name]}"]
      add.each do |v|
        conf_lines << "ip helper-address #{v}"
      end
      rem.each do |v|
        conf_lines << "no ip helper-address #{v}"
      end

      ecc conf_lines
    rescue Exception => e
      err "Exception in #{__method__}"
      err e.message
      err e.backtrace[0]
      raise
    end
  end
end
