#!/bin/zsh
set -eu

rpg_project_dir="${0:A:h}"
rpg_godot_bin="${GODOT_BIN:-}"
if [[ -z "$rpg_godot_bin" ]]; then
  for rpg_candidate in "/Applications/Godot.app/Contents/MacOS/Godot" "$HOME/Applications/Godot.app/Contents/MacOS/Godot"; do
    if [[ -x "$rpg_candidate" ]]; then
      rpg_godot_bin="$rpg_candidate"
      break
    fi
  done
fi
if [[ -z "$rpg_godot_bin" ]]; then
  rpg_godot_bin="$(command -v godot || command -v godot4 || true)"
fi
if [[ -z "$rpg_godot_bin" && -x /private/tmp/rpg-godot-runtime/Godot.app/Contents/MacOS/Godot ]]; then
  rpg_godot_bin="/private/tmp/rpg-godot-runtime/Godot.app/Contents/MacOS/Godot"
fi
if [[ -z "$rpg_godot_bin" || ! -x "$rpg_godot_bin" ]]; then
  print 'Instale Godot Standard 4.7.2 ou defina GODOT_BIN com o caminho do executável.'
  print 'Depois importe project.godot no editor ou abra novamente este lançador.'
  read -r '?Pressione Enter para fechar.'
  exit 1
fi
rpg_scene="${RPG_SCENE:-res://scenes/combat_lab.tscn}"
exec "$rpg_godot_bin" --path "$rpg_project_dir" --scene "$rpg_scene" "$@"
