#!/bin/bash

killall polybar
killall dropbox
killall blueman-applet

/usr/local/bin/polybar -r example &
/bin/sleep 0.25
blueman-applet &
/bin/sleep 0.25
dropbox start
