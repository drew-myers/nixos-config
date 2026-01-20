{ config, lib, pkgs, ... }:

let
  wanInterface = "enp2s0";
  lanInterface = "enp1s0";

  # Main LAN (untagged)
  lanAddress = "192.168.1.1";
  lanPrefixLength = 24;
  dhcpRangeStart = "192.168.1.100";
  dhcpRangeEnd = "192.168.1.250";

  # Guest VLAN
  guestVlan = 10;
  guestInterface = "vlan${toString guestVlan}";
  guestAddress = "192.168.10.1";
  guestDhcpStart = "192.168.10.100";
  guestDhcpEnd = "192.168.10.250";

  # IoT VLAN
  iotVlan = 20;
  iotInterface = "vlan${toString iotVlan}";
  iotAddress = "192.168.20.1";
  iotDhcpStart = "192.168.20.100";
  iotDhcpEnd = "192.168.20.250";

  adguardPort = 3000;
in
{
  # Enable IP forwarding and kernel hardening
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv4.conf.all.rp_filter" = 1;       # Enable strict reverse path filtering (prevents IP spoofing)
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.send_redirects" = 0;  # Disable sending ICMP redirects
    "net.ipv4.conf.default.send_redirects" = 0;
  };

  # Disable NetworkManager, use systemd-networkd
  networking = {
    useDHCP = false;
    networkmanager.enable = false;
    nameservers = [ "127.0.0.1" ];
  };

  systemd.network = {
    enable = true;

    # VLAN netdevs
    netdevs."10-guest" = {
      netdevConfig = { Kind = "vlan"; Name = guestInterface; };
      vlanConfig.Id = guestVlan;
    };
    netdevs."10-iot" = {
      netdevConfig = { Kind = "vlan"; Name = iotInterface; };
      vlanConfig.Id = iotVlan;
    };

    # WAN - DHCP from ISP (IPv6 disabled)
    networks."10-wan" = {
      matchConfig.Name = wanInterface;
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = false;
        LinkLocalAddressing = "ipv4";
      };
      dhcpV4Config.UseDNS = false;
      linkConfig.RequiredForOnline = "routable";
    };

    # LAN - Static IP + VLANs attached
    networks."20-lan" = {
      matchConfig.Name = lanInterface;
      address = [ "${lanAddress}/${toString lanPrefixLength}" ];
      vlan = [ guestInterface iotInterface ];
      networkConfig.ConfigureWithoutCarrier = true;
      linkConfig.RequiredForOnline = "no";
    };

    # Guest VLAN
    networks."30-guest" = {
      matchConfig.Name = guestInterface;
      address = [ "${guestAddress}/24" ];
      networkConfig.ConfigureWithoutCarrier = true;
      linkConfig.RequiredForOnline = "no";
    };

    # IoT VLAN
    networks."30-iot" = {
      matchConfig.Name = iotInterface;
      address = [ "${iotAddress}/24" ];
      networkConfig.ConfigureWithoutCarrier = true;
      linkConfig.RequiredForOnline = "no";
    };
  };

  # DHCP server + local DNS (dnsmasq on port 5354, AdGuard on 53)
  services.dnsmasq = {
    enable = true;
    settings = {
      port = 5354;  # AdGuard handles port 53, mDNS uses 5353
      domain-needed = true;
      bogus-priv = true;
      no-resolv = true;
      
      # FIX: Listen on specific interfaces but do NOT bind tightly (prevents startup race)
      # Must include "lo" so AdGuard can talk to it on 127.0.0.1
      interface = [ "lo" lanInterface guestInterface iotInterface ];
      bind-interfaces = false; 

      # DHCP ranges per network using TAGS
      dhcp-range = [
        "set:lan,${dhcpRangeStart},${dhcpRangeEnd},24h"
        "set:guest,${guestDhcpStart},${guestDhcpEnd},1h"
        "set:iot,${iotDhcpStart},${iotDhcpEnd},24h"
      ];

      # Explicit DHCP options per tag to ensure correct gateway/DNS
      dhcp-option = [
        # LAN
        "tag:lan,option:router,${lanAddress}"
        "tag:lan,option:dns-server,${lanAddress}"
        
        # Guest
        "tag:guest,option:router,${guestAddress}"
        "tag:guest,option:dns-server,${guestAddress}"
        
        # IoT
        "tag:iot,option:router,${iotAddress}"
        "tag:iot,option:dns-server,${iotAddress}"
      ];

      dhcp-authoritative = true;
      local = "/lan/";
      domain = "lan";
      expand-hosts = true;

      # Static DHCP reservations
      dhcp-host = [
        "e8:ff:1e:d2:1a:dd,192.168.1.10,bugman"
      ];

      # Static DNS records
      host-record = [
        "geodude.lan,192.168.1.1"
        "geodude,192.168.1.1"
      ];
    };
  };

  # AdGuard Home - DNS ad blocking with DoH upstream
  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    settings = {
      http = {
        address = "${lanAddress}:${toString adguardPort}";
      };
      dns = {
        bind_hosts = [ "127.0.0.1" lanAddress guestAddress iotAddress ];
        port = 53;
        upstream_dns = [
          # DNS-over-HTTPS upstreams (encrypted)
          "https://dns.cloudflare.com/dns-query"
          "https://dns.quad9.net/dns-query"
          # Forward local zones to dnsmasq
          "[/lan/]127.0.0.1:5354"
          "[/1.168.192.in-addr.arpa/]127.0.0.1:5354"
          "[/10.168.192.in-addr.arpa/]127.0.0.1:5354"
          "[/20.168.192.in-addr.arpa/]127.0.0.1:5354"
        ];
        bootstrap_dns = [ "1.1.1.1" "9.9.9.9" ];
        enable_dnssec = true;
      };
      filtering = {
        enabled = true;
        rewrites = [];
      };
      filters = [
        { enabled = true; url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt"; name = "AdGuard DNS filter"; id = 1; }
        { enabled = true; url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt"; name = "AdAway Default Blocklist"; id = 2; }
      ];
      user_rules = [
        "@@||anthropic.com^"
        "@@||datadoghq.com^"
      ];
    };
  };

  # Firewall - trust LAN, limited trust for VLANs
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ lanInterface ];
    allowPing = true;
    
    # Explicitly allow DHCP and DNS on VLAN interfaces (since they are not trusted)
    interfaces = {
      "${guestInterface}" = {
        allowedUDPPorts = [ 53 67 ];
        allowedTCPPorts = [ 53 ];
      };
      "${iotInterface}" = {
        allowedUDPPorts = [ 53 67 ];
        allowedTCPPorts = [ 53 ];
      };
    };
  };

  # NAT + VLAN isolation
  networking.nftables = {
    enable = true;
    ruleset = ''
      table ip nat {
        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          oifname "${wanInterface}" masquerade
        }
      }

      table inet filter {
        chain input {
          type filter hook input priority filter; policy drop;

          # Allow trusted interfaces (Loopback, LAN)
          iifname "lo" accept
          iifname "${lanInterface}" accept
          
          # Allow established/related connections (Replies to traffic we started)
          ct state vmap { invalid : drop, established : accept, related : accept }

          # Jump to allow list for other interfaces
          jump input-allow
        }

        chain input-allow {
          # Management Ports - ONLY from LAN (Redundant due to 'iifname ${lanInterface} accept' above, but safe)
          # We do NOT allow these from WAN, Guest, or IoT

          # DNS & DHCP (Guests/IoT)
          iifname "${guestInterface}" udp dport { 53, 67 } accept
          iifname "${iotInterface}" udp dport { 53, 67 } accept
          iifname "${guestInterface}" tcp dport 53 accept
          iifname "${iotInterface}" tcp dport 53 accept

          # mDNS (Avahi) - Allow discovery from VLANs
          iifname "${guestInterface}" udp dport 5353 accept
          iifname "${iotInterface}" udp dport 5353 accept

          # Allow Ping
          icmp type echo-request accept
          
          # Allow DHCPv6 client (from ISP)
          ip6 daddr fe80::/64 udp dport 546 accept
        }

        chain forward {
          type filter hook forward priority filter; policy drop;

          # Allow established/related connections
          ct state established,related accept

          # Main LAN can go anywhere
          iifname "${lanInterface}" accept

          # Guest can only reach internet (WAN), not other networks
          iifname "${guestInterface}" oifname "${wanInterface}" accept

          # IoT can reach internet
          iifname "${iotInterface}" oifname "${wanInterface}" accept

          # Main LAN can initiate to IoT (for controlling devices)
          iifname "${lanInterface}" oifname "${iotInterface}" accept
        }
      }
    '';
  };

  # UniFi Controller
  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unifi;
    openFirewall = false;
  };

  # mDNS Reflector (Avahi) - Allows AirPrint/Chromecast across VLANs
  services.avahi = {
    enable = true;
    allowInterfaces = [ lanInterface guestInterface iotInterface ];
    reflector = true;
  };
}