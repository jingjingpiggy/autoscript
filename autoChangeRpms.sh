#!/bin/bash

sudo rm /home/icg/public_html/latest_stable/*
sudo cd /home/icg/public_html/latest_pi

pi2base=`echo PI_BUILD-libcamhal*.rpm`
detail=`echo ${pi2base:9}`
sudo mv PI_BUILD-libcamhal*.rpm BASE-$detail

pi2base=`echo PI_BUILD-icamerasrc*.rpm`
detail=`echo ${pi2base:9}`
sudo mv PI_BUILD-icamerasrc*.rpm BASE-$detail

sudo mv * /home/icg/public_html/latest_stable/

