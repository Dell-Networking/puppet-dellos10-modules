# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# Author::     Neil Hemingway (neil.hemingway@greyhavens.org.uk)
# Copyright::  Copyright (c) 2021, Dell Inc. All rights reserved.
# License::    [Apache License] (http://www.apache.org/licenses/LICENSE-2.0)
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require '/opt/dell/os10/bin/devops/dellos10_shell.rb'

def get_instances_from_running_config(entity, &block)
  res = []

  begin
    debug "Fetching #{entity} config..."
    cmd = "show running-configuration #{entity} | display-xml"
    hret = execute_show_command(cmd, timeout=60)
    raise "No rpc-reply from '#{cmd}'" unless hret[:stdout] and hret[:stdout].length > 0
    data = hret[:stdout]['rpc-reply'][:data]
    res = block.call(data)
    info("#{entity} instances: #{res}")
    res
  rescue Exception => e
    err 'Exception in get_instances_from_running_config'
    err e.message
    err "hret: #{hret}"
    err e.backtrace[0]
    raise
  end

  res
end
