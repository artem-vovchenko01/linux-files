#!/usr/bin/env bash
set -x
SCRIPTS=~/linux-files/scripts

is_spawn_terminal() {
  local dir=$1
  local item=$2
  [ -f $dir/.menu_config ] && grep SPAWN_TERMINAL $dir/.menu_config && \
    cat $dir/.menu_config | grep SPAWN_TERMINAL | cut -d= -f 2 | grep $item && \
    return 0
  return 1
}

display_dir() {
  local dir=$1
  local entries=$(ls $dir)
  [ -f $dir/.menu_config ] && grep IGNORE $dir/.menu_config && \
    local entries=$(ls $dir | grep -vE "$(cat $dir/.menu_config | grep IGNORE | cut -d= -f 2 | sed 's/ /\|/g')")
  local menu_entries=()
  for entry in $entries; do
    [ -d $dir/$entry ] && menu_entries+=(${entry}/) || \
      menu_entries+=($(echo $entry | sed 's/\.sh//'))
  done
  local choice=$(printf "%s\n" "${menu_entries[@]}" | xargs -d '\n' -n1 | wofi --dmenu)
  [[ "$choice" == "" ]] && exit
  case $choice in
    */)
      display_dir $dir/$choice
      ;;
    *)
      is_spawn_terminal $dir ${choice}.sh && kitty bash -c "$dir/${choice}.sh; echo Press Return to close ...; read"
      is_spawn_terminal $dir ${choice}.sh || { 
        $dir/${choice}.sh
        CODE=$?
        [ $CODE -eq 0 ] && notify-send "${choice}.sh: success" || notify-send "${choice}.sh: FAILURE!"
      }
      ;;
  esac
}

display_dir $SCRIPTS
