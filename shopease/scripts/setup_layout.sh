#!/bin/bash
# setup_layout.sh - creates the ShopEase server folder layout
set -e
BASE=/opt/shopease
sudo mkdir -p $BASE/{app,config,logs,backups,scripts}
sudo chown -R "$USER":"$USER" $BASE
touch $BASE/config/app.env $BASE/app/index.html
echo "Layout ready:"
ls -l $BASE
