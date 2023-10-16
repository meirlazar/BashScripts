#!/bin/bash

# All things aliases

####################### ALIASES #######################################################################


# Our Personnal Aliases
alias df='df -hT -x "squashfs" -x "devtmpfs" -x "tmpfs"'
alias KILLZOMBIE="kill -HUP $(ps -A -ostat,ppid | grep -e '[zZ]'| awk '{print $2}')"
alias RIPCD="ripit --nointeraction"
alias wireless='sudo ifdown wlan0 && sudo ifup wlan0'
alias sound='sudo alsa force-reload'
alias XX='exit'
# SSH
alias chrome='/opt/google/chrome/chrome --disk-cache-size=2000000000'
# scanning
alias scanhttpopen='sudo nmap -p80 192.168.10.0/8 -oG - | grep 80/open'
alias aptreinstall_configgiles='sudo apt install --reinstall -o Dpkg::Options::="--force-confmiss" $1' # reisntall a package and all conf files with it
alias findpackagenamebyfile='sudo apt-file update; sudo apt-file find ${1:?Use filename as 1st arg}'
alias lsblk='lsblk -ibl --output-all | column -t | less -Ss'
alias force_hardrive_check_on_reboot='touch /forcefsck'
alias fixkeyboard='xmodmap;setxkbmap;xmodmap'
alias mail='mutt'
alias destroy='echo "use this command with a folder or filename" && shred -vfz -n 100'
alias sql='sudo mysql -u root -p'
alias mypasswords='/usr/bin/pwmanager'
alias shrinkphotos='find . -type f -name "*.jpg" -size +1M -exec jpegoptim  --max=70 {} \;'
alias messenger='finch'
alias services='sudo sysv-rc-conf'

# what provides a file in ubuntu
alias whatprovides='sudo dpkg -S "*/${1:?Usage:1st param is filename}"'
alias whatprovides1='sudo dpkg-query --search "*/${1:?Usage:1st param is filename}"'

# WAKEONLAN
alias WAKEONLAN='wakeonlan ${1:?Use Mac Address as arg}'


# -> Prevents accidentally clobbering files.
alias mkdir='mkdir -p'
alias r='rlogin'
alias ..='cd ..'
alias path='echo -e ${PATH//:/\\n}'
      # Assumes LPDEST is defined
alias centerim='/usr/local/bin/centerim'
      # Pretty-print using enscript
alias du='du -kh'
# The 'ls' family (this assumes you use the GNU ls)
alias la='ls -Al'               # show hidden files
alias ls='ls -hF --color'       # add colors for filetype recognition
alias lx='ls -lXB'              # sort by extension
alias lk='ls -lSr'              # sort by size
alias lc='ls -lcr'              # sort by change time
alias lu='ls -lur'              # sort by access time
alias lr='ls -lR'               # recursive ls
alias lt='ls -ltr'              # sort by date
alias lm='ls -al |more'         # pipe through 'more'
alias du='du -kh'

# tailoring 'less'
alias more='less'
export PAGER=less

# spelling typos
alias xs='cd'
alias vf='cd'
alias moer='more'
alias moew='more'
alias kk='ll'
alias top='xtitle Processes on $HOST && top'
alias make='xtitle Makilng $(basename $PWD) ; make'
alias ncftp="xtitle ncFTP ; ncftp"
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'


# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
alias dfonly="df -h | grep -E -v 'loop|tmpfs|udev'"
alias firefox='nohup firefox  -P Normal > /dev/null 2>&1 &'
alias SLEEPSERVER='ssh ${1:?Use IP or hostname as arg} "virsh --connect qemu:///system suspend Server"'
alias RESUMESERVER='ssh ${1:?Use IP or hostname as arg} "virsh --connect qemu:///system resume Server"'
alias logoff='sudo service lightdm restart'
alias suspend='systemctl suspend'

# FIX STUFF
alias FIXSHELL="dbus-send --type=method_call --print-reply --dest=org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Eval string:'global.reexec_self()'"
alias fixnfs='sudo /etc/init.d/autofs restart'
alias fixaudio='sudo killall pulseaudio; rm -r ~/.config/pulse/*; rm -r ~/.pulse*'
alias FIXGNOMECONTROLCENTER='dconf reset -f /org/gnome/control-center/ && gnome-control-center'
alias zenmap='sudo zenmap'
##############################################################################
