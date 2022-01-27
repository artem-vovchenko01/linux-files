cat /etc/os-release | grep -iq debian && SYSTEM=DEBIAN
cat /etc/os-release | grep -iq arch && SYSTEM=ARCH
cat /etc/os-release | grep -iq fedora && SYSTEM=FEDORA

[ $SYSTEM = ARCH ] && source arch-from-scratch.sh

