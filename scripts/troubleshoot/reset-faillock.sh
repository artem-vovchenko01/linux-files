#!/usr/bin/env bash
kitty bash -c "echo -e 'faillock --user artem\nshow failed attempts\nfaillock --user artem --reset\nreset'; su"
