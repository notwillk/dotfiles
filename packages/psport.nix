{ pkgs }: pkgs.writeShellScriptBin "psport" "lsof -i TCP:$1 | grep LISTEN | awk '{print $2}' | xargs ps"
