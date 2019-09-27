#!/bin/bash
# author:lang

# Shell基本运算符

# 原生bash不支持简单的数学运算，但是可以通过其他命令来实现，例如awk和expr，expr最常用

# expr是一款表达式计算工具，使用它能完成表达式的求值操作

val=`expr 2 + 3`
echo "2 + 3 = $val"

# >> 2 + 3 = 5

# 值得注意的是，表达式和运算符之间要有空格，例如`expr 2+3`是不对的

# 1.算数运算符

# 下面是常用的算数运算符

a=10;b=20

echo "a + b = `expr $a + $b`"
echo "a - b = `expr $a - $b`"
echo "a * b = `expr $a \* $b`"
echo "a / b = `expr $a / $b`"
echo "a % b = `expr $a % $b`"
echo "a == b = $[ $a == $b ]"
echo "a != b = $[ $a != $b ]"

# >> a + b = 30
# >> a - b = -10
# >> a * b = 200
# >> a / b = 0
# >> a % b = 10
# >> a == b = 0
# >> a != b = 1

# 值得注意的是，称号(*)前面必须加上反斜杠才能实现乘法运算。

# 2. 关系运算符

# shell中的关系运算符只支持数字，不支持字符串，除非字符串是数字

# 下面是常用的关系运算符

# -eq : 等于
# -ne : 不等于
# -gt : 大于
# -ge : 大于等于
# -lt : 小于
# -le : 小于等于

if [ $a -eq $b ]
then
	echo "a is equals to b!"
else
	echo "a is not equals to b!"
fi

# >> a is equals to b! 

# 3. 布尔运算符

# 布尔运算符有与或非三种

#  ! : 非
# -o : 或
# -a : 与

if [ $a > 0 -a $b > 0 ]
then
	echo "a and b are both positive!"
fi


# 4. 逻辑运算符

# 逻辑运算符有两个：&& ||

if [[ $a -gt 0 && $b -gt 0 ]]
then
	echo "a and b are both positive!"
fi

# 5. 字符串运算符

# 下面列出了常用的字符串运算符

#  = : 检测两个字符串是否相等
# != : 检测两个字符串是否不等
# -z : 检测字符串长度是否为0
# -n : 检测字符串长度是否不为0
#  $ : 检测字符串是否为空

stra="Hello"
strb="World"

if [ $stra=$strb ]
then
	echo "a = b"
else
	echo "a != b"
fi

if [ -z $stra ]
then 
	echo "a is empty!"
else
	echo "a is not empty!"
fi

if [ $stra ]
then 
	echo "a is not empty!"
else
	echo "a is empty!"
fi

# 6. 文件测试运算符

# 文件测试运算符用于测试Unix文件的各种属性

# -b 检测文件是否是块设备
# -c 检测文件是否是字符设备
# -d 检测文件是否抱哈你目录
# -f 检测文件是否是普通文件
# -g 检测文件是否设置了SGID位
# -k 检测文件是否设置了sticky bit
# -p 检测文件是否是有名管道
# -u 检测文件是否设置了SUID
# -r 检测文件是否刻度
# -w 检测文件是否可写
# -x 检测文件是否可执行
# -s 检测文件是否为空
# -e 检测文件（或目录）是否存在
# -S 检查文件是否是socket
# -L 检查文件是否是一个符号链接


