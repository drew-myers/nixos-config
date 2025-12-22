{ config, pkgs, ... }:

{
  home.username = "acmyers";
  home.homeDirectory = "/home/acmyers";

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    # here is some command line tools I use frequently
    # feel free to add your own or remove some of them

    neofetch
    nnn # terminal file manager
    lazygit

    # archives
    zip
    xz
    unzip
    p7zip

    # utils
    ripgrep # recursively searches directories for a regex pattern
    jq # A lightweight and flexible command-line JSON processor
    yq-go # yaml processor https://github.com/mikefarah/yq
    fzf # A command-line fuzzy finder

    # networking tools
    mtr # A network diagnostic tool
    iperf3
    dnsutils  # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc  # it is a calculator for the IPv4/v6 addresses

    # misc
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg

    # nix related
    #
    # it provides the command `nom` works just like `nix`
    # with more details log output
    nix-output-monitor

    glow # markdown previewer in terminal

    btop  # replacement of htop/nmon
  ];

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Drew Myers";
        email = "drew@drewmyers.dev";
      };
    };
  };

  programs.alacritty = {
    enable = true;
    # custom settings
    settings = {
      env.TERM = "xterm-256color";
      font = {
        size = 10;
      };
      scrolling.multiplier = 5;
      selection.save_to_clipboard = true;
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
             case_sensitive: false # case-sensitive completions
             quick: true    # set to false to prevent auto-selecting completions
             partial: true    # set to false to prevent partial filling of the prompt
             algorithm: "fuzzy"    # prefix or fuzzy
             external: {
               # set to false to prevent nushell looking into $env.PATH to find more suggestions
               enable: true 
               # set to lower can improve completion performance at the cost of omitting some options
               max_results: 100 
               completer: $carapace_completer # check 'carapace_completer' 
             }
           }
         } 
         $env.PATH = ($env.PATH | 
         split row (char esep) |
         prepend /home/acmyers/.apps |
         append /usr/bin/env |
         append /home/acmyers/bin
         )
         '';

       shellAliases = {
         vi = "hx";
         vim = "hx";
         nano = "hx";
         lg = "lazygit";
         nrs = "sudo nixos-rebuild switch";
       };
     };  
     carapace.enable = true;
     carapace.enableNushellIntegration = true;

     starship = { enable = true;
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
