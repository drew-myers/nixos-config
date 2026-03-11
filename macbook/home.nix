{ config, pkgs, lib, ... }:

{
  home.username = "acmyers";
  home.homeDirectory = lib.mkForce "/Users/acmyers";

  home.packages = with pkgs; [
    # archives
    zip
    xz
    unzip
    p7zip

    # utils
    ripgrep
    jq
    yq-go
    fzf
    lazygit

    # networking
    mtr
    iperf3
    ldns
    aria2
    nmap
    ipcalc

    # misc
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg
    nix-output-monitor
    btop
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };
    };
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "Drew Myers";
      email = "drew@drewmyers.dev";
    };
  };

  programs = {
    nushell = {
      enable = true;

      extraConfig = ''
        let carapace_completer = {|spans|
        carapace $spans.0 nushell ...$spans | from json
        }
        $env.config = {
          show_banner: false,
          edit_mode: "vi",
          buffer_editor: "vi",
          completions: {
            case_sensitive: false
            quick: true
            partial: true
            algorithm: "fuzzy"
            external: {
              enable: true
              max_results: 100
              completer: $carapace_completer
            }
          }
        }
        $env.PATH = ($env.PATH |
        split row (char esep) |
        prepend /etc/profiles/per-user/acmyers/bin |
        prepend /run/current-system/sw/bin |
        prepend /Users/acmyers/.local/bin |
        append /usr/bin/env
        )
      '';

      shellAliases = {
        vi = "hx";
        vim = "hx";
        nano = "hx";
        lg = "lazygit";
        drs = "sudo darwin-rebuild switch --flake ~/nixos-config/macbook";
      };
    };
    carapace.enable = true;
    carapace.enableNushellIntegration = true;

    starship = {
      enable = true;
      settings = {
        add_newline = true;
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };
      };
    };
  };

  home.stateVersion = "25.11";
}
