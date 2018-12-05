#!/bin/bash

# rclone链接的网盘的名称，也就是rclone config显示的Name那一列
rcloneDrive='eduGdrv'                 
# aria2下载目录，也就是aria2的dir配置项的值
downloadPath='/usr/local/caddy/www/aria2/download'  

# 传给这个脚本的参数 
# $2是文件个数。如果是HTTP/FTP下载，文件个数一般是1。如果是BT下载，文件个数一般大于1。
# $3是文件路径。如果是多个文件(如BT下载)，就是第1个文件的路径。
echo "`date`,[$1],[$2],[$3];" >> /tmp/aria2_download_complete.log

if [ $2 -eq 0 ]; then      #没有文件，直接返回
  echo "`date`,$LINENO" >> /tmp/aria2_download_complete.log 
  exit 0
elif [ $2 -eq 1 ]; then    #1个文件，直接处理
  echo "`date`,$LINENO" >> /tmp/aria2_download_complete.log   

  #从路径得到文件名 eg: 从 /downloadPath/a.jpg 得到 a.jpg
  basenameStr=`basename "$3"`  
  echo "`date`,$LINENO,basenameStr=$basenameStr" >> /tmp/aria2_download_complete.log  
  
  #eg: rclone move /downloadPath/a.jpg eduGdrv:
  su - -c "rclone move \"$3\" $rcloneDrive:"
  
  exit 0
else    #多个文件，一般是BT下载的情况
  echo "`date`,$LINENO" >> /tmp/aria2_download_complete.log   

  #要得bt下载生成的目录名 eg: 从 /downloadPath/bt/a/b/c/d.jpg 得到 /downloadPath/bt
  filePath=$3
  while true; do  
    #剥一层目录 eg: 从 /downloadPath/bt/a/b/c/d.jpg 得到 /downloadPath/bt/a/b/c  
    dirnameStr=`dirname "$filePath"`
    echo "`date`,$LINENO,dirnameStr=$dirnameStr" >> /tmp/aria2_download_complete.log   
	
    if [ "$dirnameStr" = "$downloadPath" ]; then    #剥到aria2下载目录了
      basenameStr=`basename "$filePath"`
      echo "`date`,$LINENO,basenameStr=$basenameStr" >> /tmp/aria2_download_complete.log  	  

      #eg: rclone move /downloadPath/bt eduGdrv:bt
      su - -c "rclone move \"$filePath\" $rcloneDrive:\"$basenameStr\""
	  
      rm -r -f "$filePath"                           #删除VPS上残留的目录
   
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

