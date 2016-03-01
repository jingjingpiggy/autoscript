#!/bin/bash

rpm -e aiqb --nodeps
rpm -e libiaaiq --nodeps
rpm -e libiacss --nodeps
rpm -e libcamhal --nodeps
rpm -e icamerasrc --nodeps

rpm -ivh aiqb-*.rpm --nodeps
rpm -ivh libiaaiq-*.rpm --nodeps
rpm -ivh libiacss-*.rpm --nodeps
rpm -ivh libcamhal-*.rpm --nodeps
rpm -ivh --nodeps --noparentdirs --prefix `pkg-config --variable=pluginsdir gstreamer-1.0` icamerasrc-*.rpm
