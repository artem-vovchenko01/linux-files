# Opswat setup

lib log "Setting up Opswat client"
lib dir cd ~
lib run "wget -qO- https://s3-us-west-2.amazonaws.com/opswat-gears-cloud-clients/linux_installer/latest/opswatclient.tar | tar xvf -"
lib dir cd opswatclient

lib input value "Input server value: (-s flag):"
opswat_server=$(lib input get-value)
lib input value "Input login value (-l flag):"
opswat_login=$(lib input get-value)

lib run "sudo ./setup.sh -s=$opswat_server -l=$opswat_login"
lib dir cd ..
lib run "rm -r opswatclient"

