# ShopEase

Scripts and configuration for the **ShopEase** Linux web server, built in Module 1 of the
*DevOps with Multi-Cloud + GenAI* course (Project 1), and kept in Git from Module 2 (Project 2).

ShopEase is a simple online-shop website served by Nginx on Ubuntu. Around it, this repo holds
everything a DevOps engineer needs to rebuild the server: folder layout, users and permissions,
web server config, and a Telegram monitor that reports CPU and RAM every 15 minutes.

## What is in this repo

```
shopease/
├── README.md                        this file
├── .gitignore                       keeps secrets and logs out of Git
├── app/
│   └── index.html                   the ShopEase web page            (Class 4)
├── nginx/
│   └── shopease.conf                Nginx site config                 (Class 4)
├── scripts/
│   ├── setup_layout.sh              creates /opt/shopease folders     (Class 2)
│   ├── gen_log.sh                   writes a sample access log        (Class 2)
│   ├── users_setup.sh               team users, sudo, permissions     (Class 3)
│   ├── resource-alert.sh            CPU/RAM report to Telegram        (Class 5)
│   └── .telegram.env.example        template for the Telegram secrets (Class 5)
├── systemd/
│   ├── shopease-monitor.service     runs resource-alert.sh once       (Class 5)
│   └── shopease-monitor.timer       ... every 15 minutes              (Class 5)
└── cron/
    └── resource-alert.cron          the cron alternative to the timer (Class 5)
```

**Never committed:** the real `scripts/.telegram.env` (your bot token) and any `logs/`.
Copy `.telegram.env.example` and fill in your own values on the server instead.

## Deploy ShopEase on a fresh Ubuntu server

Run these steps in order, from your own admin account (one that can use `sudo`).

**1. Install the tools and get the code**

```bash
sudo apt update && sudo apt install -y nginx git
git clone git@github.com:<your-username>/shopease.git ~/shopease
cd ~/shopease
```

**2. Create the folder layout, the web page and a sample log**

```bash
./scripts/setup_layout.sh
cp app/index.html /opt/shopease/app/index.html
bash scripts/gen_log.sh > /opt/shopease/logs/access.log
```

**3. Create the team and lock down the folders**

```bash
./scripts/users_setup.sh
sudo passwd devops1          # devops1 needs a password to use sudo
```

**4. Serve the site with Nginx**

```bash
sudo cp nginx/shopease.conf /etc/nginx/sites-available/shopease
sudo ln -s /etc/nginx/sites-available/shopease /etc/nginx/sites-enabled/shopease
sudo rm -f /etc/nginx/sites-enabled/default
sudo usermod -aG shopease www-data     # Nginx must be able to enter /opt/shopease
sudo nginx -t && sudo systemctl restart nginx
curl -I http://localhost               # expect: HTTP/1.1 200 OK
```

**5. Install the Telegram monitor**

```bash
sudo cp scripts/resource-alert.sh /opt/shopease/scripts/
sudo cp scripts/.telegram.env.example /opt/shopease/scripts/.telegram.env
sudo chown devops1:devops1 /opt/shopease/scripts/resource-alert.sh /opt/shopease/scripts/.telegram.env
sudo chmod 700 /opt/shopease/scripts/resource-alert.sh
sudo chmod 600 /opt/shopease/scripts/.telegram.env
sudo -u devops1 nano /opt/shopease/scripts/.telegram.env    # put in your real token and chat ID
sudo -u devops1 /opt/shopease/scripts/resource-alert.sh     # expect: Telegram notification sent successfully
```

**6. Schedule it every 15 minutes (systemd timer)**

```bash
sudo cp systemd/shopease-monitor.service systemd/shopease-monitor.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now shopease-monitor.timer
systemctl list-timers shopease-monitor.timer
```

Prefer cron? Use the line in `cron/resource-alert.cron` with `crontab -e` as devops1 instead,
but never both, or every report arrives twice.

## Daily Git workflow

```bash
git status                     # what changed?
git add <file>                 # choose what to save
git commit -m "Fix wrong port in health check"
git push                       # send it to GitHub
```

## Security notes

- The Telegram token lives only in `/opt/shopease/scripts/.telegram.env` on the server,
  owned by devops1 with permissions `600`.
- If a secret is ever pushed by mistake, deleting the file is not enough: it stays in the
  Git history. Revoke it (BotFather `/revoke`) and create a new one.
