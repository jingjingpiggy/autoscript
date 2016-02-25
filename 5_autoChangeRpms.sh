#!/bin/bash

ssh icg@yocto-build 'sudo rm /home/icg/public_html/latest_stable/*'
ssh icg@yocto-build 'sudo mv /home/icg/public_html/latest_pi/* /home/icg/public_html/latest_stable'
