cd /d %~dp0
echo ------------------ >> log.log
echo ------------------ >> err.log
ruby\bin\ruby lib/main.rb 0>>log.log 2>>err.log