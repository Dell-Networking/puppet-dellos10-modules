# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# Author::     Hemalathaa Selvaraj (hemalathaa_s@dell.com)
# Copyright::  Copyright (c) 2018, Dell Inc. All rights reserved.
# License::    [Apache License] (http://www.apache.org/licenses/LICENSE-2.0)
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# This is pure ruby implementation of provider for os10_lldp resource.
#

# Sample definition for os10_lldp resource:

# os10_lldp { 'lldpconf':
#   holdtime_multiplier => '3',
#   reinit              => '4',
#   timer               => '5',
#   enable              => 'true',
#   med_fast_start_repeat_count => '6',
#   med_network_policy => [{"id"=>'8', "app"=>"voice", "vlan"=>"3",
#                         "vlan-type"=> "tag", "priority"=>"3",
#                         "dscp"=>"4"}, {"id"=>'7', "app"=>"voice",
#                         "vlan"=>"5", "vlan-type"=> "tag",
#                         "priority"=>"3", "dscp"=>"4"}]
# }

require '/opt/dell/os10/bin/devops/dellos10_shell.rb'

Puppet::Type.type(:os10_lldp).provide(:dellos10) do
  desc 'Dell Networking OS LLDP Provider'

  alias_method :esc, :execute_show_command
  alias_method :ecc, :execute_config_command

  # Start the CLI shell server
  start_os10_shell

  # This function will cache the LLDP configuration data during the beginning of
  # the provider execution. This is done to avoid multiple CLI reads and the
  # side effect is the LLDP configuration changes made by any other means during
  # the puppet execution period will not be read.
  def init
    debug 'Caching lldp configuration...'
    ret = esc ('show running-configuration lldp | display-xml')
    @lldp = ret[:stdout]['rpc-reply'][:data]
    @lldp_global = @lldp[:'global-params'] || {}
    @lldp_sys = @lldp[:'sys-config'] || {}
  rescue Exception => e
    err 'Exception in init segment'
    err e.message
    err e.backtrace[0]
    raise
  end

  # Function to get and return the reinit value of LLDP configuration
  def reinit
    init
    info 'os10_lldp::reinit'
    begin
      return @lldp_global && @lldp_global[:'reinit-delay'] || ''
    rescue Exception => e
      err 'Exception in reinit delay'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function inputs a string to set the value of reinit in config
  # and executes the lldp configuration command
  def reinit=(str)
    info "os10_lldp::reinit= #{str}"
    begin
      if !str.empty?
        ecc ["lldp reinit #{str}"]
      else
        ecc ['no lldp reinit']
      end
    rescue Exception => e
      err 'Exception in reinit='
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function to get and return the holdtime_multiplier value of
  # LLDP configuration
  def holdtime_multiplier
    init
    info 'os10_lldp::holdtime_multiplier'
    begin
      return @lldp_global && @lldp_global[:'txhold-multiplier'] || ''
    rescue Exception => e
      err 'Exception in holdtime_multiplier'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function inputs a string to set the value of holdtime_multiplier in config
  # and executes the lldp configuration command
  def holdtime_multiplier=(str)
    info "os10_lldp::holdtime_multiplier=#{str}"
    begin
      if !str.empty?
        ecc ["lldp holdtime-multiplier #{str}"]
      else
        ecc ['no lldp holdtime-multiplier']
      end
    rescue Exception => e
      err 'Exception in holdime multiplier='
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function to get and return the timer value of LLDP configuration
  def timer
    init
    info 'os10_lldp::timer'
    begin
      return @lldp_global && @lldp_global[:'tx-interval'] || ''
    rescue Exception => e
      err 'Exception in timer'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function inputs a string to set the value of timer in config
  # and executes the lldp configuration command
  def timer=(str)
    info "os10_lldp::timer= #{str}"
    begin
      if !str.empty?
        ecc ["lldp timer #{str}"]
      else
        ecc ['no lldp timer']
      end
    rescue Exception => e
      err 'Exception in timer='
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function to get and return the med fast start repeat count
  # value of LLDP configuration
  def med_fast_start_repeat_count
    init
    info 'os10_lldp::med_fast_start_repeat_count'
    begin
      return @lldp_sys && @lldp_sys[:'fast-start-repeat-count'] || ''
    rescue Exception => e
      err 'Exception in med fast start repeat count'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function inputs a string to set the value of med fast start repeat
  # count in config and executes the lldp configuration command
  def med_fast_start_repeat_count=(str)
    info "os10_lldp::med_fast_start_repeat_count= #{str}"
    begin
      if !str.empty?
        ecc ["lldp med fast-start-repeat-count #{str}"]
      else
        ecc ['no lldp med fast-start-repeat-count']
      end
    rescue Exception => e
      err 'Exception in med fast start repeat count='
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function to get and return the global lldp enable value of
  # LLDP configuration
  def enable
    init
    info 'os10_lldp::enable global'
    begin
      return @lldp_global && @lldp_global[:enable] || ''
    rescue Exception => e
      err 'Exception in enable'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function inputs a boolean value string to set the value of enable in config
  # and executes the lldp configuration command
  def enable=(val)
    info "os10_lldp::enable=#{val}"
    begin
      # val would be a string 
      if @lldp_global && @lldp_global[:enable] && val.to_s == 'true'
        ecc ['lldp enable']
      else
        ecc ['no lldp enable']
      end
    rescue Exception => e
      err 'Exception in enable'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function to get and return the array of med_network_policy value
  # of LLDP configuration
  def med_network_policy
    init
    info 'os10_lldp::med_network_policy'
    begin
      @is_med_network_policy = @lldp_sys && @lldp_sys[:'media-policy'] || []
      return [@is_med_network_policy] if @is_med_network_policy.class == Hash
      return @is_med_network_policy
    rescue Exception => e
      err 'Exception in network policy'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function inputs an array of med_network_policy hashes to set the
  # network policies and return the exec of lldp configuration command
  def med_network_policy=(should_med_network_policy)
    info "os10_lldp::med_network_policy=#{should_med_network_policy}"
    begin
      conf_lines = []
      if med_network_policy
        # this is array subtraction
        remove = med_network_policy - should_med_network_policy
        remove.each do |policy|
          conf_lines << "no lldp med network-policy #{policy[:'policy-id']}"
        end
      end

      val = {}
      keys = ['id', 'app', 'vlan', 'vlan-type', 'priority', 'dscp']
      if should_med_network_policy
        should_med_network_policy.each do |policy|
          keys.each do |key|
            # return none when policy does not have the key
            val[key] = policy[key] || 'none'
          end
          conf_lines << "lldp med network-policy #{val['id']} "\
                        "app #{val['app']} vlan #{val['vlan']} "\
                        "vlan-type #{val['vlan-type']} "\
                        "priority #{val['priority']} dscp #{val['dscp']}"
        end
      end

      conf_lines.each { |value| info value }

      ecc conf_lines
      return
    rescue Exception => e
      err 'Exception in network policy='
      err e.message
      err e.backtrace[0]
      raise
    end
  end
end
