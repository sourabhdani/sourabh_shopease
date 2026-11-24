#!/bin/bash
# users_setup.sh - creates the ShopEase team and locks down /opt/shopease
set -e
BASE=/opt/shopease

# 1. Groups (-f = do not fail if the group exists)
sudo groupadd -f shopease
sudo groupadd -f developers

# 2. Users (only create a user if it does not exist yet)
id devops1 &>/dev/null || sudo useradd -m -s /bin/bash -G shopease,developers devops1
id dev1    &>/dev/null || sudo useradd -m -s /bin/bash -G shopease,developers dev1
id tester1 &>/dev/null || sudo useradd -m -s /bin/bash -G shopease tester1

# 3. sudo rights: devops1 is admin, dev1 may only restart Nginx
sudo usermod -aG sudo devops1
echo "dev1 ALL=(root) /usr/bin/systemctl restart nginx" > /tmp/dev1.sudoers
sudo visudo -cf /tmp/dev1.sudoers          # check the rule BEFORE installing it
sudo install -m 440 -o root -g root /tmp/dev1.sudoers /etc/sudoers.d/dev1

# 4. Ownership and permissions
sudo chown -R devops1:shopease $BASE
sudo chmod 750 $BASE
sudo chgrp -R developers $BASE/app
sudo chmod 775 $BASE/app
sudo chmod 664 $BASE/app/index.html
sudo chmod 700 $BASE/config $BASE/scripts $BASE/backups
sudo chmod 600 $BASE/config/app.env
sudo chmod 750 $BASE/logs
sudo chmod 640 $BASE/logs/access.log

echo "Team ready:"
for u in devops1 dev1 tester1; do id $u; done
sudo ls -l $BASE
