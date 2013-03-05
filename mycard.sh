#!/bin/sh

echo 'you only need to run from this script once, it will create desktop shortcut automatically after first run.'

echo -n "Username: "
read username
echo -n "Password: "
read password

cd "$(dirname "$0")"

echo "ygocore:
  username: '$username'
  password: '$password'
" > config.yml

ruby -KU lib/main.rb