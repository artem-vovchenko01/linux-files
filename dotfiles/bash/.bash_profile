#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

[[ -z $SSH_AGENT_PID ]] && eval $(ssh-agent)

cat /etc/os-release | grep -q debian || export QT_QPA_PLATFORMTHEME=qt5ct
cat /etc/os-release | grep -q debian && export PATH=$PATH:/sbin
export MOZ_ENABLE_WAYLAND=1
export _JAVA_AWT_WM_NONREPARENTING=1
export LC_ALL=en_US.UTF-8
