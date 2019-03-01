#!/bin/sh

# write last ip to log file
echo $(curl -s ifconfig.co) > "${HOME}"/.lastip &