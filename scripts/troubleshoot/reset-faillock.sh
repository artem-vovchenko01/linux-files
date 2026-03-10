#!/usr/bin/env bash
kitty bash -c "echo -e 'faillock --user $USER\nshow failed attempts\nfaillock --user $USER --reset\nreset'; su"
