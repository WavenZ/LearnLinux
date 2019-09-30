#!/bin/bash

# Shell流程控制

# shell的流程控制不可为空

# 1.if-else


# if condition
# then 
#	command1
# fi


# if condition
# then
#	command1
# else
#	command2
# fi


# if condition
# then
# 	command1
# elif condition2
# then 
#	command2
# else
# 	command2
# fi


# 2.for

# for var in item1 item2 ... itemN
# do
#	commands
# done

# 当变量值在列表里，for循环即执行一次所有命令，使用变量名获取列表中的当前取值。
# 命令可为任何有效的shell命令和语句
# in列表可以包含替换、字符串和文件名

for loop in 1 2 3 4 5 6
do
	echo "The val is : $loop"
done

for str in "Hello World!"
do
	echo $str
done

# for循环也可以写成类C语言的形式，用for(())即可：

for((i = 1; i < 5; i++))
do
	echo "$i "
done

# 3.while

# while condition
# do
# 	command
# done

i=1
while(( $i<=5 ))
do
	echo $i
	let "i++"
done

# while循环可用于读取键盘信息。
echo -n "Input a string:"
while read str
do
	echo "Length of string is ${#str}"
	echo -n "Input a string:"
done

# 无限循环的写法如下：

# while:
# do
#	command
# done

# while true
# do
# 	command
# done

# 4.until循环

# until循环一直执行到条件为true时停止

# until语法格式：

# until condition
# do 
# 	command
# done

a=0

until [ ! $a -lt 10 ]
do 
	echo $a
	let "a++"
done


# 5.case

# Shell case 和 c语言的switch语句类似

# 不同的是，case语句从符合某个模式开始的地方执行到;;为止

num=3

case $num in
	1) echo "num = 1"
	;;
	2) echo "num = 2"
	;;
	3) echo "num = 3"
	;;
	4) echo "num = 4"
	;;
	*) echo "num不属于[1, 4]"
esac
 
# 从上述表达式可以看到，*)的功能类似于C中的default分支


