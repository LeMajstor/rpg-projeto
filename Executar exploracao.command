#!/bin/zsh
set -eu
rpg_project_dir="${0:A:h}"
export RPG_SCENE="res://scenes/exploration_test.tscn"
exec "$rpg_project_dir/Executar laboratorio.command" "$@"
