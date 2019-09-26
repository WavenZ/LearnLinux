#!/bin/bash
# author: lang
# <lang.zheng@intel.com>

# 1. Shell数组

# Bash Shell只支持一维数组，初始化时不需要定义数组大小，下标从0开始

# Shell数组用括号来表示，元素用空格分隔开：

array=(A B "C" D)

# 也可以直接用下标来定义数组

my_array[0]="Michael"
my_array[1]="Jack"
my_array[2]="Steve"

# 读取数组元素的一般格式是

echo ${my_array[0]}

# >> Michael



# 使用@或*可以获取数组中的所有元素

echo ${my_array[@]}
echo ${my_array[*]}

# >> Michael Jack Steve
# >> Michael Jack Steve

# 获取数组长度的方法与获取字符串长度的方法相同

echo ${#my_array[*]}
echo ${#my_array[@]}

# >> 3
# >> 3
