function my_os_lib_system_turn_on_display {
  display=$1
  mode=$2
  scale=$3
  lib run "wlr-randr --output $display --on --mode $mode --scale $scale"
}

function my_os_lib_system_turn_off_display {
  display=$1
  lib run "wlr-randr --output $display --off"
}


function my_os_lib_system_choose_display {
  lib log notice "Choose the display: " >&2
  lib input choose-line "$(wlr-randr | grep -v '^ ' | cut -d' ' -f1)" >&2
  display="$(lib input get-choice)"
  echo $display
}

function my_os_lib_system_configure_displays_turnoff {
  display=$(my_os_lib_system_choose_display)
  my_os_lib_system_turn_off_display $display
}

function my_os_lib_system_configure_displays {
  display=$(my_os_lib_system_choose_display)

  lib log notice "Choose configuration: "
  lib input choose-line "$(__get_modes_for_display $display )"
  choice="$(lib input get-choice)"
  resolution=$(echo $choice | cut -d' ' -f1)
  rate=$(echo $choice | cut -d' ' -f3)

  lib log notice "Choose scale:"
  lib input choice 2 1.75 1.5 1.25 1
  scale="$(lib input get-choice)"

  my_os_lib_system_turn_on_display $display ${resolution}@${rate} $scale
}

function my_os_lib_system_configure_displays_optimal {
  scale=1

  displays="$(wlr-randr | grep -v '^ ' | cut -d' ' -f1)"
  if echo "$displays" | grep -iq hdmi; then
    lib log "Found display connected by HDMI" 
    display="$(echo "$displays" | grep -i hdmi | head -n1)"
    choice="$(__get_modes_for_display $display | sort -nk3 | sort -nk1 | tail -n1)"
    resolution=$(echo $choice | cut -d' ' -f1)
    rate=$(echo $choice | cut -d' ' -f3)

    my_os_lib_system_turn_on_display $display ${resolution}@${rate} $scale
  else
    lib log "Did not found display connected by HDMI" 
    display="$(echo $displays | head -n1)"
    choice="$(__get_modes_for_display $display | sort -nk3 | sort -nk1 | tail -n1)"
    resolution=$(echo $choice | cut -d' ' -f1)
    rate=$(echo $choice | cut -d' ' -f3)

    my_os_lib_system_turn_on_display $display ${resolution}@${rate} $scale
  fi

  for other in $(echo "$displays" | grep -v $display); do
    my_os_lib_system_turn_off_display $other
  done
}

function __get_modes_for_display {
  correct_display=0
  modes=0
  while IFS= read -r line
  do
    if echo $line | grep -q $1; then
      correct_display=1
      continue
    fi
    if [[ $correct_display == 1 ]]; then
      if echo $line | grep -qi modes; then
        modes=1
        continue
      fi
    fi
    if [[ $modes == 1 ]]; then
      if echo $line | grep -q px; then
        echo $line
      else
        break
      fi
    fi
  done < <(wlr-randr)
}

