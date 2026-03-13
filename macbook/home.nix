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
    nodejs_22
    nerd-fonts.jetbrains-mono
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
        prepend /opt/homebrew/bin |
        prepend /etc/profiles/per-user/acmyers/bin |
        prepend /run/current-system/sw/bin |
        prepend /Users/acmyers/.npm-global/bin |
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

  xdg.configFile."ghostty/config".text = ''
    theme = Everblush
    keybind = shift+enter=text:\n
    command = ${pkgs.nushell}/bin/nu
    font-family = "JetBrainsMono Nerd Font Mono"
    font-size = 14
    font-thicken = true
    font-thicken-strength = 0
  '';

  programs.helix = {
    enable = true;
    settings = {
      theme = "adwaita-dark";
      editor = {
        line-number = "relative";
        bufferline = "multiple";
        file-picker = {
          git-ignore = false;
        };
      };
    };
    languages = {
      language-server.pyright = {
        command = "pyright-langserver";
        args = [ "--stdio" ];
      };
      language-server.ruff = {
        command = "ruff";
        args = [ "server" ];
      };
      language = [{
        name = "python";
        language-servers = [ "pyright" "ruff" ];
        formatter = { command = "ruff"; args = [ "format" "-" ]; };
      }];
    };
  };

  xdg.configFile."helix/ignore".text = ''
    config/app.py
    venv
    .venv
    shell-venv
    src
    .python-version
    .closeio_maintenance_flag
    .cache
    .pytest_cache
    *.py[co]
    .mypy_cache
    .dmypy.json
    .ropeproject
    .idea
    .dir-locals.el
    .hypothesis
    .ruff_cache
    .envrc
    pyrightconfig.json

    dump.rdb

    release.txt

    CLAUDE.local.md
    .claude/settings.local.json

    # Packages
    *.egg
    *.egg-info
    eggs
    parts
    var
    sdist
    develop-eggs
    .installed.cfg

    # Installer logs
    build/
    pip-log.txt
    npm-debug.log

    # Unit test / coverage reports
    nosetests.xml
    .coverage
    .tox

    #Translations
    *.mo

    #Mr Developer
    .mr.developer.cfg

    # Vim
    *.swp

    # Finder
    .DS_Store

    .vscode

    # When working with org_stats
    /org_stats.csv
    /pipeline_stats.csv

    config/localhost/local.*
  '';

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

  # AeroSpace tiling window manager config
  home.file.".aerospace.toml".text = ''
    start-at-login = false
    after-login-command = []
    after-startup-command = []

    # Mouse follows focus
    on-focused-monitor-changed = ['move-mouse monitor-lazy-center']

    # Gaps
    [gaps]
    inner.horizontal = 8
    inner.vertical = 8
    outer.left = 8
    outer.right = 8
    outer.top = 8
    outer.bottom = 8

    # Main mode
    [mode.main.binding]
    # Focus (vim keys)
    alt-h = 'focus left'
    alt-j = 'focus down'
    alt-k = 'focus up'
    alt-l = 'focus right'

    # Move windows (vim keys + shift)
    alt-shift-h = 'move left'
    alt-shift-j = 'move down'
    alt-shift-k = 'move up'
    alt-shift-l = 'move right'

    # Workspaces
    alt-1 = 'workspace 1'
    alt-2 = 'workspace 2'
    alt-3 = 'workspace 3'
    alt-4 = 'workspace 4'
    alt-5 = 'workspace 5'
    alt-6 = 'workspace 6'
    alt-7 = 'workspace 7'
    alt-8 = 'workspace 8'
    alt-9 = 'workspace 9'

    # Move window to workspace
    alt-shift-1 = 'move-node-to-workspace 1'
    alt-shift-2 = 'move-node-to-workspace 2'
    alt-shift-3 = 'move-node-to-workspace 3'
    alt-shift-4 = 'move-node-to-workspace 4'
    alt-shift-5 = 'move-node-to-workspace 5'
    alt-shift-6 = 'move-node-to-workspace 6'
    alt-shift-7 = 'move-node-to-workspace 7'
    alt-shift-8 = 'move-node-to-workspace 8'
    alt-shift-9 = 'move-node-to-workspace 9'

    # Layout
    alt-slash = 'layout tiles horizontal vertical'
    alt-comma = 'layout accordion horizontal vertical'
    alt-f = 'fullscreen'
    alt-shift-f = 'layout floating tiling'

    # Split direction
    alt-v = 'split horizontal'
    alt-s = 'split vertical'

    # Resize mode
    alt-r = 'mode resize'

    # Service mode
    alt-shift-semicolon = 'mode service'

    # Resize mode
    [mode.resize.binding]
    h = 'resize width -50'
    j = 'resize height +50'
    k = 'resize height -50'
    l = 'resize width +50'
    enter = 'mode main'
    esc = 'mode main'

    # Service mode
    [mode.service.binding]
    r = ['reload-config', 'mode main']
    esc = 'mode main'

  '';

  home.stateVersion = "25.11";
}
