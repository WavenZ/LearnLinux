#!/bin/bash

# 重定向命令列表如下：

# command > file	将输出重定向到file
# command < file	将输入重定向到file
# command >> file	将输出以追加的方式重定向到file
# n > fiile		将文件描述符为n的文件重定向到file
# n >> file		将文件描述符为n的文件以追加的方式重定向到file
# n >& m		将输出文件m和n合并
# n <& m		将输入文件m和n合并
# << tag		将开始标记tag和结束标记tag之间的内容作为输入

# 需要注意的是，文件描述符0通常是标准输入，1是标准输出，2是标准错误输出


# 1.输出重定向

# 重定向一般在命令间插入特定的符号来实现。特别的，这些符号得语法如下：

## command > file1

# 上面这个命令执行cammand然后将输出的内容存入file1

# 如果要追加到file1文件后，用command >> file1

who > users

ls >> users

# 2.输入重定向

# 输入重定向的语法为：

## command < file1

# 统计users文件的行数：

wc -l users
wc -l < users

# >> 10 users
# >> 10

# 其中，第一种方式会输出文件名，而第二种不会

# 3.重定向深入

# 一般情况下，shell运行时会打开三个文件:

## 标准输入文件(stdin): stdin的文件描述符为0，程序从stdin读取数据
## 标准输出文件(stdout): stdout的文件描述符为1，程序从stdout输出数据
## 标准错误文件(stderr)：stderr额文件描述符为2，程序从stderr输出错误信息

# 如果希望stderr重定向到file，可以这样写：

## command 2 > file

# 如果希望stderr追加到file文件末尾，可以这样写：

## command 2 >> file

# 其中2表示标准错误文件

# 如果希望将stdout和stderr合并后重定向到file，可以这样写：

## command > file 2>&1 或
## command >> file 2>&1

# 如果希望对stdin和stdout都重定向，可以这样写：

## command < file1 > file2

# 4.Here Document

# Here Document是shell中的一种特殊的重定向方式，用来将输入重定向到一个交互式shell脚本或程序

# 它的基本的形式如下：

## command << dilimiter
##	document
## dilimiter

# 它的作用是将两个delimiter之间的内容(document)作为输入传递给command。
# 其中，结尾的dilimiter一定要定格写，后面也不能有任何字符。

wc -l << USERNAMES
Michael
Jack
Steve
USERNAMES


# 5./dev/null文件

# 如果希望执行某个命令，但又不希望在屏幕上显示输出，可以将输出重定向到/dev/null

## command >> /dev/null

# /dev/null是一个特殊的文件，写入到它的内容都会被丢弃;
# 如果尝试从该文件读取内容，那么什么也读不到

# 如果希望屏蔽stdout和stderr，可以这样写：

## command > /dev/null 2>&1






