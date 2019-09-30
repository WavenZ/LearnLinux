#!/bin/bash

# printf命令

# printf由POSIX标准所定义，因此使用printf的脚本比使用echo移植性好

# printf使用引用文本或空格分割的参数，外面可以在printf中使用格式化字符串，
# 还可以定制字符串的宽度、左右对齐方式等。
# 使用pirntf不会像echon自动添加换行符

# printf命令的语法：printf format-string [argument...]

printf "Hello, World!\n"

# >> Hello, World!\n"

printf "%-10s %-8s %-4s\n" Name Gender Weight
printf "%-10s %-8s %-4.2s\n" Michael male 80.50
printf "%-10s %-8s %-4.2s\n" Jack male 88.23
printf "%-10s %-8s %-4.2s\n" Steve male 64.23

# >> Name      Gender    Weight
# >> Michael   male      80.50
# >> Jack      male      88.23
# >> Steve     male      64.23

# %-10s指的是宽度为10个字符，负号表示左对齐
# %-4.2f指的是保留两位小数

printf "%d %s\n" 1 "Hello"

# >> 1 Hello

# 值得注意的是，format部分既可以用双引号也可以用单引号，不用引号也可以

printf "%s\n" "Hello World!"
printf '%s\n' "Hello World!"
printf  %s\n  "Hello World!"

# >> Hello World!
# >> Hello World!
# >> Hello World!n

# 如果只指定了一个参数，但多个的参数仍然会按照该格式输出，即format-string被重用

printf "%s\n" Hello World

# >> Hello
# >> World

# 如果没有[argements...],那么%s会由NULL代替，%d会由0代替

printf "%s and %d\n"

printf "%s\b%d" Hello 10

# printf中常用的转义字符有：

# \a 警告字符，通常为ASCII的BEL字符
# \b 后退
# \c 抑制输出结果中任何结尾的换行字符（只在%b格式指示符控制下的参数字符串有效）
#    而且，任何留在参数里的字符、任何接下来的参数以及任何留在字符串中的字符，都被忽略
# \f 换页
# \n 换行
# \r 回车
# \t 水平制表符
# \v 垂直制表符
# \\ 反斜杠字符
# \ddd  表示1到3位数八进制值的字符
# \0ddd 表示1到3位的八进制字符

printf "\a\n"
printf "Hello\bWorld 1!"
printf "\c Hello World! 2\n"


printf "\f Hello World 3\n"
printf "Hello \r World 4!"
printf "\t Hello \tWorld! 5\n"
printf "\v Hello \vWorld! 6\n"
printf "\\ Hello \\World! 7\n"
printf "Hello World!\'s'\n"
printf "Hello World!\09\n"








