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
# Resource definition for the os10_image_upgrade type that is used to upgrade
# the OS10 operating system of a Dell EMC Networking device.
#
# Sample resource:
# node 'os1039'{
#   os10_image_upgrade{'v1':
#     image_url =>
#     'tftp://10.16.148.8:/PKGS_OS10-Enterprise-10.3-installer-x86_64.bin'
#   }
# }
#   
Puppet::Type.newtype(:os10_image_upgrade) do
  desc 'os10_image_upgrade resource type is used to upgrade / downgrade OS10EE'\
  ' images by providing the filename and location of the image.'

  newparam(:name, namevar: true) do
    desc 'The name parameter for the image upgrade resource. This parameter is'\
    ' not used in any of the configuration.'
  end

  newproperty(:image_url) do
    desc 'This is the location of the binary image in the remote server. This'\
    ' image will be downloaded and installed in the switch.'
  end
end
