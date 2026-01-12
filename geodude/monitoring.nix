{ config, lib, pkgs, ... }:

let
  # Network config (matches router.nix)
  lanAddress = "192.168.1.1";
  grafanaPort = 4000;

  # ICMP ping targets for connectivity monitoring
  icmpTargets = [
    "1.1.1.1"           # Cloudflare DNS (AdGuard bootstrap)
    "9.9.9.9"           # Quad9 DNS (AdGuard bootstrap)
    "8.8.8.8"           # Google DNS (general internet check)
    # TODO: Replace with your ISP gateway IP (run: ip route | grep default)
    # "ISP_GATEWAY_IP"
  ];

  # HTTP targets - DoH endpoints used by AdGuard Home
  httpTargets = [
    "https://dns.cloudflare.com/dns-query"
    "https://dns.quad9.net/dns-query"
  ];
in
{
  # ==========================================================================
  # Prometheus - Time series database for metrics storage
  # ==========================================================================
  services.prometheus = {
    enable = true;
    port = 9090;
    listenAddress = "127.0.0.1";
    retentionTime = "90d";

    scrapeConfigs = [
      # Node exporter - system and network interface metrics
      {
        job_name = "node";
        scrape_interval = "15s";
        static_configs = [{
          targets = [ "127.0.0.1:9100" ];
        }];
      }

      # Blackbox ICMP probes - ping external hosts
      {
        job_name = "blackbox-icmp";
        scrape_interval = "15s";
        metrics_path = "/probe";
        params = { module = [ "icmp" ]; };
        static_configs = [{
          targets = icmpTargets;
        }];
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "127.0.0.1:9115";
          }
        ];
      }

      # Blackbox HTTP probes - check DoH endpoints
      {
        job_name = "blackbox-http";
        scrape_interval = "15s";
        metrics_path = "/probe";
        params = { module = [ "http_2xx" ]; };
        static_configs = [{
          targets = httpTargets;
        }];
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "127.0.0.1:9115";
          }
        ];
      }
    ];
  };

  # ==========================================================================
  # Blackbox Exporter - Probes external endpoints (ICMP, HTTP)
  # ==========================================================================
  services.prometheus.exporters.blackbox = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9115;
    configFile = pkgs.writeText "blackbox.yml" (builtins.toJSON {
      modules = {
        icmp = {
          prober = "icmp";
          timeout = "5s";
          icmp = {
            preferred_ip_protocol = "ip4";
          };
        };
        http_2xx = {
          prober = "http";
          timeout = "10s";
          http = {
            preferred_ip_protocol = "ip4";
            valid_http_versions = [ "HTTP/1.1" "HTTP/2.0" ];
            method = "GET";
            fail_if_ssl = false;
            fail_if_not_ssl = false;
          };
        };
      };
    });
  };

  # ==========================================================================
  # Node Exporter - System and network interface metrics
  # ==========================================================================
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9100;
    enabledCollectors = [
      "systemd"
      "netdev"
      "netclass"
      "filesystem"
      "loadavg"
      "meminfo"
    ];
  };

  # ==========================================================================
  # Grafana - Visualization and dashboards
  # ==========================================================================
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = lanAddress;
        http_port = grafanaPort;
        domain = lanAddress;
      };
      # Anonymous auth enabled - LAN-only access is sufficient security
      "auth.anonymous" = {
        enabled = true;
        org_role = "Admin";
      };
      auth.disable_login_form = true;
      # Disable analytics/telemetry
      analytics.reporting_enabled = false;
      analytics.check_for_updates = false;
    };

    # Provision datasources and dashboards declaratively
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:9090";
          isDefault = true;
          editable = false;
        }
      ];
      dashboards.settings.providers = [
        {
          name = "default";
          options.path = "/etc/grafana/dashboards";
        }
      ];
    };
  };

  # Dashboard JSON file
  environment.etc."grafana/dashboards/connectivity.json".source = ./dashboards/connectivity.json;

  # ==========================================================================
  # Firewall - Allow Grafana access from LAN
  # ==========================================================================
  networking.firewall.allowedTCPPorts = [ grafanaPort ];
}
