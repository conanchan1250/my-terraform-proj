#!/bin/bash
yum update -y
amazon-linux-extras install -y php7.4 
yum install -y httpd
systemctl start httpd
systemctl enable httpd
cd /var/www/html
wget https://wordpress.org/latest.tar.gz 
tar -xzf latest.tar.gz
cp -r wordpress/* ./
rm -rf latest.tar.gz
rm -rf wordpress 
chmod -R 755 wp-content
chown -R apache:apache wp-content
