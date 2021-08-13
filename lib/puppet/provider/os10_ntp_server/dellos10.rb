# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# Author::     Neil Hemingway (neil.hemingway@greyhavens.org.uk)
# Copyright::  Copyright (c) 2018, Dell Inc. All rights reserved.
# License::    [Apache License] (http://www.apache.org/licenses/LICENSE-2.0)
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Sample definition for os10_ntp_server resource:
#
# os10_ntp_server {'time.domain.com':
#   ensure => present,
#   key    => 123,
#   prefer => true,
# }

require '/opt/dell/os10/bin/devops/dellos10_shell.rb'
require 'dellos10/util'

Puppet::Type.type(:os10_ntp_server).provide(:dellos10) do
  desc 'Dell Networking OS NTP Provider'

  alias_method :ecc, :execute_config_command

  mk_resource_methods

  # Start the CLI shell server
  start_os10_shell

  def self.get_server_properties(svr)
    res = {
      :name => svr.delete(:address),
      :ensure  => :present,
    }
    svr.each_pair do |key, value|
      typekey = key == 'key-id' ? :key : key.to_sym
      res[typekey] = case value
                        when /^(true|false)$/
                          value == 'true' ? true : false
                        when /^\d+$/
                          value.to_i
                        else
                          value
                        end
      debug("Converted #{key}, #{value} -> #{typekey}, #{res[typekey]}")
    end
    debug("Server properties: #{res}")
    res
  end

  def self.get_ntp_servers(ntp_config)
    svrs = ntp_config.fetch(:servers, {})
    if !svrs
      info 'servers not configured'
      return []
    end
    svrs = svrs.fetch(:server,{})
    svrs = [svrs] unless svrs.kind_of?(Array)

    res = svrs.map do |svr|
      server_properties = get_server_properties(svr)
      new(server_properties)
    end
    debug("Servers: #{res}")
    res
  end

  def self.instances
    get_instances_from_running_config 'ntp' do |data|
      raise 'No ntp-config from "show run ntp"' unless data.has_key?(:'ntp-config')
      get_ntp_servers(data[:'ntp-config'])
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    cmd = "ntp server #{resource[:name]}"
    cmd += " key #{resource['key']}" if resource['key']
    cmd += ' prefer' if resource['prefer']
    info("(create) command: #{cmd}")
    ecc [cmd]
  end

  def destroy
    cmd = "no ntp server #{resource[:name]}"
    info("(destroy) conf_lines: #{cmd}")
    ecc [cmd]
  end

  def to_s
    "#{@resource}(provider=#{self.class.name}, name=#{self.name})"
  end
end
