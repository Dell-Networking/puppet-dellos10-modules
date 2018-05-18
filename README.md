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

## Module description

The current version of dellos10 module contains Providers that makes use of OS10 operating system's configuration CLIs. 

The `dellos10` module is dependant on the following ruby modules:

* `os10_devops_ruby_utils`

## Setup

### Install os10_devops_ruby_utils module

The dellos10 puppet module requires ``os10_devops_ruby_utils`` module to be installed separately for communicating with the underlying OS10 operating system. The installation steps can be found at [readthedocs.org](https://readthedocs.org/projects/puppet-dellos-docs/).

### Start with dellos10

```bash
puppet module install dellemcnetworking-dellos10
```

See [Puppet Labs: Installing Modules](https://docs.puppetlabs.com/puppet/latest/reference/modules_installing.html) for more information.

## Usage

These Puppet resources are defined as part of `dellos10` module:

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

The ``os10_route`` resource type is used to manage static routes in OS10 switches.

**Attributes**

| Attribute   | Description                                         |
|-------------|-----------------------------------------------------|
| ``destination`` | Target IP address to which the route must be configured |
| ``prefix_len`` | Netmask of the target IP address |
| ``next_hop_list`` | List of next-hop IP address for the route to be configured |
| ``ensure`` | Determine whether the route entry should be present or not |

### Type: os10_snmp
The ``os10_snmp`` resource type is to used to manage SNMP configuration in OS10 Enterprise Edition switches. The os10_snmp resource is not an ensurable type and hence does not have an ensure attribute.

**Attributes**

| Attribute   | Description                                         |
|-------------|-----------------------------------------------------|
| ``community_strings`` | Dictionary of community string with its access right; will be the only list of community string entries present in the SNMP configuration (for example, {'public'=>'ro', 'private'=>'rw'}) |
| ``contact`` | Contact property of SNMP server; there can be only one entry for contact; an empty string for contact will remove the contact entry from the SNMP configuration |
| ``location`` | Location property of the SNMP server; there can be only one entry for location; an empty string for location will remove the location entry |
| ``enabled_traps`` | Dictionary of entries where the key is trap category and values are the list of subcategory or all to enable traps for all subcategory items |
| ``trap_destination`` | Dictionary of entries where the key is list of [ip,Port] and value is a list with version string ("v1"/"v2") and community string |

### Type: os10_monitor
The ``os10_monitor`` resource type is to used to manage port monitor (mirroring) session configuration in OS10 Enterprise Edition switches.

**Attributes**

| Attribute   | Description                                         |
|-------------|-----------------------------------------------------|
| ``ensure`` | Determines whether this monitor configuration should exist or not |
| ``id`` | Configures the ID of the monitor session in the switch; ID needs to be unique (1 to 18) |
| ``source`` | Configures values of the interfaces that will be configured as source interfaces for this monitoring session (for example, ['ethernet 1/1/9', 'ethernet 1/1/10']) |
| ``destination`` | Configures values of the destination interface to which traffic is to be mirrored (for example, 'ethernet 1/1/10') |
| ``flow_based`` | Specifies whether to enable or disable flow-based monitoring; optional attribute defaults to false |
| ``shutdown`` | Enables or disables the monitoring session; if the shutdown is false, the session will be configured but in shutdown state; optional attribute defaults to true |

### Type: os10_interface
The ``os10_interface`` resource type is used to manage interface configuration in OS10 switches.

**Attributes**

| Attribute   | Description                                         |
|-------------|-----------------------------------------------------|
| ``desc`` | Configures the description of the interface |
| ``mtu`` | Configures the maximum transmission unit (MTU) of the interface |
| ``switchport_mode`` | Configures the switchport mode of the interface; either trunk or access in case of switchport, or can be false when not in L2 mode (trunk, access, absent) |
| ``admin`` | Sets the administrative state of the interface (up, down) |
| ``ip_address`` | Specifies the IPv4 address and mask of the interface in ip/prefixlen format |
| ``ipv6_address`` | Specifies the IPv6 address and mask of the interface in ip/prefixlen format |
| ``ipv6_autoconfig`` | Enable or disables IPv6 autoconfig (true, false) |
| ``ip_helper`` | Specifies the IP address for the interface to which UDP broadcasts need to be forwarded |

### Type: os10_image_upgrade
The ``os10_image_upgrade`` resource type is used to upgrade/downgrade OS10 Enterprise Edition images by providing the filename and location of the image.

**Attribute**

| Attribute   | Description                                         |
|-------------|-----------------------------------------------------|
| ``image_url`` | Location of the binary image in the remote server; image will be downloaded and installed in the standby partition of the switch | 

### Type: os10_bgp
The resource definition for ``os10_bgp`` that is used to configure base BGP configuration in OS10 Enterprise Edition switches.

**Attributes**

| Attribute   | Description                                         |
|-------------|-----------------------------------------------------|
| ``ensure`` | Determines whether the BGP configuration should be present or not |
| ``asn`` | Autonomous system (AS) number of the BGP configuration (1 to 4294967295 or 0.1 to 65535.65535) |
| ``router_id`` | Configures the IP address of the local BGP router instance |
| ``max_path_ebgp`` | Configures the maximum number of paths to forward packets through eBGP (1 to 64) |
| ``max_path_ibgp`` | Configures the maximum number of paths to forward packets through iBGP (1 to 64) |
| ``graceful_restart`` | Configures graceful restart capability |
| ``log_neighbor_changes`` | Configures logging of neighbors up/down |
| ``fast_external_fallover`` | Configures reset session if a link to a directly connected external peer goes down |
| ``always_compare_med`` | Configures comparing MED from different neighbors |
| ``default_loc_pref`` | Configures default local preference value (1 to 4294967295) |
| ``confederation_identifier`` | Sets the AS identifier for confederation routing domain (1 to 4294967295 and 0.1 to 65535.65535) |
| ``confederation_peers`` | Configures peer AS numbers in BGP confederation as a list (1 to 4294967295 and 0.1 to 65535.65535) |
| ``route_reflector_client_to_client`` | Configures client-to-client route reflection |
| ``route_reflector_cluster_id`` | Configures route-reflector cluster-id (1 to 4294967295 or A.B.C.D IPv4 address format) |
| ``bestpath_as_path`` | Configures the best-path selection to either ignore or include prefixes received from different AS path during multipath calculation |
| ``bestpath_med_confed`` | Configures best-path to compare MED among confederation paths |
| ``bestpath_med_missing_as_worst`` | Configures best-path to treat missing MED as the least preferred one |
| ``bestpath_routerid_ignore`` | Configures best-path computation to ignore router identifier |

### Type: os10_bgp_af

**Attributes**

| Attribute   | Description                                         |
|-------------|-----------------------------------------------------|
| ``ensure`` | Configures whether the BGP address family should be present or not; typically this resource will have dependency on the ``os10_bgp`` resource; this resource in manifest will have a ``require`` dependency over its corresponding os10_bgp configuration |
| ``asn`` | AS number of the BGP configuration (1 to 4294967295 or 0.1 to 65535.65535) |
| ``ip_ver`` | Configures the IP version of this instance of address family configuration (ipv4, ipv6) |
| ``aggregate_address`` | Configures IPv4/IPv6 BGP aggregate address and mask; values should be of the same version as provided in ``ip_ver`` parameter |
| ``dampening_state`` | Enables or disables route-flap dampening; shen ``dampening_state`` is true all the timers should be defined |
| ``dampening_half_life`` | Sets dampening half-life time for the penalty (1 to 45) |
| ``dampening_reuse`` | Sets the time value to start reusing a route (1 to 20000) |
| ``dampening_suppress`` | Sets the time value to start suppressing a route (1 to 20000) |
| ``dampening_max_suppress`` | Sets the maximum time duration to suppress a stable route (1 to 255) |
| ``dampening_route_map`` | Configures the name of the route-map to specify criteria for dampening (up to 140 characters) |
| ``default_metric`` | Sets the default metric of redistributed routes (1 to 4294967295) |
| ``network`` | Specifies a list of IPs and mask along with optional route-map string |
| ``redistribute`` | Configures routing protocols that need to be redistributed (valid value is a list of <protocol_value>; protocol can be connected, ospf, static; value can be blank or route-map string in the case of connected, static and blank or process-id in the case of OSPF |

### Type: os10_bgp_neighbor

**Attributes**

| Attribute   | Description                                         |
|-------------|-----------------------------------------------------|
| ``require`` | Configures the dependant ``os10_bgp`` configuration that should be configured before applying the ``os10_bgp_neighbor`` configuration; typically this resource will have dependency on the ``os10_bgp`` resource; this resource in manifest will have a *require* dependency over its corresponding ``os10_bgp`` configuration |
| ``ensure`` | Configures whether the ``os10_bgp_neighbor` should be present or not |
| ``asn`` | Configures the AS number of the BGP configuration (1 to 4294967295 or 0.1 to 65535.65535) |
| ``neighbor`` | Specifies a neighbor router IP address or template name for the given configuration (valid IPv4 or IPv6 address or string up to 16 characters) |
| ``type`` | Specifies whether the configuration is for neighbor IP or template |
| ``advertisement_interval`` | Specifies the minimum interval between sending BGP routing updates |
| ``advertisement_start`` | Specifies the delay initiating OPEN message for the specified time |
| ``timers`` | Configures the array of two timer values; keepalive interval and holdtime values |
| ``connection_retry_timer`` | Configures the peer connection retry timer |
| ``remote_as`` | Specifies the AS number of the BGP neighbor |
| ``remove_private_as`` | Enables or disables configuration to remove private AS number from outbound updates |
| ``shutdown`` | Sets the shutdown state of the neighbor |
| ``password`` | Sets the MD5 password for authentication (up to 128 characters) |
| ``send_community_standard`` | Enables or disables sending standard community attribute |
| ``send_community_extended`` | Enables or disables sending extended community attribute |
| ``peergroup`` | Configures neighbor to BGP peer-group; inherit configuration of peer-group template (template should be an existing configuration) |
| ``ebgp_multihop`` | Configures the maximum-hop count value allowed in eBGP neighbors that are not directly connected (1 to 255) |
| ``fall_over`` | Configures the session fall on peer-route loss |
| ``local_as`` | Configures local AS number for the BGP peer |
| ``route_reflector_client`` | Configures a BGP neighbor as router reflector client |
| ``weight`` | Configures the default weight for routes from the neighbor interface (1 to 4294967295) |

### Type: os10_bgp_neighbor_af
The resource definition for ``os10_bgp_neighbor_af`` that is used to configure address family subconfiguration (for both IPv4 and IPv6) under bgp neighbor sub-configuration. Typically this resource will have dependency on ``os10_bgp_neighbor`` resource. This resource in manifest will have a `require` dependency over its corresponding os10_bgp_neighbor configuration.

**Attributes**

| Attribute   | Description                                         |
|-------------|-----------------------------------------------------|
| ``require`` | Configures the dependant os10_bgp configuration that should be configured before applying the os10_bgp_neighbor configuration |
| ``ensure`` | Configures whether the bgp_neighbor_af subconfiguration should be present or not |
| ``asn`` | Configures the AS number of the BGP configuration (1 to 4294967295 or 0.1 to 65535.65535) |
| ``neighbor`` | Configures the neighbor route IP address to which the current address family subconfiguration |
| ``type`` | Specify whether the neighbor configuration is of type ip or template |
| ``ip_ver`` | Configures either IPv4 or IPv6 address family |
| ``activate`` | Enable the address family for this neighbor |
| ``allowas_in`` | Configures allowed local AS number in as-path (1 to 10) |
| ``add_path`` | Configures the setting to send or receive multiple paths; blank string removes the configuration |
| ``distribute_list`` | Specifies to filter networks in routing updates (two prefix-list names up to 140 characters) for applying policy to incoming and outgoing routes respectively |
| ``next_hop_self`` | Enables or disables the next-hop calculation for this neighbor |
| ``route_map`` | Configures the names of the route-map (two route-map names up to 140 characters) for filtering incoming and outgoing routing updates |
| ``sender_side_loop_detection`` | Configures sender-side loop detect for neighbor |
| ``soft_reconfiguration`` | Configures per neighbor soft reconfiguration |

### Type: os10_lldp
The ``os10_lldp`` resource type is to used to manage global LLDP configuration in OS10 Enterprise Edition switches. The os10_lldp resource is not an ensurable type and hence does not have an ensure attribute.

**Attributes**

| Attribute   | Description                                         |
|-------------|-----------------------------------------------------|
| ``holdtime_multiplier`` | Configures the holdtime multiplier (2 to 10); an empty string will remove the holdtime multiplier value from the LLDP configuration |
| ``reinit`` | Configures the reinit value (1 to 10); an empty string will remove the reinit value from the LLDP configuration |
| ``timer`` | Configures the timer value (5 to 254); an empty string will remove the timer value from the LLDP configuration |
| ``med_fast_start_repeat_count`` | Configures the med fast start repeat counter value (1 to 10; default 3); an empty string will remove the med fast start repeat count value from the LLDP configuration |
| ``enable`` | Specifies to enable or disable LLDP globally (true, false) |
| ``med_network_policy`` | Configures the med network policy (set of hash keys id<1-32>, app<guest-voice, guestvoice-signaling, softphone-voice, streaming-video, video-conferencing, voice-signaling, voice, video-signaling>, vlan_id<1-4093>, vlan_type<tag/untag>, priority<0-7>, dscp<0-63> |

### Type: os10_lldp_interface
The ``os10_lldp_interface`` resource type is to used to manage LLDP configuration per interface in OS10 Enterprise Edition switches. The os10_lldp resource is not an ensurable type and hence does not have an ensure attribute. The per interface name is given as arg for the resource.

**Attributes**

| Attribute   | Description                                         |
|-------------|-----------------------------------------------------|
| ``receive`` | Configures the receive value (true, false) to enable or disable the reception of LLDP for that interface |
| ``transmit`` | Configures the transmit value (true, false) to enable or diable the transmission of LLDP for that interface |
| ``med`` | Configures the med value (true, false) to enable or disable the MED LLDP for that interface; LLDP MED can be enabled only when LLDP transmit and receive are enabled; LLDP receive/transmit can be disabled only when LLDP MED is disabled |
| ``med_tlv_select_inventory`` | Configures the med tlv select inventory value (true, false) to enable or disable the MED TLV select inventory LLDP for that interface |
| ``med_tlv_select_network_policy`` | Configures the med tlv select network policy value (true, false) to enable or disable the MED TLV select network policy LLDP for that interface |
| ``med_network_policy`` | Configures the med network policy IDs (1 to 32) to add and remove the network policies |
| ``tlv_select`` | Configures the tlv select key value pair with LLDP TLV select option as key and suboption as array of values; tlv-select for all the interfaces are enabled by default in the device; values given in the parameter are to disable the options per interface, and values not in the list will be enabled; values for tlv_select options and suboptions are basic-tlv => ["management-address", "port-description", "system-capabilities", "system-description", "system-name"], dcbxp => [""], dcbxp-appln => ["iscsi"], dot3tlv => ["macphy-config", "max-framesize"], dot1tlv => ["link-aggregation", "port-vlan-id"] |

## Limitations
The ``dellos10`` Puppet module is designed to work only with the Dell EMC Networking OS10 network operating system only.

## Known Issues
None

## Change Log
* ver 0.1.0 - Initial draft release
* ver 0.1.1 - Minor bug fixes. Documentation updates.
* ver 1.0.0 - First release

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

© 2018 Dell Inc. or its subsidiaries. All Rights Reserved.
