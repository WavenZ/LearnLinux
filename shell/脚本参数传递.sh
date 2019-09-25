#!/bin/bash
# auther:lang
# <lang.zheng@intel,com>


# 1. Shell传递参数
# shell脚本传递参数时，脚本内获取参数的格式为$n，n表示传递的第几个参数

echo "Shell Arguments";
echo "filename: $0";
echo "first arg: $1";
echo "second arg: $2";
echo "third arg: $3";

# 为脚本设置可执行权限，并执行脚本
# chmod +x ./a.sh
# ./a.sh hello world !

# 输出如下：

# Shell Arguments
# filename: ./a.sh
# first arg: hello
# second arg: world
# third arg: !

# 此外，还有几个特殊字符用来处理参数

# $#: 传递到脚本的参数个数
# $*：以一个单字符串显示所有向脚本传递的参数
# $@: 与$*相同，但是使用时加引号，并再引号中返回每个参数
# $!: 后台运行的最后一个进程的id号
# $$: 脚本运行的当前进程id号
# $-: 显示shell使用的当前选项，与set命令功能相同
# $?: 显示最后命令的推出状态。0表示没有错误，a其它任何值表示有错误。


echo "argc: $#"
echo "pid: $$"

# ./a.sh hello world

# a
# 4252

# $*和$@的区别在于，$*等价于"hello world",$@等价于"hello""world"

for i in "$*"; do
	echo $i
done

for i in "$@"; do
	echo $i
done

# hello world
# hello
# world

# 在shell脚本中传递的参数中如果包含空格，应该使用单引号或者双引号将该参数
# 括起来，以便于脚本将这个参数作为整体来接收

for i in "$@"; do
	echo $i
done

# ./a.sh hello "world !"

# hello 
# world !

# shell脚本中在使用参数之前可以先校验参数是否存在

if [-n "$1"]; then
	echo $1
else 
	echo "null args"
fi

# ./a.sh hello
# hello

# ./a.sh
# null args






