cd /d %~dp0
echo ------------------ >> log.txt
echo ------------------ >> err.txt
ruby\bin\ruby lib/main.rb 0>>log.txt 2>>err.txt