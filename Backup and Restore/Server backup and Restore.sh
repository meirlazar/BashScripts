# Backup Script of Server

DATE=$(date +"%b%d%Y")
BKUPDIR="/media/ALLDATA3/Installs/Ubuntu_latest/Backups/server/$DATE"


# Backup all important directories
DIRS="/etc /var /home/meir /root /opt/couchpotato"

# Stop all LAMP services before running backup

systemctl stop apache2 || exit
systemctl stop mysql || exit

for X in ${DIRS}; do 
rsync -av ${X} ${BKUPDIR}
done 

systemctl start apache2
systemctl start mysql

# Backup the cron
crontab -l > ${BKUPDIR}/crontab.root
crontab -u meir -l > ${BKUPDIR}/crontab.meir


echo "END OF SCRIPT. CLOSE IT"
read -p "END OF SCRIPT, HIT ENTER TO CLOSE"
exit


###########################################################################################
###########################################################################################
###########################################################################################
###########################################################################################


# Restore Script of Server

echo "Typically /media/ALLDATA3/Installs/Ubuntu_latest/Backups/server/$DATE is used for backups"
read -p "What Dir to use for the backups": BKUPDIR


##### First Install the Base OS Server without anything else

###############################################################################

# Create NFS share dirs

mkdir -p /media/ALLDATA1 /media/ALLDATA2 /media/ALLDATA3 /media/PRON /media/MEDIA


###############################################################################

# Setup /etc/fstab

cat >> /etc/fstab << EOF
192.168.1.15:/media/ALLDATA1/ /media/ALLDATA1 nfs rsize=37000,wsize=37000,noacl,rw,hard,intr,noatime,nodev,nolock,fsc,nfsvers=3 0 0 
192.168.1.15:/media/ALLDATA2/ /media/ALLDATA2 nfs rsize=37000,wsize=37000,noacl,rw,hard,intr,noatime,nodev,nolock,fsc,nfsvers=3 0 0
192.168.1.15:/media/ALLDATA3/ /media/ALLDATA3 nfs rsize=37000,wsize=37000,noacl,rw,hard,intr,noatime,nodev,nolock,fsc,nfsvers=3 0 0
192.168.1.44:/media/RAID0/PRON /media/PRON nfs rsize=37000,wsize=37000,noacl,rw,hard,intr,noatime,nodev,nolock,fsc,nfsvers=3
192.168.1.44:/media/RAID0/MEDIA /media/MEDIA nfs rsize=37000,wsize=37000,noacl,rw,hard,intr,noatime,nodev,nolock,fsc,nfsvers=3
EOF

mount -a || echo "Cannot mount remote dirs. Script will not work until you fix this"

###############################################################################
# Setup the STATIC IP

rsync -av ${BKUPDIR}/etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml
sudo netplan apply

###############################################################################

# Restore /home/meir

rsync -av ${BKUPDIR}/home/meir/.bashrc /home/meir/.bashrc
source /home/meir/.bashrc


###############################################################################


# Disable the UFW firewall
systemctl disable ufw
systemctl stop ufw

###############################################################################

# Setup APACHE LINKS

ln -s /media/ALLDATA3/Installs/ibmrepo/ /var/www/html/
ln -s "/media/MEDIA/Videos/Instructional Videos/Computer_Tutorials/" /var/www/html/
ln -s "/media/MEDIA/Installs/Games/Flash/" /var/www/html/

###############################################################################

# CHECK REPOS

apt-get update && apt-get upgrade -y

###############################################################################

# Install LAMP 

add-apt-repository universe
add-apt-repository ppa:nijel/phpmyadmin
LAMP="apache2 apache2-utils mysql-client mysql-server phpmyadmin git php7.2 php7.2-mysql curl libapache2-mod-php7.2 php7.2-cli php7.2-cgi php7.2-gd"
apt-get install ${LAMP} -y

###############################################################################

# MYSQL DB RESTORE

systemctl stop mysql || exit

mv /var/lib/mysql /var/lib/mysql.orig
rsync -av ${BKUPDIR}/var/lib/mysql /var/lib/mysql
chown -R mysql:mysql /var/lib/mysql
systemctl start mysql

###############################################################################


# APACHE CONFIG RESTORE

systemctl stop apache2 || exit

mv /etc/apache2/apache2.conf /etc/apache2/apache2.conf.orig
rsync -av ${BKUPDIR}/etc/apache2/apache2.conf /etc/apache2/apache2.conf
rsync -av ${BKUPDIR}/etc/apache2/sites-available /etc/apache2/sites-available
a2enmod rewrite
systemctl start apache2

###############################################################################

# Install and Configure PLEX

echo "deb https://downloads.plex.tv/repo/deb public main" | tee /etc/apt/sources.list.d/plexmediaserver.list
apt update && apt install plexmediaserver
systemctl stop plexmediaserver
rsync -av ${BKUPDIR}/var/lib/plexmediaserver /var/lib/plexmediaserver
systemctl start plexmediaserver


###############################################################################

# Install ATOMIC TOOLKIT

git clone https://github.com/htpcBeginner/AtoMiC-ToolKit /home/meir/AtoMiC-ToolKit
cd /home/meir/AtoMiC-ToolKit/
bash setup.sh

###############################################################################

# Restore SABNZBPLUS

rsync -av ${BKUPDIR}/etc/default/sabnzbdplus /etc/default/sabnzbdplus

###############################################################################

# Restore CouchPotato

rsync -av ${BKUPDIR}/opt/couchpotato/data/settings.conf /opt/couchpotato/data/settings.conf

###############################################################################

# Restore TRANSMISSION

rsync -av ${BKUPDIR}/home/meir/.config/transmission-daemon/settings.json /home/meir/.config/transmission-daemon/settings.json
rsync -av ${BKUPDIR}/etc/transmission-daemon/settings.json /etc/transmission-daemon/settings.json

###############################################################################

# Restore /var/www/html files

systemctl stop apache2 || exit
rsync -av ${BKUPDIR}/var/www/html /var/www/html
chown -R www-data:www-data /var/www/html
chmod 664 /var/www/html/.htaccess
systemctl start apache2 || exit

###############################################################################

# Restore the crontab
crontab ${BKUPDIR}\crontab.root
crontab -u meir ${BKUPDIR}\crontab.meir

###############################################################################



