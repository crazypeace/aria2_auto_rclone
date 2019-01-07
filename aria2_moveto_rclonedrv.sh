#!/bin/bash

# rclone链接的网盘的名称，也就是rclone config显示的Name那一列
rcloneDrive='gdrv'                 
# aria2下载目录，也就是aria2的dir配置项的值
downloadPath='/usr/local/caddy/www/aria2/Download'  

# Aria2传给这个脚本的参数 
# $1是一个序列号，一般没有实际用处
# $2是文件个数。如果是HTTP/FTP下载，文件个数一般是1。如果是BT下载，文件个数一般大于1。
# $3是文件路径。如果是多个文件(如BT下载)，就是第1个文件的路径。

if [ $2 -eq 0 ]; then      # 没有文件，直接返回
  exit 0  
elif [ $2 -eq 1 ]; then    # 1个文件，直接处理
  # eg: rclone move /downloadPath/a.jpg gdrv:
  su - -c "rclone move \"$3\" $rcloneDrive:"  
  exit 0
else    # 多个文件，一般是BT下载的情况 
  filePath=$3     # eg: /downloadPath/bt/a/b/c/d.jpg
  while true; do  
    # 剥一层目录 eg: 从 /downloadPath/bt/a/b/c/d.jpg 得到 /downloadPath/bt/a/b/c  
    dirnameStr=`dirname "$filePath"`    
    if [ "$dirnameStr" = "$downloadPath" ]; then    # 剥一层目录就到aria2下载目录了，说明 filePath 应该为 /downloadPath/bt     
      # eg: 从 /downloadPath/bt 得到 bt
      basenameStr=`basename "$filePath"`	  
      # eg: rclone move /downloadPath/bt gdrv:bt
      su - -c "rclone move \"$filePath\" $rcloneDrive:\"$basenameStr\""
      # 删除VPS上残留的目录 eg: rm -rf /downloadPath/bt
      rm -rf "$filePath"            
      exit 0      
    elif [ "$dirnameStr" = "/" ]; then              #脚本出问题了，剥到根目录了，还没匹配到aria2下载目录
      # 打印错误日志
      echo "`date` [ERROR] rcloneDrive=$rcloneDrive;downloadPath=$downloadPath;[$1];[$2];[$3];" >> /tmp/aria2_download_complete.log
      exit 0
    else
      filePath=$dirnameStr
    fi
  done
fi

