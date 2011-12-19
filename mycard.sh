# Move to the script's dir
readlink $0 > /dev/null 2>&1
isLink=$?
if [ $isLink -eq 0 ]; then
    cd $(dirname $(readlink $0))
else
    cd $(dirname $0)
fi

echo ------------------ >> log.log
echo ------------------ >> err.log
ruby lib/main.rb 0>>log.log 2>>err.log