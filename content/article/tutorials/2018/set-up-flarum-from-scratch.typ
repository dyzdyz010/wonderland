#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "Set Up Flarum From Scratch",
  desc: [Set up Flarum forum from scratch on a Linux VPS],
  date: "2018-01-06",
  tags: (
    blog-tags.linux,
    blog-tags.software,
  ),
)

#link("https://flarum.org/docs/install.html")[Before you continue]

= 1. Get a VPS from Linode/Vultr/whatever

// External images from sinaimg.cn are no longer available.

= 2. Pick a linux distribution and make it running(I use CentOS 7).

// External image from sinaimg.cn is no longer available.

= 3. Install Apache/MySQL/PHP 7.1

== Get yourself a non-root sudo user

```bash
adduser USERNAME
passwd USERNAME
usermod -aG wheel USERNAME
su USERNAME
```

== Install and configure Apache

#link("https://www.digitalocean.com/community/tutorials/how-to-set-up-apache-virtual-hosts-on-centos-7")[Check this out]

First install it.

```bash
sudo yum update
sudo yum -y install httpd
sudo systemctl enable httpd.service
```

Then create directory structure.

```bash
sudo mkdir /etc/httpd/sites-available
sudo mkdir /etc/httpd/sites-enabled
```

Open config file:

```bash
sudo vim /etc/httpd/conf/httpd.conf
```

Add this to the end of the file:

```conf
IncludeOptional sites-enabled/*.conf
```

== Install MySQL

CentOS 7 by default uses `MariaDB` rather than MySQL, but there's no difference using it.

*Note:* yum installs MariaDB 5.5 by default, which no longer satisfies flarum's requirements. #link("https://mariadb.com/resources/blog/installing-mariadb-10-on-centos-7-rhel-7/")[See here] for instructions on installing MariaDB 10.

```bash
sudo mysql_secure_installation
```

Then create a `user` and a `database` in `MySQL` for flarum.

== Install and configure PHP

I'm using php 7.1 here.

#link("https://webtatic.com/packages/php70/")[Take a look at this]

First add needed yum repo:

```bash
sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
```

Install php

```bash
sudo yum install mod_php71w php71w-cli php71w-xml php71w-mbstring php71w-mysql php71w-gd
```

= 4. Install Flarum

== Create site directory

Name your site directory whatever you like, I'll just stick with `flarum`.

```bash
sudo mkdir /var/www/flarum
```

== Install composer

```bash
cd /tmp
sudo curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
```

== Fetch flarum content

```bash
cd /var/www
sudo yum install unzip
sudo chown USERNAME:GROUPNAME flarum
cd flarum
composer create-project flarum/flarum . --stability=beta
```

== Adjust ownership and permissions

Change directory's ower to `apache` for apache to operate:

```bash
cd ..
sudo chown -R apache:apache flarum
```

= 5. Make it up and running

== Create virtual host in apache for flarum

Name configuration file whatever you like:

```bash
cd /etc/httpd/sites-available
sudo vim flarum.conf
```

Fill in content below(*Don't forget the url rewrite block!*):

```conf
<VirtualHost *:80>
    ServerName YOURDOMAIN
    ServerAlias ALIAS
    DocumentRoot /var/www/flarum/public
    ErrorLog /var/www/flarum/storage/logs/error.log
    CustomLog /var/www/flarum/storage/logs/requests.log combined

    <Directory "/var/www/flarum/public">
        DirectoryIndex index.php
        AllowOverride All
        allow from all
    </Directory>
</VirtualHost>
```

Make your config go live

```bash
sudo ln -s /etc/httpd/sites-available/flarum.conf /etc/httpd/sites-enabled/flarum.conf
```

== Configure firewalld and restart Apache server

```bash
sudo firewall-cmd --add-service=http --permanent && sudo firewall-cmd --add-service=https --permanent
sudo systemctl restart firewalld
sudo apachectl restart
```

= 6. Visit your flarum site and enjoy!

== Note: Wrote this down based on my memory, if there are any missing pieces, post a comment below
