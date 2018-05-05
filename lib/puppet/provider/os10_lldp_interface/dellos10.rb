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
# This is pure ruby implementation of provider for os10_lldp_interface resource.
#

# Sample definition for os10_lldp_interface resource:

# os10_lldp_interface { 'ethernet 1/1/1':
#   receive                  => 'true',
#   transmit                 => 'true',
#   med                      => 'true',
#   med_network_policy       => ["7", "8"],
#   med_tlv_select_inventory => 'false',
#   med_tlv_select_network_policy => 'true',
#   tlv_select              => {"dcbxp"=>[""],"dot1tlv"=>["link-aggregation"],
#                              "dot3tlv"=>["max-framesize"]}
# }

require '/opt/dell/os10/bin/devops/dellos10_shell.rb'

Puppet::Type.type(:os10_lldp_interface).provide(:dellos10) do
  desc 'Dell Networking OS LLDP Interface Provider'

  attr_reader :receive
  attr_reader :transmit
  attr_reader :med
  attr_reader :med_network_policy
  attr_reader :med_tlv_select_inventory
  attr_reader :med_tlv_select_network_policy
  attr_reader :tlv_select

  alias_method :esc, :execute_show_command
  alias_method :ecc, :execute_config_command

  # Start the CLI shell server
  start_os10_shell

  # This function will cache the LLDP Interface configuration data during
  # the beginning of the provider execution. This is done to avoid multiple
  # CLI reads and the side effect is the LLDP configuration changes made
  # by any other means during the puppet execution period will not be read.
  def initialize(*args)
    @interface_name = args[0].name
    super(*args)
    begin
      debug 'Caching lldp interface related configuration...'
      ret = esc 'show running-configuration interface ' +
                 @interface_name + ' | display-xml'
      @tlv_ret = esc 'show running-configuration interface ' + @interface_name
      @lldp_intf = ret[:stdout]['rpc-reply'][:data][:interfaces][:interface]
      info "lld int #{@lldp_intf}"
    rescue Exception => e
      err 'Exception in init segment'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function to get and return the receive value of Interface LLDP configuration
  def receive
    info 'os10_lldp_interface::receive'
    begin
      @lldp_interface_lldp = @lldp_intf[:lldp] || {}
      return @lldp_interface_lldp[:'rx-enable'] || ''
    rescue Exception => e
      err 'Exception in receive'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function inputs a boolean value string to set the value of receive in config
  # and return the exec of lldp configuration command
  def receive=(val)
    info "os10_lldp_interface::receive= #{val}"
    begin
      conf_lines = []
      conf_lines << "interface #{@interface_name}"
      conf_lines << 'lldp receive' if receive == 'false' && val == 'true'
      conf_lines << 'no lldp receive' if val == 'false'
      conf_lines.each { |value| info value }
      ecc conf_lines
      return
    rescue Exception => e
      err 'Exception in receive='
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function to get and return the transmit value of
  # Interface LLDP configuration
  def transmit
    info 'os10_lldp_interface::transmit'
    begin
      @lldp_interface_lldp = @lldp_intf[:lldp] || {}
      return @lldp_interface_lldp[:'tx-enable'] || ''
    rescue Exception => e
      err 'Exception in transmit'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function inputs a boolean value string to set the value of
  # transmit in config and return the exec of lldp configuration command
  def transmit=(val)
    info "os10_lldp_interface::transmit= #{val}"
    begin
      conf_lines = []
      conf_lines << "interface #{@interface_name}"
      conf_lines << 'lldp transmit' if transmit == 'false' && val == 'true'
      conf_lines << 'no lldp transmit' if val == 'false'
      conf_lines.each { |value| info value }
      ecc conf_lines
      return
    rescue Exception => e
      err 'Exception in transmit='
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function to get and return the med value of Interface LLDP configuration
  def med
    info 'os10_lldp_interface::med'
    begin
      @lldp_interface_med = @lldp_intf[:'lldp-med-cfg'] || {}
      return @lldp_interface_med[:'med-enable'] || ''
    rescue Exception => e
      err 'Exception in med'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function inputs a boolean value string to set the value of med in config
  # and return the exec of lldp configuration command
  def med=(val)
    info "os10_lldp_interface::med= #{val}"
    begin
      conf_lines = []
      conf_lines << "interface #{@interface_name}"
      conf_lines << 'lldp med enable' if med == 'false' && val == 'true'
      conf_lines << 'lldp med disable' if val == 'false'
      conf_lines.each { |value| info value }
      ecc conf_lines
      return
    rescue Exception => e
      err 'Exception in med='
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function to get and return the med tlv select inventory value of
  # Interface LLDP configuration
  def med_tlv_select_inventory
    info 'os10_lldp_interface::med tlv select inventory'
    begin
      @lldp_interface_med_cfg = @lldp_intf[:'lldp-med-cfg'] || {}
      @lldp_interface_med_tlv = @lldp_interface_med_cfg[:'tlvs-tx-enable'] || {}
      return @lldp_interface_med_tlv[:inventory] || ''
    rescue Exception => e
      err 'Exception in med tlv select inventory'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function inputs a boolean value string to set the value of
  # med tlv select inventory
  # in config and return the exec of lldp configuration command
  def med_tlv_select_inventory=(val)
    info "os10_lldp_interface::med tlv select inventory= #{val}"
    begin
      conf_lines = []
      conf_lines << "interface #{@interface_name}"
      conf_lines << 'lldp med tlv-select inventory' if val == 'true'
      if val == 'false' && med_tlv_select_inventory == 'true'
        conf_lines << 'no lldp med tlv-select inventory'
      end
      conf_lines.each { |value| info value }
      ecc conf_lines
      return
    rescue Exception => e
      err 'Exception in med tlv select inventory='
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function to get and return the med tlv select network policy value
  # of Interface LLDP configuration
  def med_tlv_select_network_policy
    info 'os10_lldp_interface::med tlv select network policy'
    begin
      @lldp_interface_med_cfg = @lldp_intf[:'lldp-med-cfg'] || {}
      @lldp_interface_med_tlv = @lldp_interface_med_cfg[:'tlvs-tx-enable'] || {}
      return @lldp_interface_med_tlv[:'network-policy'] || ''
    rescue Exception => e
      err 'Exception in med tlv select network policy'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function inputs a boolean value string to set the value of med tlv select
  # network policy in config and return the exec of lldp configuration command
  def med_tlv_select_network_policy=(val)
    info "os10_lldp_interface::med tlv select network policy= #{val}"
    begin
      conf_lines = []
      conf_lines << "interface #{@interface_name}"
      if med_tlv_select_network_policy == 'false' && val == 'true'
        conf_lines << 'lldp med tlv-select network-policy'
      end
      conf_lines << 'no lldp med tlv-select network-policy' if val == 'false'
      conf_lines.each { |value| info value }
      ecc conf_lines
      return
    rescue Exception => e
      err 'Exception in med tlv select network policy='
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function to get and return the med network policy value of
  # Interface LLDP configuration
  def med_network_policy
    info 'os10_lldp_interface::med_network_policy'
    begin
      lldp_interface_med = @lldp_intf[:'lldp-med-cfg'] || {}
      @lldp_med_nw_policy = lldp_interface_med[:'policy-id'] || []
      info "lldp med policy #{@lldp_med_nw_policy}"
      return [@lldp_med_nw_policy] if @lldp_med_nw_policy.class == String
      return @lldp_med_nw_policy
    rescue Exception => e
      err 'Exception in network policy'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function inputs an array of med_network_policy values to set the
  # network policies and return the exec of lldp configuration command
  def med_network_policy=(should_med_network_policy)
    info "os10_lldp_interface::med_network_policy=#{should_med_network_policy}"
    begin
      conf_lines = []
      if med_network_policy
        remove = med_network_policy - should_med_network_policy
        remove.each do |policy|
          conf_lines << "interface #{@interface_name}"
          conf_lines << "lldp med network-policy remove #{policy}"
        end
      end
      if should_med_network_policy
        should_med_network_policy.each do |policy|
          conf_lines << "interface #{@interface_name}"
          conf_lines << "lldp med network-policy add #{policy}"
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

  # Function to get and return the tlv select value of
  # Interface LLDP configuration
  def tlv_select
    info 'os10_lldp_interface::tlv select'
    begin
      lldp_interface_data = @tlv_ret[:stdout].split("\n")
      temp_data = {}

      lldp_interface_data.each do |data|
        if data.include? 'lldp tlv-select'
          tlv_data = data.split(' ')
          if tlv_data.length == 4
            temp_data[tlv_data[3]] = [' ']
          elsif temp_data[tlv_data[3]].nil? && tlv_data.length >= 4
            temp_data[tlv_data[3]] = [tlv_data[4]]
          elsif tlv_data[4]
            temp_data[tlv_data[3]] = temp_data[tlv_data[3]] << tlv_data[4]
            temp_data[tlv_data[3]] = temp_data[tlv_data[3]].sort
          end
        end
      end
      return temp_data
    rescue Exception => e
      err 'Exception in tlv select'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Function inputs an hash of tlv select to set
  # and return the exec of lldp configuration command
  def tlv_select=(should_tlv_select)
    info "os10_lldp_interface::tlv_select=#{should_tlv_select}"
    begin
      # if both the current and new inputs are not empty,
      if !tlv_select.empty? && !should_tlv_select.empty?
        conf_lines = []
        conf_lines << "interface #{@interface_name}"
        # loop through the new configuration values and check if
        # the keys are already present in the configuration,
        should_tlv_select.each do |key, _value|
          if tlv_select.include? key
            enable = tlv_select[key] - should_tlv_select[key]
            enable.each do |tlvs|
              # enable the tlv-select that is not present in the new config
              conf_lines << "lldp tlv-select #{key} #{tlvs}"
            end
          # disable the tlv-select that needs to be configured
          else
            disable = should_tlv_select[key]
            if key == 'dcbxp'
              conf_lines << "no lldp tlv-select #{key}"
            else
              disable.each do |tlvs|
                conf_lines << "no lldp tlv-select #{key} #{tlvs}"
              end
            end
          end
        end
        # loop through the configuration values already present in the device
        # and check if the keys match with new configs
        tlv_select.each do |k, _v|
          if should_tlv_select.include? k
            disable = should_tlv_select[k] - tlv_select[k]
            disable.each do |tlvs|
              # disable the tlv-select that is not present in config
              # and needs to be configured newly
              conf_lines << "no lldp tlv-select #{k} #{tlvs}"
            end
          # enable the tlv-select that does not match with new configuration
          else
            enable = tlv_select[k]
            enable.each do |tlvs|
              conf_lines << "lldp tlv-select #{k} #{tlvs}"
            end
          end
        end
        conf_lines.each { |val| info val }
        ecc conf_lines

      # if the new configuration is empty and there are config already present
      # in the device, enable them
      elsif should_tlv_select.empty? && !tlv_select.empty?
        tlv_select.each do |key, _value|
          enable = tlv_select[key]
          conf_lines = []
          conf_lines << "interface #{@interface_name}"
          enable.each do |tlvs|
            conf_lines << "lldp tlv-select #{key} #{tlvs}"
          end
          conf_lines.each { |val| info val }
          ecc conf_lines
        end

      # if there are no configuration present in the device, disable all
      # the new tlv-select
      else
        should_tlv_select.each do |key, _value|
          disable = should_tlv_select[key]
          conf_lines = []
          conf_lines << "interface #{@interface_name}"
          disable.each do |tlvs|
            conf_lines << "no lldp tlv-select #{key} #{tlvs}"
          end
          conf_lines.each { |val| info val }
          ecc conf_lines
        end
        return
      end
    rescue Exception => e
      err 'Exception in tlv select'
      err e.message
      err e.backtrace[0]
      raise
    end
  end
end
