# Disable KWin and use i3gaps as WM
# This file must be in env directory to work
# export KDEWM="$HOME/.i3/i3-plasma"
export KDEWM="/usr/bin/kwin_wayland"

# Compositor (Animations, Shadows, Transparency)
# xcompmgr -C
# call compton from i3 config
compton -cCFb --backend glx --vsync opengl --config $HOME/.config/compton/compton.conf
