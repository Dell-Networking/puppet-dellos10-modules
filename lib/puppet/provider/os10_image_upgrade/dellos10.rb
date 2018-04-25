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
# This Puppet provider is implementation for installing any image available in the
# remote location. The image is downloaded and installed in the standby partition.
# The provider code will monitor the progress of the installation procedure by
# periodically polling for the status of the installer. Once the installation is
# complete the system boot marker is set to the standby partition, where the new
# image is installed and a reload is triggered. Any unsaved configuration is saved
# before the reload.
#

require '/opt/dell/os10/bin/devops/dellos10_shell.rb'

Puppet::Type.type(:os10_image_upgrade).provide(:dellos10) do
  alias_method :esc, :execute_show_command
  alias_method :ecc, :execute_config_command

  start_os10_shell

  def image_url
    info "os10_image_upgrade::image_url for #{resource[:name]}"
    begin
      command = 'show version | grep "OS Version"'
      ret = esc command
      debug ret
    rescue Exception => e
      err 'Exception in __function__'
      err e.message
      err e.backtrace[0]
      raise
    end
  end

  def image_url=(url)
    info "os10_image_upgrade::image_url for #{resource[:name]}"
    info "url is #{url}"
    begin
      # Get the status of downloader before initiating install
      hret = esc 'show image status | display-xml'
      status = hret[:stdout]['rpc-reply'][:data][:'system-sw-state']
      state = status[:'software-upgrade-status'][:'global-state']

      raise "Installer state #{state} != idle. Aborting Download!" if state != 'idle'

      command = "image install #{url}"
      esc command

      # Periodically check for the status of download
      oldstate = state
      loop do
        hret = esc 'show image status | display-xml'
        status = hret[:stdout]['rpc-reply'][:data][:'system-sw-state']
        state = status[:'software-upgrade-status'][:'global-state']
        perc = status[:'software-upgrade-status'][:'file-transfer-status']\
          [:'file-progress']
        insst = status[:'software-upgrade-status'][:'software-install-status']\
          [:'task-state-detail']

        debug "state is #{state} #{perc}% #{insst}"
        if oldstate != state
          info "Installer state changed from #{oldstate} to #{state}"
          if state == 'idle'
            # When the installer goes back to idle state from install
            debug "Breaking out from loop during #{oldstate} to #{state}"\
                 ' transition'
            break
          end
          oldstate = state
        end
        sleep(1)
      end

      # Now that installer is idle, check for State Detail of both File Transfer
      # and Installation State before initiating a reload

      stat1 = status[:"software-upgrade-status"][:"file-transfer-status"]\
            [:"task-state-detail"]
      stat2 = status[:"software-upgrade-status"][:"software-install-status"]\
            [:"task-state-detail"]

      if (stat1 == 'Completed: No error') && (stat2 == 'Completed: Success')
        debug "Download state is #{stat1}"
        debug "Install state is #{stat2}"
        info 'reloading to standby partition'
        esc 'boot system standby'
        esc 'write memory'
        esc 'reload'
        sleep(1)
        esc 'yes'
      else
        err "Download state is #{stat1}"
        err "Install state is #{stat2}"
        raise 'Install failed!'
      end
    rescue Exception => e
      err 'Exception in __function__'
      err e.message
      err e.backtrace[0]
      raise
    end
  end
end
