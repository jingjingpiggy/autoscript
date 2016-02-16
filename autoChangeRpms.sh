#!/bin/bash

rm ~/public_html/latest_stable/*
cd ~/public_html/latest_pi

pi2base=`echo PI_BUILD-libcamhal*.rpm`
detail=`echo ${pi2base:9}`
mv PI_BUILD-libcamhal*.rpm BASE-$detail

pi2base=`echo PI_BUILD-icamerasrc*.rpm`
detail=`echo ${pi2base:9}`
mv PI_BUILD-icamerasrc*.rpm BASE-$detail

mv * ~/public_html/latest_stable/

