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
# Sample definition for os10_privilege resource:
#
# os10_privilege { "$mode:$priv_level:$command": }

require '/opt/dell/os10/bin/devops/dellos10_shell.rb'
require 'dellos10/util'

Puppet::Type.type(:os10_privilege).provide(:dellos10) do
  desc 'Dell Networking OS Privilege Provider'

  alias_method :esc, :execute_show_command
  alias_method :ecc, :execute_config_command

  mk_resource_methods

  # Start the CLI shell server
  start_os10_shell

  def self.get_privilege_properties(priv)
    info("priv: #{priv}")
    props = {
      :priv_level => priv.delete(:level).to_i,
      :ensure  => :present,
    }
    priv[:mode].each_pair do |key, value|
      case key
      when :'mode-name'
        props[:mode] = value
      when :command
        props[:command] = value
      when :'permit-param'
        props[:permit_param] = value
      end
    end
    props[:name] = "#{props[:mode]}:#{props[:priv_level]}:#{props[:command]} #{props[:permit_param]}"
    props
  end

  def self.get_privileges(privileges)
    privileges = privileges.fetch(:privilege, [])
    privileges = [privileges] unless privileges.kind_of?(Array)

    privileges.map do |privilege|
      privilege_properties = get_privilege_properties(privilege)
      new(privilege_properties)
    end
  end

  def self.instances
    get_instances_from_running_config 'privilege' do |data|
      raise 'No users from "show run privilege"' unless data.has_key?(:'privilege-level-config')
      get_privileges(data[:'privilege-level-config'])
    end
  end

  def self.prefetch(resources)
    debug 'Prefetching users...'
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
    conf_lines = []
    cmd = "privilege #{resource[:mode]}"
    cmd += " priv-lvl #{resource['priv_level']}"
    cmd += " \"#{resource['command']} #{resource['permit_param']}\""
    conf_lines << cmd

    debug("(create) command: #{conf_lines}")
    ecc conf_lines
  end

  def destroy
    conf_lines = []
    cmd = "no privilege #{resource[:mode]}"
    cmd += " priv-lvl #{resource['priv_level']}"
    cmd += " \"#{resource['command']} #{resource['permit_param']}\""
    conf_lines << cmd
    debug("(destroy) conf_lines: #{conf_lines}")
    ecc conf_lines
  end

  def to_s
    "#{@resource}(provider=#{self.class.name}, " + @property_hash.collect { |k,v| "#{k}=#{v}" }.join(', ') + ')'
  end
end
