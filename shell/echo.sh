#!/bin/bash

# echo命令

# 1.显示普通字符串

echo "Hello World!"

# >> Hello World!

# 其中，双引号可以直接省略

echo Heloo World!

# >> Hello World!

# 2.显示转义字符

echo "\"Hello World!\""

# >> "Hello World!"

# 3.显示变量

read str
echo "$str"

# 4.显示换行

echo -e "Hello! \n"
echo "Hi!"

# >> "Hello!
# >>
# >> Hi

# 5.显示不换行

echo -e "Hello! \c"
echo "Hi!"

# >> Hello! Hi!

# 6.显示结果定向至文件

echo "Hello World!" > log

# 7.原样输出字符串，不进行转义或取变量

name=Michael
echo '$name\"'

# >> $name\"

# 8.显示命令结果

echo `date`

# >> Sat Sep 28 09:57:41 CST 2019 

