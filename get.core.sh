#!/bin/bash

pname="$1"
core="$2"
fileName="$0"

which expect &> /dev/null
if [ $? -ne 0 ];then
	echo "no expect command"
	exit 1
fi

/usr/bin/expect <<EOF
set timeout -1
if { "$pname" == "" || "$core" == ""  } {
	puts "Usage: $fileName /path/xx.exe /path/core.xx"
	exit 1
}
spawn gdb $pname $core &> /dev/null
expect {
"(gdb)" { send "bt\r"; send "quit\r" } 
}

expect eof
EOF
