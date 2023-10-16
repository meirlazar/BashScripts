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
alias sshserver1='ssh -p 621 -X meir@192.168.1.21'
alias sshoffice='ssh -X -p 645 officelaptop'
alias sshlinuxgamer='ssh -X -p 644 meir@192.168.1.44'
alias chrome='/opt/google/chrome/chrome --disk-cache-size=2000000000'
alias sshelana='ssh lazar@elanaubuntulaptop'
# scanning
alias checkeverything='/media/ALLDATA2/M_J/Meir/vcProjects/BashScripts/Monitoring/checkeverything.sh'
alias scancameras='sudo nmap -p80 192.168.10.0/8 -oG - | grep 80/open'
alias aptreinstall_configgiles='sudo apt install --reinstall -o Dpkg::Options::="--force-confmiss" $1' # reisntall a package and all conf files with it
alias findpackagenamebyfile='sudo apt-file update; sudo apt-file find ${1:?Use filename as 1st arg}'
alias lsblk='lsblk -ibl --output-all | column -t | less -Ss'
alias force_hardrive_check_on_reboot='touch /forcefsck'
alias bitcoin_wallet='electrum'
alias scanmynetwork_deeply='sudo nmap -sT 192.168.1.0/8'
alias SCANVNC="sudo nmap 192.2.1.1-254 -p 5900 | grep -B4 -E 'open|filtered'  | grep '192.' | cut -d ' ' -f5"
alias fixkeyboard='xmodmap;setxkbmap;xmodmap'
alias mail='mutt'
alias destroy='echo "use this command with a folder or filename" && shred -vfz -n 100'
alias sql='sudo mysql -u root -p'
alias mypasswords='/usr/bin/pwmanager'
alias shrinkphotos='find . -type f -name "*.jpg" -size +1M -exec jpegoptim  --max=70 {} \;'
alias bulletin='wget -P -e -A pdf --no-directories -r -l1 https://www.chabadshul.org/images/bulletin/ && pdftotext shulbull.pdf && head shulbull.txt && rm shul*'
alias messenger='finch'
alias services='sudo sysv-rc-conf'
#alias Stop='transmission-remote lazar.linkpc.net:2812 -n admin:p0wer1nme -d 1 -u 0'
#alias Normal='transmission-remote lazar.linkpc.net:2812 -n admin:p0wer1nme -d 125 -u 15'
#alias Full_Blast='transmission-remote lazar.linkpc.net:2812 -n admin:p0wer1nme -D -u 60'
#alias Stop='transmission-remote lazar.linkpc.net:2812 -n admin:p0wer1nme -tall --stop'
#alias Start='transmission-remote lazar.linkpc.net:2812 -n admin:p0wer1nme -tall --start'
#alias aom='wine "/media/RAID0/MEDIA/Installs/Games/Age of Mythology/aomx.exe"'

# what provides a file in ubuntu
alias whatprovides='sudo dpkg -S "*/${1:?Usage:1st param is filename}"'
alias whatprovides1='sudo dpkg-query --search "*/${1:?Usage:1st param is filename}"'

# WAKEONLAN
alias KIDS4_WAKEUP='wakeonlan 00:23:AE:65:B0:AD'
alias KIDS3_WAKEUP='wakeonlan 00:1E:4F:D2:6E:4C'
alias KIDS2_WAKEUP='wakeonlan 00:23:AE:65:B7:3E'
alias KIDS1_WAKEUP='wakeonlan 00:23:AE:65:B5:D6'
alias YESHIVAPC_WAKEUP='wakeonlan 00:1d:09:22:ac:33'
alias SERVER_WAKEUP='wakeonlan 00:13:72:1b:db:8d'
alias GAMEPC_WAKEUP='wakeonlan 00:16:76:d9:5a:15'

# app aliases

alias slickedit='/opt/slickedit/bin/vs'

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

# spelling typos - highly personnal :-)
alias xs='cd'
alias vf='cd'
alias moer='more'
alias moew='more'
alias kk='ll'
alias top='xtitle Processes on $HOST && top'
alias make='xtitle Makilng $(basename $PWD) ; make'
alias ncftp="xtitle ncFTP ; ncftp"

alias videooffice='nohup ffmpeg -y -thread_queue_size 64K -f alsa -i default -f v4l2  -i /dev/video0 -acodec ac3 -ac 2 -ab 64k -vcodec libx264 -f matroska -s 800x600 -preset ultrafast -qp 16 /home/meir/Videos/Office_$(date +%F_%T).mp4 > /dev/null 2>&1 &'
alias watchoffice='nohup ffmpeg -y -thread_queue_size 64K -f alsa -i default -f v4l2  -i /dev/video0 -acodec ac3 -ac 2 -ab 64k -vcodec libx264 -f matroska -s 1280x720 -preset ultrafast -qp 16 /home/meir/Videos/Office_$(date +%F_%T).mp4 > /dev/null 2>&1 &'
alias stopoffice='pkill -f ffmpeg'
alias watchmyoffice="ssh officelaptop 'nohup /home/meir/dockerfiles/webcamstreamer/workingsilent.sh > /dev/null 2>&1 &'"
alias record='/home/meir/Apps/atbswp-linux/atbswp'
alias generatepass='chmod +x /media/ALLDATA2/M_J/Meir/vcProjects/BashScripts/randompasswordgen/newrandgen.sh; /media/ALLDATA2/M_J/Meir/vcProjects/BashScripts/randompasswordgen/newrandgen.sh'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'


# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
alias dfonly="df -h | grep -E -v 'loop|tmpfs|udev'"
alias firefox='nohup firefox  -P Normal > /dev/null 2>&1 &'
alias foxcont='nohup /usr/bin/firefox -P Meir > /dev/null 2>&1 &'
alias alarm='/home/meir/Documents/alarm.sh'
alias disarm='pkill -f /home/meir/Documents/alarm.sh'
alias SLEEPSERVER='ssh 192.168.1.21 "virsh --connect qemu:///system suspend Server"'
alias RESUMESERVER='ssh 192.168.1.21 "virsh --connect qemu:///system resume Server"'
alias logoff='sudo service lightdm restart'
alias suspend='systemctl suspend'

# FIX STUFF
alias FIXSHELL="dbus-send --type=method_call --print-reply --dest=org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Eval string:'global.reexec_self()'"
alias fixnfs='sudo /etc/init.d/autofs restart'
alias fixaudio='sudo killall pulseaudio; rm -r ~/.config/pulse/*; rm -r ~/.pulse*'
alias FIXGNOMECONTROLCENTER='dconf reset -f /org/gnome/control-center/ && gnome-control-center'
alias zenmap='sudo zenmap'
alias cameras='cvlc --vlm-conf /home/meir/Documents/Cameras/mosiac_vlc5.vlm'
##############################################################################
