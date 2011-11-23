cd /d %~dp0
echo ------------------ >> log.txt
echo ------------------ >> err.txt
ruby\bin\ruby lib/main.rb >> log.txt 2>> err.txt