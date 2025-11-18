# start status bar
slstatus &

# notifications
dunst &

# set wallpaper
#feh --bg-fill ~/Pictures/<image> &

# compositor
picom --vsync --backend glx &

# screen locker
xset s 300
xss-lock --transfer-sleep-lock -- lock_screen &

toggle_lock check

exec dbus-run-session dwm > ~/.dwm.log
