# Puppet dellos10 module

## Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with dellos10](#beginning-with-dellos10)
4. [Usage](#usage)
5. [Limitations](#limitations)
6. [Known Issues](#known-issues)
7. [Change Log](#change-log)
8. [Development](#development)
9. [License](#license)

## Overview

The dellos10 module is used to manage configuration of Dell Networking devices running OS10 operating system. This module provides Puppet Types, Providers and sample manifests for various features of the OS10 software.

## Module Description

The current version of dellos10 module contains Providers that makes use of OS10 operating system's configuration CLIs. 

The `dellos10` module is dependant on the following ruby modules:

* `os10_devops_ruby_utils`

## Setup

### Setup Requirements

#### Installing `os10_devops_ruby_utils` module

The dellos10 puppet module requires `os10_devops_ruby_utils` module to be installed separately for communicating with the underlying OS10 operating system. The installation procedure can be found at [readthedocs.org](https://readthedocs.org/projects/puppet-dellos-docs/)

### Beginning with dellos10

```bash
puppet module install dellemcnetworking-dellos10
```

For more information on Puppet module installation see [Puppet Labs: Installing Modules](https://docs.puppetlabs.com/puppet/latest/reference/modules_installing.html)

## Usage

The following Puppet resources are defined as part of `dellos10` module.

* [`os10_route`](#type-os10_route)
* [`os10_snmp`](#type-os10_snmp)
* [`os10_monitor`](#type-os10_monitor)
* [`os10_interface`](#type-os10_interface)
* [`os10_image_upgrade`](#type-os10_image_upgrade)
* [`os10_bgp`](#type-os10_bgp)
* [`os10_bgp_af`](#type-os10_bgp_af)
* [`os10_bgp_neighbor`](#type-os10_bgp_neighbor)
* [`os10_bgp_neighbor_af`](#type-os10_bgp_neighbor_af)
* [`os10_lldp`](#type-os10_lldp)
* [`os10_lldp_interface`](#type-os10_lldp_interface)

### Type: os10_route

`os10_route` resource type is used to manage static routes in OS10 switches.

#### Attributes

##### `destination`
Target IP address to which the route must be configured.

##### `prefix_len`
Netmask of the target IP address.

##### `next_hop_list`
List of next hop IP address for the route to be configured.

##### `ensure`
Determine whether the route entry should be present or not.

### Type: os10_snmp
`os10_snmp` resource type is to used to manage SNMP configuration in OS10 EE switches. The os10_snmp resource is not an ensurable type and hence does not have an ensure attribute.

#### Attributes

##### `community_strings`
This property is a dictionary of community string with its access right. These will be the only list of community string entries present in the SNMP configuration. eg:{'public'=>'ro', 'private'=>'rw'}.

##### `contact`
Contact property of SNMP server. There can be only one entry for contact. An empty string for contact will remove the contact entry from the SNMP configuration.

##### `location`
Location property of the SNMP server. There can be only one entry for location. An empty string for location will remove the location entry.

##### `enabled_traps`
This will be a dictionary of entries where the key is trap category and values are the list of subcategory or :all to enable traps for all sub category items.

##### `trap_destination`
This will be a dictionary of entries where the key is list of [ip,Port] and value is a list with version string ("v1"/"v2") and community string.


### Type: os10_monitor
`os10_monitor` resource type is to used to manage port monitor (mirroring) session configuration in OS10 EE switches.

#### Attributes

##### `ensure`
Determines whether this monitor configuration should exist or not.

##### `id`
This property is an integer that is configured as the id of the monitor session in the switch. The id needs to be unique and should be an integer between 1 and 18.

##### `source`
This property is an array of string values of the interfaces that will be configured as source interfaces for this monitoring session. eg) ['ethernet 1/1/9', 'ethernet 1/1/10']

##### `destination`
This property is a string name of the destination interface to which traffic has to be mirrored. eg) 'ethernet 1/1/10'

##### `flow_based`
This property is a boolean value specifying whether to enable or disable flow based monitoring. This is an optional attribute defaulted to false.

##### `shutdown`
This property will decide whether to enable or disable the monitor session. If the shutdown is false, the session will be configured but in shutdown state. This is an optional attribute defaulted to true.


### Type: os10_interface
`os10_interface` resource type is used to manage interface configuration in OS10 switches.

#### Attributes

##### `desc`
String containing description of the interface.

##### `mtu`
String containing maximum transmission unit of the interface.

##### `switchport_mode`
Switchport mode of the interface. Can be either trunk or access in case of switchport. Or can be false when not in L2 mode. Valid values are 'trunk', 'access' and 'absent'.

##### `admin`
Administrative state of the interface. Valid values are 'up' and 'down'.

##### `ip_address`
String containing ipv4 address and mask of the interface in ip/prefixlen format.

##### `ipv6_address`
String containing ipv6 address and mask of the interface in ip/prefixlen format.

##### `ipv6_autoconfig`
Boolean value to enable or disable ipv6 autoconfig. Valid values are 'true' and 'false'

###### `ip_helper`
List containing string of IP address for the interface to which UDP broadcasts need to be forwarded.


### Type: os10_image_upgrade
`os10_image_upgrade` resource type is used to upgrade / downgrade OS10EE images by providing the filename and location of the image.

#### Attributes

##### `image_url`
This is the location of the binary image in the remote server. This image will be downloaded and installed in the standby partition of the switch.


### Type: os10_bgp
Resource Definition for os10_bgp that is used to configure base bgp configuration in OS10 switches.

#### Attributes

##### `ensure`
Determines whether the bgp configuration should be present or not.

##### `asn`
Autonomous System number of the bgp configuration. Valid values are 1-4294967295 or 0.1-65535.65535.

##### `router_id`
Configures the IP address of the local BGP router instance.

##### `max_path_ebgp`
Configures the maximum number of paths to forward packets through eBGP. Valid values are 1-64.

##### `max_path_ibgp`
Configures the maximum number of paths to forward packets through iBGP. Valid values are 1-64.

##### `graceful_restart`
Configures graceful restart capability.

##### `log_neighbor_changes`
Configures logging of neighbors up/down.

##### `fast_external_fallover`
Configures reset session if a link to a directly connected external peer goes down.

##### `always_compare_med`
Configure comparing MED from different neighbors.

##### `default_loc_pref`
Configure default local preference value. Valid values are 1-4294967295.

###### `confederation_identifier`
Set the autonomous system identifier for confederation routing domain. Valid values are integer 1-4294967295 and dotted decimal format 0.1-65535.65535.

##### `confederation_peers`
Configure peer autonomous system numbers in BGP confederation as a list. Valid values for each entry are integer 1-4294967295 and dotted decimal format 0.1-65535.65535.

##### `route_reflector_client_to_client`
Configure client to client route reflection.

##### `route_reflector_cluster_id`
Configure Route-Reflector Cluster-id. Valid values are 32 bit integer 1-4294967295 or A.B.C.D IPV4 address format.

##### `bestpath_as_path`
Configures the bestpath selection to either ignore or include prefixes received from different AS path during multipath calculation.

##### `bestpath_med_confed`
Configures bestpath to compare MED among confederation paths.

##### `bestpath_med_missing_as_worst`
Configures bestpath to treat missing MED as the least preferred one.

##### `bestpath_routerid_ignore`
Configures bestpath computation to ignore router identifier.

### Type: os10_bgp_af

#### Attributes

##### `ensure`
Configures whether the bgp address family section should be present or not. Typically this resource will have dependency on os10_bgp resource. This resource in manifest will have a `require` dependency over its corresponding os10_bgp configuration.

##### `asn`
Autonomous System number of the bgp configuration. Valid values are 1-4294967295 or 0.1-65535.65535.

##### `ip_ver`
Configures the IP version of this instance of address family configuration. Valid values are ipv4 and ipv6.

##### `aggregate_address`
Configures ipv4/ipv6 BGP aggregate address and mask. The values should be of the same version as provided in `ip_ver` parameter.

##### `dampening_state`
Enable or disable route-flap dampening. When dampening_state is true all the timers should be defined.

##### `dampening_half_life`
Set dampening half-life time for the penalty. Valid values are 1-45.

##### `dampening_reuse`
Set time value to start reusing a route. Valid values are 1-20000.

##### `dampening_suppress`
Set time value to start suppressing a route. Valid values are 1-20000.

##### `dampening_max_suppress`
Set maximum time duration to suppress a stable route. Valid values are 1-255.

###### `dampening_route_map`
Name of route-map to specify criteria for dampening. Valid value is a string with a maximum of 140 characters.

##### `default_metric`
Set default metric of redistributed routes. Valid value is in the range 1-4294967295.

##### `network`
List of IPs and mask along with optional routemap string.

##### `redistribute`
Configures routing protocols that need to be redistributed. Valid value is a list of (protocol value). Protocol can be connected / ospf / static. Value can be blank or routemap string incase of connected / static and blank or process-id incase of ospf.

### Type: os10_bgp_neighbor

#### Attributes

##### `require`
Configures the dependant os10_bgp configuration that should be configured before applying the os10_bgp_neighbor configuration. Typically this resource will have dependency on os10_bgp resource. This resource in manifest will have a `require` dependency over its corresponding os10_bgp configuration.

##### `ensure`
Configures whether the os10_bgp_neighbor section should be present or not.

##### `asn`
Autonomous System number of the bgp configuration. Valid values are 1-4294967295 or 0.1-65535.65535.

##### `neighbor`
Specify a neighbor router IP address or template name for the given configuration. Valid values can be a valid ipv4 or ipv6 address or string with maximum of 16 characters.

##### `type`
Specify whether the configuration is for neighbor ip or template.

##### `advertisement_interval`
Minimum interval between sending BGP routing updates.

##### `advertisement_start`
Delay initiating OPEN message for the specified time.

##### `timers`
Array of two timer values. Keepalive interval and Holdtime values.

##### `connection_retry_timer`
Configure peer connection retry timer.

##### `remote_as`
Specify autonomous system number of the BGP neighbor.

##### `remove_private_as`
Enables or disables configuration to remove private AS number from outbound updates.

##### `shutdown`
Set the shutdown state of the neighbor.

##### `password`
Set MD5 password for authentication with maximum of 128 characters.

##### `send_community_standard`
Enables or disables sending standard community attribute.

##### `send_community_extended`
Enables or disables sending extended community attribute.

##### `peergroup`
Configures neighbor to BGP peer-group. Inherit configuration of peer-group template. The template should be an existing configuration.

##### `ebgp_multihop`
Configures the maximum-hop count value allowed in eBGP neighbors that are not directly connected. This takes an integer value between 1-255.

##### `fall_over`
Configures the session fall on peer-route loss.

##### `local_as`
Configure local autonomous system number for the BGP peer.

##### `route_reflector_client`
Configures a BGP neighbor as router reflector client.

##### `weight`
Configure default weight for routes from the neighbor interface. Value can be between 1-4294967295.

### Type: os10_bgp_neighbor_af
Resource definition for os10_bgp_neighbor_af that is used to configure address family sub-configuration (for both ipv4 and ipv6) under bgp neighbor sub-configuration. Typically this resource will have dependency on os10_bgp_neighbor resource. This resource in manifest will have a `require` dependency over its corresponding os10_bgp_neighbor configuration.

#### Attributes

##### `require`
Configures the dependant os10_bgp configuration that should be configured before applying the os10_bgp_neighbor configuration.

##### `ensure`
Configures whether the `bgp_neighbor_af` sub-configuration should be present or not.

##### `asn`
Autonomous System number of the bgp configuration. Valid values are 1-4294967295 or 0.1-65535.65535.

##### `neighbor`
The neighbor route IP address to which the current address family sub-configuration.

##### `type`
Specify whether the neighbor configuration is of type ip or template.

##### `ip_ver`
Configures either ipv4 or ipv6 address family.

##### `activate`
Enable the Address Family for this Neighbor.

##### `allowas_in`
Configure allowed local AS number in as-path. Valid values are 1-10.

##### `add_path`
Configures the setting to Send or Receive multiple paths. Blank string removes the configuration.

##### `distribute_list`
Filter networks in routing updates. Valid parameter is an array of two Prefix list name (max 140 chars) for applying policy to incoming and outgoing routes respectively.

##### `next_hop_self`
Enables or Disables the next hop calculation for this neighbor.

##### `route_map`
Names of the route map. Valid parameter is an array of two Route-map name (max 140 chars) for filtering incoming and outgoing routing updates.

##### `sender_side_loop_detection`
Configures sender side loop detect for neighbor.

##### `soft_reconfiguration`
Configures per neighbor soft reconfiguration.

### Type: os10_lldp
`os10_lldp` resource type is to used to manage global LLDP configuration in OS10 EE switches. The os10_lldp resource is not an ensurable type and hence does not have an ensure attribute.

#### Attributes

##### `holdtime_multiplier`
This property is a string with a value range of <2-10>. An empty string will remove the holdtime multiplier value from the LLDP configuration.

##### `reinit`
This property is a string with a value range of <1-10>. An empty string will remove the reinit value from the LLDP configuration.

##### `timer`
This property is a string with a value range of <5-254>. An empty string will remove the timer value from the LLDP configuration.

##### `med_fast_start_repeat_count`
This property is a string with a value range of <1-10>, (default=3). An empty string will remove the med fast start repeat count value from the LLDP configuration.

##### `enable`
This property is a boolean string with value 'true' or 'false' to enable or disable the lldp globally.

##### `med_network_policy`
This will be an array of hash entries with the set of hash keys id<1-32>, app<guest-voice, guestvoice-signaling, softphone-voice, streaming-video, video-conferencing, voice-signaling, voice, video-signaling>, vlan_id<1-4093>, vlan_type<tag/untag>, priority<0-7>, dscp<0-63>. 

### Type: os10_lldp_interface
`os10_lldp_interface` resource type is to used to manage LLDP configuration per interface in OS10 EE switches. The os10_lldp resource is not an ensurable type and hence does not have an ensure attribute. The per interface name is given as arg for the resource.

#### Attributes

##### `receive`
This property is a boolean string with a value 'true' or 'false' to enable or disable the reception of lldp for that interface.

##### `transmit`
This property is a boolean string with a value 'true' or 'false' to enable or diable the transmission of lldp for that interface.

##### `med`
This property is a boolean string with a value 'true' or 'false' to enable or disable the med lldp for that interface. LLDP MED can be enabled only when LLDP transmit and receive are enabled | LLDP receive/transmit can be disabled only when LLDP MED is disabled

##### `med_tlv_select_inventory`
This property is a boolean string with a value 'true' or 'false' to enable or disable the med tlv select inventory lldp for that interface.

##### `med_tlv_select_network_policy`
This property is a boolean string with a value 'true' or 'false' to enable or disable the med tlv select network policy lldp for that interface.

##### `med_network_policy`
This property is an array of med policy ids with a range of <1-32> to add and remove the network policies.

##### `tlv_select`
This property is a hash of key value pair with lldp tlv select option as key and sub option as array of values. The tlv-select for all the interfaces are enabled by default in the device. The values given in the parameter are to disable the options per interface. The values not in the list will be enabled. The values for tlv_select options and sub-options are basic-tlv => ["management-address", "port-description", "system-capabilities", "system-description", "system-name"], dcbxp => [""], dcbxp-appln => ["iscsi"], dot3tlv => ["macphy-config", "max-framesize"], dot1tlv => ["link-aggregation", "port-vlan-id"].



## Limitations
The `dellos10` puppet module is designed to work only with DellEmcNetworking OS10 network operating system only.

## Known Issues

## Change Log
* ver 0.1.0 - First release
* ver 0.1.1 - Minor bug fixes. Documentation updates.

## Development
Fork the GitHub repo and send PR with modified code with a brief explanation.

## Contact
networking_devops_tools@dell.com

## License

~~~text
Copyright (c) 2018 Dell EMC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

~~~

© 2018 Dell EMC
