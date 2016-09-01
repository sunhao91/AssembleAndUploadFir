#!/usr/bin/env bash

apiToken="xxxFirToken"
temp=".hppBuildCache"


build(){
    echo "-------------set version-------------"
    awk '{if($0 ~ /versionName/) {print "        versionName \"'$versionName'\" ";} else {print $0;}}'   "./$name/build.gradle" > "./$name/build.gradle.temp"
    awk '{if($0 ~ /versionCode/) {print "        versionCode '$version' ";} else {print $0;}}'  "./$name/build.gradle.temp" > "./$name/build.gradle"

    echo "-------------building-------------"
    gradle -q :$name:assembleRelease
    #这里应该做多做判断,生成出来的文件可能多样 == 懒得写了.
    if [ -f "./$name/build/outputs/apk/$name-release-unaligned.apk" ]; then
        echo "$name build success"
    else
        echo "$name build failed"
        return
    fi
}

upload(){
    echo "-------------request signKey-------------"

    result=$(curl -X "POST" "http://api.fir.im/apps" \
      -H "Content-Type: application/json" \
      -d "{\"type\":\"android\", \"bundle_id\":\"$bundleId\", \"api_token\":\"$apiToken\"}");

    binary=$(echo $result |awk -F '"binary"' '{print $2}');
    key=$(echo $binary |awk -F '"key"' '{print $2}'|awk -F '"' '{print $2}');
    token=$(echo $binary |awk -F '"token"' '{print $2}'|awk -F '"' '{print $2}');

    #这里应该做多做判断,生成出来的文件可能多样 == 懒得写了.
    filename="./$name/build/outputs/apk/$name-release-unaligned.apk"

    echo "-------------uploading-------------"
    result=$(curl  -F "key=$key"              \
        -F "token=$token"             \
        -F "file=@$filename"             \
        -F "x:name=$appName"             \
        -F "x:version=$versionName"         \
        -F "x:build=$version"               \
        -F "x:changelog=$changeLog"       \
        http://upload.qiniu.com);

    uploadStatus=$(echo $result |awk -F '"is_completed":' '{print $2}'|awk -F '}' '{print $1}');

    if [ "$uploadStatus" = "true" ]; then
        echo "$name  upload success!"
    else
        echo "$name upload failed!"
        return
    fi
}
if [ -d "../$temp" ]; then
    rm -rf ../$temp/*
else
    mkdir ../$temp
fi

echo "-------------copy-------------"
cp -rf * ../$temp

cd ../$temp
echo "-------------clean-------------"
gradle clean -q

####################################################################################################
echo "-------------build app-------------"
version=1
versionName=1.0
name=app
appName=HappyApp
bundleId="com.soohoo.hpp"
changeLog=""
build
upload

#echo "-------------build photo-------------"
#version=1
#versionName=1.0
#name=photo
#appName="图片大全"
#bundleId="com.soohoo.hpp.photo"
#changeLog=""
#build
#upload

####################################################################################################
echo "-------------移除临时文件-------------"
rm -rf ../$temp/*
