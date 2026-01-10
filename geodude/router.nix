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
  # AdGuard will handle upstream DNS with DoH
  adguardPort = 3000;  # Web UI port
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

  # DHCP server + local DNS (dnsmasq on port 5353, AdGuard on 53)
  services.dnsmasq = {
    enable = true;
    settings = {
      port = 5353;  # AdGuard handles port 53
      domain-needed = true;
      bogus-priv = true;
      no-resolv = true;
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

      # Static DHCP reservations + local DNS
      dhcp-host = [
        "e8:ff:1e:d2:1a:dd,192.168.1.10,bugman"
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
        bind_hosts = [ "127.0.0.1" lanAddress ];
        port = 53;
        upstream_dns = [
          # DNS-over-HTTPS upstreams (encrypted)
          "https://dns.cloudflare.com/dns-query"
          "https://dns.quad9.net/dns-query"
          # Forward .lan to local dnsmasq
          "[/lan/]127.0.0.1:5353"
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
      user_rules = [];
    };
  };

  # Firewall - trust LAN, block WAN
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ lanInterface ];
    allowPing = true;
    allowedTCPPorts = [ adguardPort ];  # AdGuard web UI
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
