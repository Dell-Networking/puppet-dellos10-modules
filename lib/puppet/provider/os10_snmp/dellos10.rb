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
# Sample definition for os10_snmp resource:
# 
# os10_snmp{'snmpconf':
#   contact           => 'dellforce10@dell.com',
#   location          => 'Chennai-OTP',
#   community_strings => {'public'=>'ro', 'private'=>'ro','general'=>'ro'},
#   enabled_traps     => {'envmon'=>['fan','power-supply'],
#                         'snmp'=>['linkdown','linkup']},
#   trap_destination => {'10.1.1.1:12'=>['v1','public'],
#                            '10.2.2.2:123'   => ['v1','password']}
#

require '/opt/dell/os10/bin/devops/dellos10_shell.rb'

Puppet::Type.type(:os10_snmp).provide(:dellos10) do
  desc 'Dell Networking OS SNMP Provider'

  alias_method :esc, :execute_show_command
  alias_method :ecc, :execute_config_command

  # Start the CLI shell server
  start_os10_shell

  # This function will cache the SNMP configuration data during the beginning of
  # the provider execution. This is done to avoid multiple CLI reads and the
  # side effect is the SNMP configuration changes made by any other means during
  # the puppet execution period will not be read.
  def init
    begin
      if !@snmp
        debug 'Caching snmp configuration...'
        hret = esc 'show running-configuration snmp | display-xml'
        @snmp = hret[:stdout]['rpc-reply'][:data][:'snmp-server']
        info @snmp
        debug 'done!'
      end
    rescue Exception => e
      err 'Exception in init segment'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def contact
    init
    info 'Os10_snmp::contact'
    begin
      if @snmp[:global] && @snmp[:global].has_key?(:'sys-contact')
        return @snmp[:global][:'sys-contact']
      else
        return ''
      end
    rescue Exception => e
      err 'Exception in contact'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def contact=(str)
    info "Os10_snmp::contact= #{str}"
    begin
      if !str.empty?
        ecc ["snmp-server contact #{str}"]
      else
        ecc ['no snmp-server contact']
      end
    rescue Exception => e
      err 'Exception in contact='
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def location
    info 'os10_snmp::location'
    begin
      init
      if @snmp[:global] && @snmp[:global].has_key?(:'sys-location')
        info @snmp[:global]
        return @snmp[:global][:'sys-location']
      else
        return ''
      end
    rescue Exception => e
      err 'Exception in location'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def location=(str)
    str = "\"#{str}\"" if str.include?(' ')
    info "os10_snmp::location= #{str}"
    begin
      if !str.empty?
        ecc ["snmp-server location #{str}"]
      else
        ecc ['no snmp-server location']
      end
    rescue Exception => e
      err 'Exception in location='
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def community_strings
    info 'os10_snmp::community_strings'
    begin
      init
      @is_comm = {}

      return {} if !@snmp.has_key? :community

      comm = @snmp[:community]
      if !comm || (comm.class != Array)
        info 'community strings not configured'
        return {}
      end

      ret = {}
      comm.each do |element|
        ret[element[:'community-name']] = map_ro element[:'community-access']
      end
      @is_comm = ret
    rescue Exception => e
      err 'Exception in community_strings'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Utility-function to convert the string between CLI format and xml format
  def map_ro(str)
    return 'ro' if str == 'read-only'
    'undefined'
  end

  def community_strings=(should_comm)
    info 'os10_snmp::community_strings='
    info should_comm
    begin
      conf_lines = []
      del = {}
      add = {}

      if @is_comm && @is_comm.any?
        # config that need to be removed
        # is - should => delete
        del = Hash[@is_comm] # A simple assignment would just make it a reference
        del.delete_if { |key, _value| should_comm.has_key?(key) }
        debug "delete list is #{del}"
      end

      # config that needs to be added
      # should - is => add
      add = should_comm # This would add a reference. But that's OK.
      add.delete_if { |key, _value| @is_comm && @is_comm.has_key?(key) }
      debug "add list is #{add}"

      add.each do |key, value|
        conf_lines << "snmp-server community #{key} #{value}"
      end

      del.each do |key, _value|
        conf_lines << "no snmp-server community #{key}"
      end
      ecc conf_lines
    rescue Exception => e
      err 'Exception in community_strings='
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def enabled_traps
    info 'os10_snmp::enabled_traps'
    begin
      init
      ret = {}
      @is_traps = {}

      # This will throw NoMethodError exception if the traps are empty
      traps = @snmp[:'trap-notification'][:trap]
      if traps.class == Hash
        # This check is required because when there is only one option, the CLI
        # doesn't pack this in an array.
        traps = [traps]
      end
      # Sample value of traps can be
      # traps =
      # [{:"trap-name"=>"snmp", :"trap-snmp-option"=>["authentication",
      # "linkDown", "linkUp"]}, {:"trap-name"=>"envmon",
      # :"trap-envmon-option"=>"temperature"}]

      debug "configured traps are #{traps}"
      # If present, traps is an array
      traps.each do |ele|
        debug ele
        trap_option = ele[:'trap-name']
        debug "trap_option is #{trap_option}"
        trap_sub_options = ele[:"trap-#{trap_option}-option"]
        debug "trap_sup_options is #{trap_sub_options}"

        # trap_sub_options is a simple string in case of only one sub option
        # or an array in case of multiple sub options
        if trap_sub_options.class == Array
          trap_sub_options.map!(&:downcase)
          ret[trap_option] = trap_sub_options.sort
        else
          ret[trap_option] = [trap_sub_options.downcase]
        end
      end
      debug "returing #{ret}"
      @is_traps = ret
    rescue NoMethodError
      debug 'None of the traps are configured'
      {}
    rescue Exception => e
      err 'Exception in enabled_traps'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  # Helper function to carry out this transformation:
  # {'a'=>['1','2'], 'b'=>['3','4','5']} gets returned as
  # ['a 1', 'a 2', 'b 3', 'b 4', 'b 5']
  def conv_trap_to_conflines(traphash)
    ret = []
    # Sanity check of the argument
    if (traphash.class == Hash) && !traphash.empty? \
      && (traphash.values[0].class == Array)

      traphash.each_pair do |k, v|
        conflines = [k].product(v) # This is an array multiplication
        conflines.map! { |x| x[0] + ' ' + x[1] } # Convert the inner list to str
        ret += conflines
      end
    end
    ret
  end

  def enabled_traps=(should_traps)
    info 'os10_snmp::enabled_traps='
    info should_traps
    begin
      should_conf = conv_trap_to_conflines(should_traps)
      is_conf = conv_trap_to_conflines(@is_traps)

      # should - is => conf that needs to be added
      # is - should => conf that needs to be deleted
      add_conf = should_conf - is_conf
      del_conf = is_conf - should_conf

      debug "traps is #{is_conf}"
      debug "traps should be #{should_conf}"

      debug "adding traps #{add_conf}"
      debug "deleting traps #{del_conf}"

      add_conf.map! { |v| 'snmp-server enable traps ' + v }
      del_conf.map! { |v| 'no snmp-server enable traps ' + v }

      ecc(add_conf + del_conf)
    rescue Exception => e
      err 'Exception in enabled_traps='
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def trap_destination
    info 'os10_snmp::trap_destination'
    begin
      init
      @is_hosts = {}
      return {} if !@snmp.has_key? :'trap-recipient-host'

      hosts = @snmp[:'trap-recipient-host']
      if hosts.class == Hash
        # When there is only one trap entry, CLI doesn't pack it in an array
        hosts = [hosts]
      end

      ret = {}
      hosts.each do |host|
        iptup = "#{host[:'host-address']}:#{host[:'udp-port']}"
        # There seems to be some inconsistency in the way CLI returns w.r.t
        # version
        if host.has_key? :'security-model'
          if host[:'security-model'] == '2c'
            ver = 'v2'
          else
            ver = 'v2'
            warning "Unknown security model string #{host[:'security-model']}"\
            ' Defaulting to v2'
          end
        else
          ver = 'v1'
        end
        ret[iptup] = [ver, host[:'community-name']]
        info "key is #{iptup}, value is #{ret[iptup]}"
      end

      @is_hosts = ret
    rescue Exception => e
      err 'Exception in trap_destination'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def trap_destination=(should_hosts)
    info 'os10_snmp::trap_destination='
    info should_hosts
    begin
      conf_lines = []
      if !@is_hosts.none?
        # For each key in is...
        @is_hosts.each_pair do |k, v|
          # If the key is not there in should, remove it
          if !should_hosts.has_key? k
            # Remove k
            ip, udp = k.split(':')
            conf_lines << "no snmp-server host #{ip} junk udp-port #{udp}"
            info "removing key #{k} #{v}"
          else
            # If the key is present, but value is different that should, remove it
            if v != should_hosts[k]
              # Remove k
              ip, udp = k.split(':')
              conf_lines << "no snmp-server host #{ip} junk udp-port #{udp}"
              info "removing key #{k} #{v}"
            end
          end
        end
      end

      if !should_hosts.none?
        # For each key in should...
        should_hosts.each_pair do |k, v|
          # If the key is not there in is, add it
          if @is_hosts && !@is_hosts.has_key?(k)
            # Add k
            if (v[0] != 'v1') && (v[0] != 'v2')
              warning "Invalid version #{v[0]}. Defaulting to v1"
            end
            ver = (v[0] == 'v2') ? '2c' : '1'
            ip, udp = k.split(':')
            conf_lines << "snmp-server host #{ip} traps version #{ver} #{v[1]}"\
              " udp-port #{udp}"
            info "Adding key #{k} #{v}"
          else
            if v != @is_hosts[k]
              # Add k
              if (v[0] != 'v1') && (v[0] != 'v2')
                warning "Invalid version #{v[0]}. Defaulting to v1"
              end
              ver = (v[0] == 'v2') ? '2c' : '1'
              ip, udp = k.split(':')
              conf_lines << "snmp-server host #{ip} traps version #{ver} #{v[1]}"\
                " udp-port #{udp}"
              info "Adding key #{k} #{v}"
            end
          end
        end
      end

      info 'commiting the following changes:'
      conf_lines.each { |v| info v }
      ecc conf_lines
    rescue Exception => e
      err 'Exception in trap_destination='
      err e.message
      err e.backtrace[0]
      raise
    end
  end
end
