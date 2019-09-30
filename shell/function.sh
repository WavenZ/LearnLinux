#!/bin/bash

# linux shell中的函数定义格式如下：
# [ function ] funcname [()]
# {
# 	do something...
#	[return int;]
# }

# 其中，function关键字是可选的
# 另外，return返回也是可选的，如果不加，将已最后一条命令运行结果作为返回值

func(){
	echo "In fun().."
}

func

# >> In fun()...


func1(){
	return 2;
}

func1

echo "Return val : $?"

# 值得注意的是，函数所有函数在使用前必须定义，因此函数往往放在脚本开始部分。




# 在Shell中，调用函数时可以向其传递参数。
# 在函数体内部，通过$n的形式来获取参数的值

calcSum(){
	return $(($1 + $2))
}

calcSum 2 3


echo $?


# 此外，还有如下几个特殊字符用于处理参数

# $# 传递到脚本的参数个数
# $* 以一个单字符串显示所有向脚本传递的参数
# $$ 脚本运行的当前进程号
# $! 后台运行到额最后一个进程的ID号
# $@ 与$*相同，但是使用时返回每个参数
# $- 显示Shell使用的当前选项，与set命令功能相同
# $? 显示最后命令的推出状态。
