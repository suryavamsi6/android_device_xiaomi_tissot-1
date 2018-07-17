@echo off
zip -r -1 "%~dp0\tissot_manager.zip" *
adb push tissot_manager.zip /tissot_manager/
adb shell chmod 777 /tissot_manager/*
del tissot_manager.zip
::adb shell /sbin/tissot_manager.sh

