# Sway UI look setup

lib input "Install sway graphical?" && lib run "source $(lib path envs)/sway-graphical.sh"

# Opswat setup

lib log "Setting up Opswat client"
lib dir ~
lib run "wget -qO- https://s3-us-west-2.amazonaws.com/opswat-gears-cloud-clients/linux_installer/latest/opswatclient.tar | tar xvf -"
lib dir opswatclient

lib input value "Input server value: (-s flag):"
opswat_server=$(lib input get-value)
lib input value "Input login value (-l flag):"
opswat_login=$(lib input get-value)

lib run "sudo ./setup.sh -s=$opswat_server -l=$opswat_login"
lib dir ..
lib run "rm -r opswatclient"

