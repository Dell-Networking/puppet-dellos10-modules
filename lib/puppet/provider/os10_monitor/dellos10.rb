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
# This is pure ruby implementation of provider for os10_monitor resource.
# os10_monitor resource is an ensurable type. Hence we need to provide support for
# create, destroy, exists? methods.
# Sample definition for the monitor resource:
#   os10_monitor{'session1':
#     id          => 1
#     source      => ['ethernet 1/1/9', 'ethernet 1/1/8'],
#     destination => 'ethernet 1/1/10',
#     flow_based  => true,
#     shutdown    => false,
#     ensure      => present,
#   }
#

require 'ipaddr'
require '/opt/dell/os10/bin/devops/dellos10_shell.rb'

Puppet::Type.type(:os10_monitor).provide(:dellos10) do
  desc 'Dell Networking OS Monitor Provider'

  alias_method :esc, :execute_show_command
  alias_method :ecc, :execute_config_command

  start_os10_shell

  def init
    # The ruby CLI server will get started automatically from the client code
  end

  def create
    debug "os10_monitor::create for #{resource[:name]}"
    begin
      info resource[:source]
      info resource[:destination]

      conf_lines = []
      conf_lines << "monitor session #{resource[:id]}"

      resource[:source].each do |v|
        # Interfaces names should have been validated in the type.
        conf_lines << "source interface #{v}"
      end

      conf_lines << "destination interface #{resource[:destination]}"

      if resource[:flow_based]
        conf_lines << 'flow-based enable'
      else
        conf_lines << 'no flow-based enable'
      end

      # When the session is shutdown, there will not be a "shut" in running
      # config. Rather when the session is enabled, there will be a "no shut" in
      # the config. i.e, the monitor is by default in shutdown mode unless
      # explicitly given "no shut" config.
      notice resource[:shutdown]
      if resource[:shutdown]
        conf_lines << 'shut'
      else
        conf_lines << 'no shut'
      end

      info 'executing '
      info conf_lines

      ecc conf_lines
    rescue Exception => e
      err 'Exception in create'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def destroy
    debug "os10_monitor::destroy for #{resource[:name]}"
    begin
      ecc ["no monitor session #{resource[:id]}"]
    rescue Exception => e
      err 'Exception in destroy'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def exists?
    debug "os10_monitor::exists? for #{resource[:name]}"\
       " #{resource[:id]}"\
       " #{resource[:source]}"\
       " #{resource[:destination]}"\
       " #{resource[:flow_based]}"\
       " #{resource[:shutdown]}"
    begin
      ret = esc 'show running-configuration monitor | display-xml'

      # If there is a session present, the following keys will be present in the
      # ret hash.
      sessions = ret[:stdout]['rpc-reply'][:data][:"sessions"]

      info "sessions are #{sessions}"

      if sessions
        # There is atleast one session configured
        sessions = sessions[:session]
      else
        # There are no monitor sessions configured
        @sess = nil
        return false
      end

      # sessions will be an array if there are multiple entries or a Hash if
      # there is only one entry.
      sessions = [sessions] if sessions && sessions.class == Hash

      sessions.each do |v|
        @sess = v if Integer(v[:id]) == resource[:id]
      end

      info "exists? returning #{@sess != nil}"
      @sess != nil
    rescue Exception => e
      err 'Exception in exists?'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def source
    debug "os10_monitor::source for #{resource[:name]}"
    begin
      ret = []
      sources = @sess[:'source-intf']

      # sources will be an array if there are multiple entries or Hash if there
      # is only one entry
      sources = [sources] if sources.class == Hash
      sources.each do |v|
        intf = v[:name]
        # info "source interface is #{intf}"
        # convert "ethernet1/1/1" to "ethernet 1/1/1"
        ret << intf.sub(%r{[a-z]*}) { |x| x + ' ' }
      end
      # No need to sort here as we already sort and compare in the type defn.
      info "returning #{ret}"
      @is_sources = ret
    rescue Exception => e
      err 'Exception in source'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def source=(should_sources)
    debug "os10_monitor::source= #{should_sources} for #{resource[:name]}"
    begin
      info "is_sources is #{@is_sources}"
      add = should_sources - @is_sources
      del = @is_sources - should_sources

      conf_lines = ["monitor session #{resource[:id]}"]

      info "adding sources: #{add}"
      add.each { |v| conf_lines << "source interface #{v}" }

      info "deleting sources: #{del}"
      del.each { |v| conf_lines << "no source interface #{v}" }

      ecc conf_lines
    rescue Exception => e
      err 'Exception in source='
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def destination
    debug "os10_monitor::destination for #{resource[:name]}"
    begin
      @intf = ''
      if @sess.has_key? :'destination-interface'
        @intf = @sess[:'destination-interface']
        info "intf is #{@intf}"
        @intf.sub!(%r{[a-z]*}) { |v| v + ' ' }
        info "intf is #{@intf}"
      end
      info "destination is #{@intf}"
      @intf
    rescue Exception => e
      err 'Exception in destination'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def destination=(dest)
    debug "os10_monitor::destination= #{dest} for #{resource[:name]}"
    begin
      conf_lines = ["monitor session #{resource[:id]}"]
      conf_lines << "no destination interface #{@intf}" if !@intf.empty?

      # An empty string would simply remove the existing destination interface
      conf_lines << "destination interface #{dest}" if !dest.empty?

      info 'executing... '
      info conf_lines
      ecc conf_lines
    rescue Exception => e
      err 'Exception in destination='
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def flow_based
    debug "os10_monitor::flow_based for #{resource[:name]}"
    begin
      ret = @sess.has_key? :'flow-enabled'
      info "flow_based is returned as #{ret} for session "\
        "#{resource[:id]}"
      ret
    rescue Exception => e
      err 'Exception in flow_based'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def flow_based=(val)
    debug "os10_monitor::flow_based= #{val} for #{resource[:name]}"
    begin
      conf_lines = ["monitor session #{resource[:id]}"]

      # val would be a string 
      if val.to_s == 'true'
        conf_lines << 'flow-based enable'
      else
        conf_lines << 'no flow-based enable'
      end
      info 'executing...'
      info conf_lines
      ecc conf_lines
    rescue Exception => e
      err 'Exception in flow_based='
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def shutdown
    debug "os10_monitor::shutdown for #{resource[:name]}"
    begin
      # When the session is shutdown, there will not be a "shut" in running
      # config. Rather when the session is enabled, there will be a "no shut" in
      # the config. i.e, the monitor is by default in shutdown mode unless
      # explicitly given "no shut" config.

      if @sess.has_key? :disable
        if @sess[:disable] == 'false'
          shut = false
        else
          err "Unexpected value for disable = #{@sess[:disable]}. Considering"\
          ' as true'
          shut = true
        end
      else
        shut = true
      end

      info "shutdown is returned as #{shut} for session #{resource[:id]}"
      shut
    rescue Exception => e
      err 'Exception in shutdown'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def shutdown=(val)
    debug "os10_monitor::shutdown= #{val} for #{resource[:name]}"
    begin
      conf_lines = ["monitor session #{resource[:id]}"]

      # val would be a string
      if val == 'true'
        conf_lines << 'shut'
      else
        conf_lines << 'no shut'
      end
      info 'executing...'
      info conf_lines
      ecc conf_lines
    rescue Exception => e
      err 'Exception in shutdown='
      err e.message
      err e.backtrace[0]
      raise
    end
  end
end
