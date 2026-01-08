{ config, lib, pkgs, ... }:

let
  # TESTING CONFIG: enp2s0=WAN (existing network), enp1s0=LAN (new 192.168.1.x)
  # PRODUCTION: swap these when going live
  wanInterface = "enp2s0";
  lanInterface = "enp1s0";

  lanAddress = "192.168.1.1";
  lanPrefixLength = 24;
  dhcpRangeStart = "192.168.1.100";
  dhcpRangeEnd = "192.168.1.250";
  upstreamDns = [ "1.1.1.1" "8.8.8.8" ];
in
{
  # Enable IP forwarding
  boot.kernel.sysctl."net.ipv4.conf.all.forwarding" = true;

  # Disable NetworkManager, use systemd-networkd
  networking = {
    useDHCP = false;
    networkmanager.enable = false;
    nameservers = [ "127.0.0.1" ];
  };

  systemd.network = {
    enable = true;

    # WAN - DHCP from ISP
    networks."10-wan" = {
      matchConfig.Name = wanInterface;
      networkConfig.DHCP = "ipv4";
      dhcpV4Config.UseDNS = false;
      linkConfig.RequiredForOnline = "routable";
    };

    # LAN - Static IP
    networks."20-lan" = {
      matchConfig.Name = lanInterface;
      address = [ "${lanAddress}/${toString lanPrefixLength}" ];
      networkConfig.ConfigureWithoutCarrier = true;
      linkConfig.RequiredForOnline = "no";
    };
  };

  # DHCP + DNS server
  services.dnsmasq = {
    enable = true;
    settings = {
      server = upstreamDns;
      domain-needed = true;
      bogus-priv = true;
      no-resolv = true;
      cache-size = 1000;
      interface = lanInterface;
      bind-interfaces = true;
      dhcp-range = [ "${dhcpRangeStart},${dhcpRangeEnd},24h" ];
      dhcp-option = [
        "option:router,${lanAddress}"
        "option:dns-server,${lanAddress}"
      ];
      dhcp-authoritative = true;
      local = "/lan/";
      domain = "lan";
      expand-hosts = true;
    };
  };

  # Firewall - trust LAN, block WAN
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ lanInterface ];
    allowPing = true;
  };

  # NAT masquerade
  networking.nftables = {
    enable = true;
    ruleset = ''
      table ip nat {
        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          oifname "${wanInterface}" masquerade
        }
      }
    '';
  };

  # UniFi Controller for managing Ubiquiti APs
  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unifi;
    openFirewall = true;
  };
}
