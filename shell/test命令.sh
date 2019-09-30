#!/bin/bash

# Shell test命令

# Shell中的test命令用于检查某个条件是否成立
# test可以进行数值、字符和文件三个方面的测试

# 1.数值测试

# 数值测试可以用如下几个符号: -eq -ne -gt -ge -lt -le

num1=100
num2=200

if test $[num1] -eq $[num2]
then
	echo "num1=num2"
else
	echo "num1!=num2"
fi

# >> num1!=num2

# []中可以执行基本的算术运算

if test $[2 * num1] -eq $[num2]
then
	echo "2*num1=num2"
else
	echo "2*num1!=num2"
fi

# >> num1=num2

# 2.文件测试

# -e filename : 测试文件是否存在
# -r filename ：测试文件是否可读
# -w filename : 测试文件是否可写
# -x filename : 测试文件是否可执行
# -s filename : 测试文件是否存在且不为空
# -d filename : 测试是否为目录
# -f filename ：测试文件是否为普通文件
# -c filename : 测试文件是否为字符设备
# -b filename : 测试文件是否为块设备

cd /bin
if test -e ./bash
then
	echo "file /bin/bash exist!"
else 
	echo "file /bin/bash dose not exist!"
fi

# 利用-o -a ! 可以将多个条件测试连接起来
a=100
b=0
if test $a -gt 0 -o $b -gt 0
then
	echo "a and b are not both non-positive!"
else
	echo "a and b are both non-positive!"
fi



