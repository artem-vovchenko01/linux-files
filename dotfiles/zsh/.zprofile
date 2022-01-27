[[ -z $SSH_AGENT_PID ]] && eval $(ssh-agent)

cat /etc/os-release | grep -q debian || export QT_QPA_PLATFORMTHEME=qt5ct
cat /etc/os-release | grep -q debian && export PATH=$PATH:/sbin

