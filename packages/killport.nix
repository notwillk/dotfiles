{ pkgs }: pkgs.writeShellScriptBin "killport" "lsof -i TCP:$1 | grep LISTEN | awk '{print $2}' | uniq | xargs kill -9"
