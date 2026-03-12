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

  programs.tmux = {
    enable = true;
    prefix = "C-w";
    baseIndex = 1;
    escapeTime = 0;
    keyMode = "vi";
    mouse = true;
    terminal = "tmux-256color";
    historyLimit = 50000;
    extraConfig = ''
      # True color support
      set -ag terminal-overrides ",xterm-256color:RGB"
      set -ag terminal-overrides ",ghostty:RGB"

      # Vi-style pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Vi-style pane resizing
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Vi-style copy mode
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi y send -X copy-pipe-and-cancel "pbcopy"
      bind -T copy-mode-vi C-v send -X rectangle-toggle

      # Splits that make sense
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # New windows keep current path
      bind c new-window -c "#{pane_current_path}"

      # Quick reload
      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded"

      # ── Status bar ──
      set -g status-position top
      set -g status-interval 5
      set -g status-style "bg=#1a1b26,fg=#a9b1d6"

      # Left: session name
      set -g status-left-length 30
      set -g status-left "#[fg=#7aa2f7,bold] #S #[fg=#3b4261]│ "

      # Right: date + time
      set -g status-right-length 50
      set -g status-right "#[fg=#3b4261]│ #[fg=#9ece6a]%a %b %d #[fg=#3b4261]│ #[fg=#bb9af7]%H:%M "

      # Window tabs
      set -g window-status-format "#[fg=#565f89] #I:#W "
      set -g window-status-current-format "#[fg=#7aa2f7,bold] #I:#W "
      set -g window-status-separator ""

      # Pane borders
      set -g pane-border-style "fg=#3b4261"
      set -g pane-active-border-style "fg=#7aa2f7"

      # Message style
      set -g message-style "bg=#1a1b26,fg=#7aa2f7"
    '';
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

  # Colima default VM profile
  home.file.".colima/default/colima.yaml".text = ''
    cpu: 8
    memory: 16
    disk: 60
    runtime: docker
    arch: aarch64
    autoActivate: true
    forwardAgent: false
    network:
      address: true
      dns: []
    docker: {}
  '';

  home.stateVersion = "25.11";
}
