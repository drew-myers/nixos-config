This is the nixos config repo for a custom home network router

Any diagnostic commands can be run via: ssh geodude.lan

To provision changes run: scp -r /home/acmyers/nixos-config/geodude/* acmyers@192.168.1.1:~/nixos-config/geodude/ ; ssh acmyers@192.168.1.1 "cd ~/nixos-config/geodude && sudo nixos-rebuild switch --flake .#geodude"
