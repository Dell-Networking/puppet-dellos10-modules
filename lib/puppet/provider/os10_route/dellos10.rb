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
# This is pure ruby implementation of provider for os10_route resource.
# os10_route resource is an ensurable type. Hence we need to provide support for
# create, destroy, exists? methods.
# Sample definition for the route resource:
# os10_route{'route1':
#   destination        => '10.20.212.0',
#   prefix_len         => 24,
#   next_hop_list      => ['127.0.0.2', '127.0.0.3', '127.0.0.4'],
#   ensure             => present,
#   }
#

require 'ipaddr'
require '/opt/dell/os10/bin/devops/dellos10_shell.rb'

Puppet::Type.type(:os10_route).provide(:dellos10) do
  desc 'Dell Networking OS Interface Provider'

  alias_method :esc, :execute_show_command
  alias_method :ecc, :execute_config_command

  def init
    # The ruby CLI server will get started automatically from the client code
    begin
      ip = IPAddr.new(resource[:destination] + '/' + resource[:prefix_len])
      @type = 'ip' if ip.ipv4?
      @type = 'ipv6' if ip.ipv6?

      # This failure should not occur here as the IP is already validated.
      raise 'Invalid IP address' if @type.nil?
    rescue Exception
      raise "Invalid IP address #{resource[:destination]}"\
            "/#{resource[:prefix_len]}"
    end
  end

  def create
    info "os10_route::create for #{resource[:name]}"\
       " #{resource[:destination]}"\
       " #{resource[:prefix_len]}"\
       " #{resource[:next_hop_list]}"
    begin
      nhl = resource[:next_hop_list]
      conf_lines = []
      nhl.each do |v|
        conf_lines << "#{@type} route #{resource[:destination]}/"\
                      "#{resource[:prefix_len]} #{v}"
      end
      info "Executing #{conf_lines}"

      hret = ecc conf_lines
      debug hret
    rescue Exception => e
      err 'Exception in create'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def destroy
    info "os10_route::destroy for #{resource[:name]}"\
      " #{resource[:destination]}"\
      " #{resource[:prefix_len]}"\
      " #{resource[:next_hop_list]}"
    begin
      nhl = resource[:next_hop_list]
      conf_lines = []
      nhl.each do |v|
        conf_lines << "no #{@type} route #{resource[:destination]}/"\
                    "#{resource[:prefix_len]} #{v}"
      end
      info "Executing conf_lines #{conf_lines}"
      ecc conf_lines
    rescue Exception => e
      err 'Exception in destroy'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def exists?
    info "os10_route::exists? for #{resource[:name]}"\
       " #{resource[:destination]}"\
       " #{resource[:prefix_len]}"\
       " #{resource[:next_hop_list]}"
    begin
      start_os10_shell
      # If there is atleast one route entry for destination/prefix, we declare
      # the resource exists.

      init
      command_line = 'show running-configuration | grep '

      command_line += "\"#{@type} route #{resource[:destination]}/"\
                     "#{resource[:prefix_len]}\""
      info command_line
      nhl = []
      hret = esc command_line

      # Cache the output of the route
      # Consider caching the entire routes (not just for the given
      # prefix/len) to avoid multiple CLI calls when there are large number of
      # os10_route resources.
      info "hret is #{hret}"
      @routes = (hret.any? && hret.has_key?(:stdout)) ? hret[:stdout] : ''

      @routes = @routes.split("\n")
      info "routes cofigured: #{@routes}"

      !@routes.empty?
    rescue Exception => e
      err 'Exception in exists?'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def next_hop_list
    info "os10_route::next_hop_list for #{resource[:name]}"\
       " #{resource[:destination]}"\
       " #{resource[:prefix_len]}"\
       " #{resource[:next_hop_list]}"
    begin
      info @routes
      @is_nhl = []
      @routes.each do |v|
        @is_nhl << v.split(' ')[3..-1].reduce { |s, x| s + ' ' + x } if
          v.start_with? 'ip route'
      end

      # Filter out the nil element, if @routes contain something unexpected.
      @is_nhl.delete_if(&:nil?)

      # The next hop list should be sorted.
      # The input next_hop_list would have been already sorted by munge.
      @is_nhl.sort!
    rescue Exception => e
      err 'Exception in next_hop_list'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def next_hop_list=(nhl)
    info "os10_route::next_hop_list= #{nhl} for #{resource[:name]}"\
       " #{resource[:destination]}"\
       " #{resource[:prefix_len]}"\
       " #{resource[:next_hop_list]}"
    begin
      should_nhl = resource[:next_hop_list]
      add = should_nhl - @is_nhl
      del = @is_nhl - should_nhl

      conf_lines = []
      add.each { |v|
        conf_lines << "#{@type} route #{resource[:destination]}/"\
                      "#{resource[:prefix_len]} #{v}"
      }

      del.each { |v|
        conf_lines << "no #{@type} route #{resource[:destination]}/"\
                      "#{resource[:prefix_len]} #{v}"
      }

      info "adding nhl #{add}"
      info "deleting nhl #{del}"

      ecc conf_lines
    rescue Exception => e
      err 'Exception in next_hop_list='
      err e.message
      err e.backtrace[0]
      raise
    end
  end
end
