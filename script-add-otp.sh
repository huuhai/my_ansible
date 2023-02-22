##==========REDHAT 8==========
#!/bin/sh


#selinux-policy-devel and policycoreutils-devel unzip

## Create folder ace
##sudo sudo su
##123456
mkdir /var/ace
cd /tmp
unzip AM_Config.zip
cp /tmp/sdconf.rec /var/ace/
tar -xvf PAM-Agent_v8.1.2.126.10_02_20_16_28_37.tar -C /opt/
cd /var/ace

##sua dong nay tuong ung voi IP cua may chu linux
echo 'CLIENT_IP=192.168.157.145' > sdopts.rec

## Disable SELINUX
echo "Disable SELinux"
setenforce 0  > /dev/null 2>&1
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
echo "Done"

##Create User
##listUsers=(duongnvmk binhpn hainh giangnt vietpt)
listUsers=(hainh)
password=Gtelst@123456
for user in ${listUsers[*]}
do
	if [[ $(grep "^$user" /etc/passwd) != "$user" ]]; 
	then
		useradd -m $user -p $password > /dev/null 2>&1
		chage -M 99999 $user;
	fi
## neu cho user co quyen sudo su thi mo comment doan code nay
##	if [ ! $(grep "^$user" /etc/sudoers) ];
##	then
##		echo -e "$user\tALL=(ALL)\tALL" >> /etc/sudoers
##	fi
done

##Configure sshd_config
sed -i 's/UsePAM yes/UsePAM yes/' /etc/ssh/sshd_config
sed -i 's/UsePAM no/UsePAM yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config

if [[ ! $(grep 'AllowUsers' /etc/ssh/sshd_config) ]];
then
        printf "AllowUsers ${listUsers[*]}" >> /etc/ssh/sshd_config
else
        sed -i -e "s/AllowUsers/AllowUsers ${listUsers[*]}/" /etc/ssh/sshd_config
fi

if [[ ! $(grep 'DenyUsers' /etc/ssh/sshd_config) ]]; 
then
  echo -e "\nDenyUsers all" >> /etc/ssh/sshd_config
fi

systemctl restart sshd

##install agent PAM
echo 'y
Accept
0
/var/ace
/opt
y' > /opt/PAM-Agent_v8.1.2.126.10_02_20_16_28_37/installoptions.conf

/opt/PAM-Agent_v8.1.2.126.10_02_20_16_28_37/install_pam.sh -s < /opt/PAM-Agent_v8.1.2.126.10_02_20_16_28_37/installoptions.conf

String="auth required pam_securid.so"
##config remote file
sed -i -e 's/^auth/#auth/' /etc/pam.d/remote
if [ ! $(grep --regexp='auth*.*required*.*pam_securid\.so' /etc/pam.d/remote) ]; 
then
  echo $String >> /etc/pam.d/remote
fi

##config login file
sed -i -e 's/^auth/#auth/' /etc/pam.d/login
if [ ! $(grep --regexp='auth*.*required*.*pam_securid\.so' /etc/pam.d/login) ]; 
then
  echo $String >> /etc/pam.d/login
fi

##config su file
sed -i -e 's/^auth/#auth/' /etc/pam.d/su
if [ ! $(grep --regexp='auth*.*required*.*pam_securid\.so' /etc/pam.d/su) ]; 
then
  echo $String >> /etc/pam.d/su
fi

##config sshd file
sed -i -e 's/^auth/#auth/' /etc/pam.d/sshd
if [ ! $(grep --regexp='auth*.*required*.*pam_securid\.so' /etc/pam.d/sshd) ]; 
then
  echo $String >> /etc/pam.d/sshd
fi

##config sudo file
sed -i -e 's/^auth/#auth/' /etc/pam.d/sudo
if [ ! $(grep --regexp='auth*.*required*.*pam_securid\.so' /etc/pam.d/sudo) ]; 
then
  echo $String >> /etc/pam.d/sudo
fi

##config mfa_api_template.properties
sed -i 's/ENABLE_AGENT_REPORTING=/ENABLE_AGENT_REPORTING=1/' /var/ace/conf/mfa_api_template.properties

##config mfa_api.properties
echo 'ENABLE_AGENT_REPORTING=1' >> /var/ace/conf/mfa_api.properties

##config sd_pam.conf
sed -i 's/ENABLE_USERS_SUPPORT=0/ENABLE_USERS_SUPPORT=1/' /etc/sd_pam.conf
sed -i 's/INCL_EXCL_USERS=0/INCL_EXCL_USERS=1/' /etc/sd_pam.conf
sed -i 's/LIST_OF_USERS=/LIST_OF_USERS=ngocpm:dokd:vuht/' /etc/sd_pam.conf

##config SecurID Trace Logging
sed -i 's/RSATRACELEVEL=0/RSATRACELEVEL=8/' /etc/sd_pam.conf
sed -i 's/RSATRACEDEST=/RSATRACEDEST=/var/log/Authen_SecurID' /etc/sd_pam.conf

##test connect
/opt/pam/bin/64bit/acestatus
