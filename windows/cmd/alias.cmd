@echo off

title Terminal
prompt hypercurious@%USERNAME%[$T]$H$H$H$H]$G
cd %userprofile%\Desktop

DOSKEY ll=ls -la
DOSKEY py=python $1
DOSKEY ceid=cd %userprofile%\Desktop\CEID
DOSKEY diogenis=ssh username@diogenis.ceid.upatras.gr
DOSKEY alias=vim %userprofile%\alias.cmd
DOSKEY rc=vim %userprofile%\.vimrc
DOSKEY sd=shutdown -s -t $1
DOSKEY abort=shutdown -a
DOSKEY clear=cls

cls
