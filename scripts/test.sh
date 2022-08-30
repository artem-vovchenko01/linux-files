function myfun {
  if $INTERACTIVE; then
    echo interactive
  else
    echo non-interactive
  fi
}

myfun
