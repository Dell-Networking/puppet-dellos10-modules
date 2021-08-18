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
# Sample definition for os10_user resource:
#
# os10_user {'my_username':
#   ensure       => present,
#   password     => 'my_secret_password',
#   role         => 'netadmin',
#   priv_level   => 15,
#   ssh_key_type => key,
#   ssh_key      => 'ssh-rsa jhghgdjhgdjvgjvgh',
# }

require '/opt/dell/os10/bin/devops/dellos10_shell.rb'
require 'dellos10/util'

Puppet::Type.type(:os10_user).provide(:dellos10) do
  desc 'Dell Networking OS User Provider'

  alias_method :esc, :execute_show_command
  alias_method :ecc, :execute_config_command

  mk_resource_methods

  # Start the CLI shell server
  start_os10_shell

  def self.get_user_properties(svr)
    props = {
      :name => svr.delete(:name),
      :ensure  => :present,
    }
    svr.each_pair do |key, value|
      case key
      when :group
        props[:role] = value.to_sym
      when :'sshkey-type'
        props[:ssh_key_type] = value.to_sym
      when :sshkey
        props[:ssh_key] = value
      when :'privilege-level'
        props[:priv_level] = value.to_i
      end
    end
    props
  end

  def self.get_users(users)
    users = users.fetch(:user, [])
    users = [users] unless users.kind_of?(Array)

    users.map do |user|
      user_properties = get_user_properties(user)
      new(user_properties)
    end
  end

  def self.instances
    get_instances_from_running_config 'users' do |data|
      raise 'No users from "show run users"' unless data.has_key?(:'system')
      get_users(data[:'system'])
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
    cmd = "username #{resource[:name]}"
    cmd += " password #{resource[:password]}"
    cmd += " role #{resource['role']}"
    cmd += " priv-lvl #{resource['priv_level']}" if resource['priv_level']
    conf_lines << cmd

    if resource['ssh_key']
      cmd = "username #{resource[:name]} sshkey \"#{resource['ssh_key']}\""
      conf_lines << cmd
    end

    info("(create) command: #{conf_lines}")
    ecc conf_lines
  end

  def destroy
    conf_lines = []
    conf_lines << "no username #{resource[:name]}"
    conf_lines << "no username #{resource[:name]} sshkey"
    info("(destroy) conf_lines: #{conf_lines}")
    ecc [cmd]
  end

  def to_s
    "#{@resource}(provider=#{self.class.name}, " + @property_hash.collect { |k,v| "#{k}=#{v}" }.join(', ') + ')'
  end
end
