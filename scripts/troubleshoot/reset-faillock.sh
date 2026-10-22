#!/usr/bin/env bash
# menu: Unlock the account after too many failed logins
kitty bash -c "echo -e 'faillock --user $USER\nshow failed attempts\nfaillock --user $USER --reset\nreset'; su"
