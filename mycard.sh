#!/bin/sh

echo 'you only need to run from this script once, it will create desktop shortcut automatically after first run.'

cd "$(dirname "$0")"


read -p "Username: " username
if [ $username ]; then
  read -p "Password: " password
  echo "ygocore:
  username: '$username'
  password: '$password'
" > config.yml;
fi
ruby -KU lib/main.rb
