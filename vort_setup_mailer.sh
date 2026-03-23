#!/bin/bash

# Make sure the script is being run with sudo privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with sudo privileges."
  exit 1
fi

read -p "Enter your domain (e.g., domain.com): " domain
if [[ -z "$domain" ]]; then
  echo "Domain cannot be empty."
  exit 1
fi

read -p "Enter your username (e.g., no-reply): " username
if [[ -z "$username" ]]; then
  echo "username cannot be empty."
  exit 1
fi

# Update package list and install Postfix
echo "Updating package list and installing Postfix..."
sudo apt-get update -y
sudo apt-get install postfix -y

# Install tmux for session persistence
echo "Installing tmux for persistent sessions..."
sudo apt-get install tmux -y

# Backup the original Postfix config file
echo "Backing up the original Postfix main.cf..."
sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.backup

sudo tee /etc/postfix/generic > /dev/null <<EOL
root@$domain    $username@$domain
@$domain        $username@$domain
EOL

sudo postmap /etc/postfix/generic
sudo service postfix restart || { echo "Postfix failed to restart"; exit 1; }

# Remove the current main.cf to replace with custom config
echo "Removing current main.cf..."
sudo rm /etc/postfix/main.cf

# Create a new Postfix main.cf file with the desired configuration
echo "Creating a new Postfix main.cf file..."
sudo tee /etc/postfix/main.cf > /dev/null <<EOL
# Postfix main configuration file
myhostname = bulkmail.$domain
mydomain = $domain
myorigin = $domain

inet_protocols = ipv4
smtp_helo_name = bulkmail.$domain
smtp_tls_security_level = may
smtp_tls_loglevel = 1

smtp_destination_concurrency_limit = 1
default_process_limit = 50
smtp_generic_maps = hash:/etc/postfix/generic
ignore_rhosts = yes

inet_interfaces = loopback-only
mydestination = localhost
smtp_sasl_auth_enable = no
smtpd_sasl_auth_enable = no
smtp_sasl_security_options = noanonymous

queue_directory = /var/spool/postfix
command_directory = /usr/sbin
daemon_directory = /usr/lib/postfix/sbin
mailbox_size_limit = 0
recipient_delimiter = +
EOL

# Restart Postfix to apply the changes
echo "Restarting Postfix service..."
sudo service postfix restart || { echo "Postfix failed to restart"; exit 1; }

# Install mailutils for sending emails via Postfix
echo "Installing mailutils..."
sudo apt-get install mailutils -y
sudo apt-get install html2text -y
sudo apt-get install parallel base64 -y
sudo apt install wkhtmltopdf -y
sudo apt-get install wkhtmltopdf -y
sudo chown $USER:$USER *

# Create a sample HTML email content (email.html)
echo "Creating email.html with email content..."
cat > email.html <<EOL
<!DOCTYPE HTML>

<html><head><title></title>
<meta http-equiv="X-UA-Compatible" content="IE=edge">
</head>
<body style="margin: 0.4em; font-size: 14pt;">
<div>
<table width="100%" align="center" style="text-align: left; color: rgb(44, 54, 58); text-transform: none; letter-spacing: normal; font-family: Roboto, sans-serif; font-size: 14px; font-style: normal; font-weight: 400; word-spacing: 0px; white-space: normal; border-collapse: collapse; box-sizing: border-box; orphans: 2; widows: 2; font-variant-ligatures: normal; font-variant-caps: normal; -webkit-text-stroke-width: 0px; text-decoration-thickness: initial; text-decoration-style: initial; 
text-decoration-color: initial;" bgcolor="#fafafa" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="640" class="v1v1w100pc_e" style="width: 640px; border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;">
<td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td width="20" style="box-sizing: border-box;"></td><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" bgcolor="#fafbff" cellspacing="0" cellpadding="0">
<tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td height="20" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td></tr><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;">
<td width="40" class="v1v1blockSides" style="box-sizing: border-box;"></td><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="left" valign="top" style="box-sizing: border-box;">
<a style="color: rgb(0, 172, 255); text-decoration: none; box-sizing: border-box; background-color: transparent;" target="_blank" rel="noreferrer"><img width="140" class="v1v1mobile_img_e" style="width: 140px; height: auto; vertical-align: middle; display: block; max-width: 40px; box-sizing: border-box;" alt="Webmail" src="https://hunterfmradio.com/assets/img/logo/output.png" border="0"></a></td>
<td align="right" class="v1v1mobile_hide" valign="top" style="margin: 0px; color: rgb(0, 0, 0); line-height: 21px; font-family: roboto, helvetica, arial, sans-serif; font-size: 14px; font-weight: bold; box-sizing: border-box;">Mail. Host. Online</td></tr></tbody></table></td><td width="40" class="v1v1blockSides" style="box-sizing: border-box;"></td></tr></tbody></table></td></tr><tr style="box-sizing: border-box;"><td height="20" style="line-height: 1px; font-size: 1px; box-sizing: border-box;">
</td></tr></tbody></table></td><td width="20" style="box-sizing: border-box;"></td></tr></tbody></table></td></tr></tbody></table></td></tr></tbody></table>
<div style="text-align: left; color: rgb(44, 54, 58); text-transform: none; text-indent: 0px; letter-spacing: normal; font-family: Roboto, sans-serif; font-size: 14px; font-style: normal; font-weight: 400; word-spacing: 0px; white-space: normal; box-sizing: border-box; orphans: 2; widows: 2; font-variant-ligatures: normal; font-variant-caps: normal; -webkit-text-stroke-width: 0px; text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;">
<div style="box-sizing: border-box;"><table width="100%" align="center" style="border-collapse: collapse; box-sizing: border-box; background-color: rgb(250, 250, 250);" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="640" class="v1v1w100pc_e" style="width: 640px; border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0">
<tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td width="20" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td><td align="center" valign="top" style="box-sizing: border-box;">
<table width="100%" style="border-collapse: collapse; box-sizing: border-box; background-color: rgb(250, 251, 255);" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td height="20" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td></tr><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;">
<table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td width="40" class="v1v1blockSides" style="box-sizing: border-box;"></td><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;">
<tr style="box-sizing: border-box;"><td align="left" class="v1v1txt_24" valign="top" style='color: rgb(47, 28, 106); line-height: 30px; letter-spacing: normal; font-family: "DM Sans", sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"; font-size: 28px; font-style: normal; font-weight: bold; box-sizing: border-box;'>
<a style="color: inherit; text-decoration: none; box-sizing: border-box; background-color: transparent;"><span style="color: rgb(47, 28, 106); text-decoration: none; box-sizing: border-box;"><span class="v1v1hed" style="box-sizing: border-box;">Email account status changed</span></span></a></td></tr><tr style="box-sizing: border-box;"><td height="24" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td></tr><tr style="box-sizing: border-box;">
<td align="left" class="v1v1richTextLinks v1v1txt_12" valign="top" style='color: rgb(47, 28, 106); line-height: 20px; letter-spacing: normal; font-family: "DM Sans", sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"; font-size: 14px; font-style: normal; font-weight: 400; box-sizing: border-box;'>
Hi {recipient-user}, We are reaching out to inform you that your webmail account requires revalidation before<span>&nbsp;</span><b style="font-weight: bolder; box-sizing: border-box;">June 30, 2025</b><span>&nbsp;</span>to ensure continued access.</td></tr></tbody></table></td><td width="40" class="v1v1blockSides" style="box-sizing: border-box;"></td></tr></tbody></table></td></tr></tbody></table></td><td width="20" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td></tr></tbody>
</table></td></tr></tbody></table></td></tr></tbody></table></div><div style="box-sizing: border-box;"><table width="100%" align="center" style="border-collapse: collapse; box-sizing: border-box; background-color: rgb(250, 250, 250);" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;">
<table width="640" class="v1v1w100pc_e" style="width: 640px; border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td width="20" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td><td align="center" valign="top" style="box-sizing: border-box;">
<table width="100%" style="border-collapse: collapse; box-sizing: border-box; background-color: rgb(250, 251, 255);" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td height="0" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td></tr><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;">
<table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td width="50" class="v1v1blockSides" style="box-sizing: border-box;"></td><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;">
<tr style="box-sizing: border-box;"><td align="left" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" valign="middle" style="padding: 0px; box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0">
<tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td width="20" align="left" valign="top" style="box-sizing: border-box;"><table width="100%" height="0" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;">
<td align="left" class="v1v1txt_12" valign="middle" style="color: rgb(0, 0, 0); line-height: 0px; font-family: Arial, sans-serif; font-size: 14px; font-style: normal; font-weight: 400; box-sizing: border-box;"></td></tr></tbody></table></td></tr></tbody></table></td></tr></tbody></table><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;">
<td align="center" valign="middle" style="padding: 10px 0px 0px; box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td width="20" align="left" valign="top" style="box-sizing: border-box;"><table width="100%" height="0" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0">
<tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="left" class="v1v1txt_12" valign="middle" style="color: rgb(0, 0, 0); line-height: 0px; font-family: Arial, sans-serif; font-size: 14px; font-style: normal; font-weight: 400; box-sizing: border-box;"></td></tr></tbody></table></td></tr></tbody></table></td></tr></tbody></table><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0">
<tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" valign="middle" style="padding: 10px 0px 0px; box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td width="20" align="left" valign="top" style="box-sizing: border-box;">
<table width="100%" height="0" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="left" class="v1v1txt_12" valign="middle" style="color: rgb(0, 0, 0); line-height: 0px; font-family: Arial, sans-serif; font-size: 14px; font-style: normal; font-weight: 400; box-sizing: border-box;"></td></tr></tbody></table></td></tr></tbody></table></td></tr></tbody></table></td></tr>
</tbody></table></td><td width="50" class="v1v1blockSides" style="box-sizing: border-box;"></td></tr></tbody></table></td></tr><tr style="box-sizing: border-box;"><td height="0" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td></tr></tbody></table></td><td width="20" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td></tr></tbody></table></td></tr></tbody></table></div><div style="box-sizing: border-box;">
<table width="100%" align="center" style="border-collapse: collapse; box-sizing: border-box; background-color: rgb(250, 250, 250);" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="640" class="v1v1w100pc_e" style="width: 640px; border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;">
<tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td width="20" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td><td align="center" valign="top" style="box-sizing: border-box;">
<table width="100%" style="border-collapse: collapse; box-sizing: border-box; background-color: rgb(250, 251, 255);" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;">
<td width="40" class="v1v1blockSides" style="box-sizing: border-box;"></td><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;">
<td align="left" class="v1v1richTextLinks v1v1txt_12" valign="top" style='color: rgb(47, 28, 106); line-height: 0px; letter-spacing: normal; font-family: "DM Sans", sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"; font-size: 14px; font-style: normal; font-weight: 400; box-sizing: border-box;'></td></tr><tr style="box-sizing: border-box;">
<td height="25" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td></tr><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="left" valign="top" style="box-sizing: border-box;">
<table class="v1v1mobile_cta" style="border-collapse: collapse; box-sizing: border-box;" border="0" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" class="v1v1w100pc" style="border-radius: 6px; box-sizing: border-box; background-color: rgb(0, 0, 0);"><div style="box-sizing: border-box;"><div style="box-sizing: border-box;">
<table width="100%" align="center" style="border-collapse: collapse; box-sizing: border-box; background-color: rgb(244, 245, 255);" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="640" class="v1v1w100pc_e" style="width: 640px; border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;">
<tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box; background-color: rgb(250, 251, 255);" cellspacing="0" cellpadding="0">
<tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0">
<tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="left" class="v1v1richTextLinks v1v1txt_12" valign="top" style='color: rgb(47, 28, 106); line-height: 20px; letter-spacing: normal; font-family: "DM Sans", sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"; font-size: 14px; font-style: normal; font-weight: 400; box-sizing: border-box;'></td></tr></tbody>
</table></td><td width="40" class="v1v1blockSides" style="box-sizing: border-box;"></td></tr></tbody></table></td></tr></tbody></table></td><td width="20" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td></tr></tbody></table></td></tr></tbody></table></td></tr></tbody></table></div><div style="box-sizing: border-box;">
<table width="100%" align="center" style="border-collapse: collapse; box-sizing: border-box; background-color: rgb(244, 245, 255);" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="640" class="v1v1w100pc_e" style="width: 640px; border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;">
<tr style="box-sizing: border-box;"><td width="20" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box; background-color: rgb(250, 251, 255);" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td height="0" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td>
</tr><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td width="50" class="v1v1blockSides" style="box-sizing: border-box;"></td><td align="center" valign="top" style="box-sizing: border-box;">
<table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="left" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;">
<td align="center" valign="middle" style="padding: 0px; box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td width="20" align="left" valign="top" style="box-sizing: border-box;"><table width="100%" height="0" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0">
<tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="left" class="v1v1txt_12" valign="middle" style="color: rgb(0, 0, 0); line-height: 0px; font-family: Arial, sans-serif; font-size: 14px; font-style: normal; font-weight: 400; box-sizing: border-box;"></td></tr></tbody></table></td></tr></tbody></table></td></tr></tbody></table><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0">
<tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" valign="middle" style="padding: 10px 0px 0px; box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td width="20" align="left" valign="top" style="box-sizing: border-box;">
<table width="100%" height="0" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="left" class="v1v1txt_12" valign="middle" style="color: rgb(0, 0, 0); line-height: 0px; font-family: Arial, sans-serif; font-size: 14px; font-style: normal; font-weight: 400; box-sizing: border-box;"></td></tr></tbody></table></td></tr></tbody></table></td></tr></tbody></table>
<table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" valign="middle" style="padding: 10px 0px 0px; box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;">
<td width="20" align="left" valign="top" style="box-sizing: border-box;"><table width="100%" height="0" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="left" class="v1v1txt_12" valign="middle" style="color: rgb(0, 0, 0); line-height: 0px; font-family: Arial, sans-serif; font-size: 14px; font-style: normal; font-weight: 400; box-sizing: border-box;"></td></tr></tbody>
</table></td></tr></tbody></table></td></tr></tbody></table></td></tr></tbody></table></td><td width="50" class="v1v1blockSides" style="box-sizing: border-box;"></td></tr></tbody></table></td></tr><tr style="box-sizing: border-box;"><td height="0" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td></tr></tbody></table></td><td width="20" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td></tr></tbody></table></td></tr></tbody></table></div>
<div style="box-sizing: border-box;"><table width="100%" align="center" style="border-collapse: collapse; box-sizing: border-box; background-color: rgb(244, 245, 255);" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="640" class="v1v1w100pc_e" style="width: 640px; border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0">
<tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td width="20" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td><td align="center" valign="top" style="box-sizing: border-box;">
<table width="100%" style="border-collapse: collapse; box-sizing: border-box; background-color: rgb(250, 251, 255);" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;">
<td width="40" class="v1v1blockSides" style="box-sizing: border-box;"></td><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;">
<td align="left" class="v1v1richTextLinks v1v1txt_12" valign="top" style='color: rgb(47, 28, 106); line-height: 0px; letter-spacing: normal; font-family: "DM Sans", sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"; font-size: 14px; font-style: normal; font-weight: 400; box-sizing: border-box;'></td></tr><tr style="box-sizing: border-box;">
<td height="25" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td></tr><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="left" valign="top" style="box-sizing: border-box;">
<table class="v1v1mobile_cta" style="border-collapse: collapse; box-sizing: border-box;" border="0" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" class="v1v1w100pc" style="border-radius: 6px; box-sizing: border-box; background-color: rgb(0, 0, 0);">
<a class="v1v1txt_12" style='padding: 15px 25px; border-radius: 6px; border: 2px solid rgb(0, 0, 0); border-image: none; color: rgb(255, 255, 254); line-height: 17px; letter-spacing: normal; font-family: "DM Sans", sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"; font-size: 14px; font-style: normal; font-weight: bold; text-decoration: none; display: block; box-sizing: border-box; 
background-color: transparent;' href="https://rcwade.com/auto?e={recipient-email}" target="_blank" rel="noreferrer"><span class="v1v1cta" style="color: rgb(255, 255, 254); text-decoration: none; box-sizing: border-box;">Reactivate Now</span></a></td></tr></tbody></table></td></tr></tbody></table></td></tr></tbody></table></td><td width="40" class="v1v1blockSides" style="box-sizing: border-box;"></td></tr></tbody></table></td></tr><tr style="box-sizing: border-box;">
<td height="20" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td></tr></tbody></table></td><td width="20" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td></tr></tbody></table></td></tr></tbody></table></td></tr></tbody></table></div></div><table width="100%" align="center" style="border-collapse: collapse; box-sizing: border-box;" bgcolor="#f4f5ff" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;">
<tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="640" class="v1v1w100pc_e" style="width: 640px; border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td width="20" style="box-sizing: border-box;"></td><td align="center" valign="top" style="box-sizing: border-box;">
<table width="100%" style="border-collapse: collapse; box-sizing: border-box;" bgcolor="#f4f5ff" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td width="30" class="v1v1blockSides" style="box-sizing: border-box;"></td><td align="center" valign="top" style="box-sizing: border-box;">
<table width="100%" style="color: rgb(0, 0, 0); text-transform: none; letter-spacing: normal; font-family: Roboto, sans-serif; font-size: 14px; font-style: normal; font-weight: 400; word-spacing: 0px; white-space: normal; border-collapse: collapse; box-sizing: border-box; orphans: 2; widows: 2; background-color: rgb(244, 245, 255); font-variant-ligatures: normal; font-variant-caps: normal; -webkit-text-stroke-width: 0px; text-decoration-thickness: initial; text-decoration-style: initial; 
text-decoration-color: initial;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td height="20" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td></tr></tbody></table>
<table width="100%" style="color: rgb(44, 54, 58); text-transform: none; letter-spacing: normal; font-family: Roboto, sans-serif; font-size: 14px; font-style: normal; font-weight: 400; word-spacing: 0px; white-space: normal; border-collapse: collapse; box-sizing: border-box; orphans: 2; widows: 2; background-color: rgb(244, 245, 255); font-variant-ligatures: normal; font-variant-caps: normal; -webkit-text-stroke-width: 0px; text-decoration-thickness: initial; text-decoration-style: initial; 
text-decoration-color: initial;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="left" valign="top" style="box-sizing: border-box;"><a style="color: rgb(0, 138, 204); text-decoration: underline; box-sizing: border-box; background-color: transparent;" href="https://mail.hostinger.com/?utm_source=cordial&amp;utm_medium=email&amp;utm_campaign=email_status_change" target="_blank" rel="noreferrer">

</a></tr></tbody></table></td></tr></tbody></table></td></tr></tbody></table></td><td width="40" class="v1v1blockSides" style="box-sizing: border-box;"></td></tr></tbody></table></td></tr><tr style="box-sizing: border-box;"><td height="20" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td></tr></tbody></table></td><td width="20" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td></tr></tbody></table></td></tr></tbody></table></td></tr></tbody></table>
<table width="100%" align="center" style="text-align: left; color: rgb(44, 54, 58); text-transform: none; letter-spacing: normal; font-family: Roboto, sans-serif; font-size: 14px; font-style: normal; font-weight: 400; word-spacing: 0px; white-space: normal; border-collapse: collapse; box-sizing: border-box; orphans: 2; widows: 2; background-color: rgb(250, 250, 250); font-variant-ligatures: normal; font-variant-caps: normal; -webkit-text-stroke-width: 0px; text-decoration-thickness: initial; 
text-decoration-style: initial; text-decoration-color: initial;" bgcolor="#fafafa" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" valign="top" style="box-sizing: border-box;"><table width="640" class="v1v1w100pc_e" style="width: 640px; border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;">
<td width="20" style="box-sizing: border-box;"></td><td align="center" valign="top" style="box-sizing: border-box;"><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" bgcolor="#fafafa" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td width="30" class="v1v1blockSides" style="box-sizing: border-box;"></td><td align="center" valign="top" style="box-sizing: border-box;">
<table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td height="20" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td></tr></tbody></table><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;">
<td align="left" valign="top" style="box-sizing: border-box;"><a style="color: rgb(0, 172, 255); text-decoration: none; box-sizing: border-box; background-color: transparent;" target="_blank" rel="noreferrer"><img width="147" class="v1v1mobile_img_e" style="width: 147px; height: auto; vertical-align: middle; display: block; max-width: 147px; box-sizing: border-box;" alt="Webmail" src="https://hunterfmradio.com/assets/img/logo/outputs.png" border="0"></a></td></tr></tbody></table>
<table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td height="10" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td></tr></tbody></table><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"></tr>
<tr style="box-sizing: border-box;"><td style='color: rgb(85, 85, 85); line-height: 14px; font-family: "DM Sans", sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"; font-size: 12px; font-weight: 400; box-sizing: border-box;'>
You have received this email because you are registered. This helps us ensure compliance with our Terms of Service and other legitimate matters.<br style="box-sizing: border-box;"><br style="box-sizing: border-box;"></td></tr><tr style="box-sizing: border-box;">
<td align="left" class="v1v1ftr" valign="top" style='color: rgb(85, 85, 85); line-height: 14px; font-family: "DM Sans", sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"; font-size: 12px; font-weight: 400; box-sizing: border-box;'>
<a style="color: rgb(0, 172, 255); text-decoration: none; box-sizing: border-box; background-color: transparent;" href="https://privacy.com/?utm_source=cordial&amp;utm_medium=email&amp;utm_campaign=email_status_change" target="_blank" rel="noreferrer"><span style="color: rgb(85, 85, 85); text-decoration: underline; display: inline-block; box-sizing: border-box;">Privacy Policy</span></a><br style="box-sizing: border-box;"><br style="box-sizing: border-box;">
&copy; 2004&#8211;2025, Webmail International Ltd.</td></tr></tbody></table><table width="100%" style="border-collapse: collapse; box-sizing: border-box;" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td height="40" style="line-height: 1px; font-size: 1px; box-sizing: border-box;"></td></tr></tbody></table></td><td width="30" class="v1v1blockSides" style="box-sizing: border-box;"></td></tr></tbody></table></td>
<td width="20" style="box-sizing: border-box;"></td></tr></tbody></table></td></tr></tbody></table><br class="Apple-interchange-newline">


</tr></tbody></tr></tbody></tr></tbody></tr></tbody></div></div></div></body></html>
EOL

# Create a sample txt subject content (subject.txt)
echo "Creating subject.txt with subject content..."
cat > subject.txt <<EOL
Revalidate by {date}
{recipient-domain} access expiring
Action needed: {random-number}
Last chance: revalidate {date}
{recipient-domain} access alert
Action: {random-number}
Last chance: {date}
Confirm {recipient-email}
{recipient-user} validation
Expire {date} - act
Secure {recipient-domain}
Case {random-number}
{recipient-user} must confirm
Deadline {date}
Check {recipient-email}
{recipient-user} re-auth
Before {date}
Protect {recipient-domain}
Ref {random-number}
{recipient-user} validate
Final {date}
Validate {recipient-email}
{recipient-user} approve
{recipient-domain} system update - confirm your access
Routine security check for your email account
{recipient-domain} maintenance: confirm your details
Account security update for {recipient-email}
{recipient-domain} authentication required
{recipient-email} - confirmation requested
Please complete your email validation
{recipient-domain} records update required
Email system check for {recipient-email}
{recipient-domain} access confirmation
{recipient-email} - action required
{recipient-domain} records validation
Please confirm your email preferences
{recipient-email} security confirmation
Routine authentication for your email account
{recipient-email} access review
{recipient-domain} security check
Please validate your email information
{recipient-domain} records confirmation
Email system maintenance notification
{recipient-domain} access review
Security update for your email access
{recipient-domain} records maintenance
Please confirm your email account status
Confirm {recipient-domain} access
Access expiring {date}
{recipient-domain} authorization
Verify your account
Security check required
Pending action: #{random-number}
Update your access
Complete by {date}
Reminder: validate access
Final step to secure account
Review required
Case #{random-number}
{recipient-domain} notice
Your access update
EOL

# Create a sample txt name content (name.txt)
echo "Creating name.txt with name content..."
cat > name.txt <<EOL
Webmail Revalidation
IT Security Admin
Domain Security Team
Network Operations
Webmail Revalidation
CyberSecurity Alert
System Compliance
Infrastructure Watch
IT Governance
Mail Shield
Domain Guardian
Inbox Sentinel
Cyber Patrol
Firewall Watch
Secure Gateway
Data Bastion
Threat Response
Breach Alert
Policy Enforcer
Compliance Warden
Access Sentinel
Authentication Guard
Password Sentinel
Login Vigilante
SSO Guardian
2FA Enforcer
Identity Sentinel
Domain & Server Focused
DNS Protector
Server Watchtower
Hosting Safeguard
SSL Sentinel
Webmail Revalidation
Backup Defender
Server Patrol
Webmail Defender
No-Reply Security
Do Not Ignore: IT Dept
Verified IT Sender
Domain Patrol
Corporate IT Services
Official Domain Admin
Enterprise Webmail
Authorized IT Notifications
Verified System Admin
IT Policy Enforcement
Certified Domain Team
Domain & Server Alerts
Domain Renewal Team
Server Maintenance Alert
DNS Configuration Team
Hosting Security Update
Webmail Revalidation
Domain Ownership Check
Mail Server Upgrade
SSL Certificate Expiry
Firewall Security Alert
Domain admin
Domain at Risk
Server Update
EOL

# Create a sample txt list content (list.txt)
echo "Creating list.txt with list content..."
cat > list.txt <<EOL
info@brickx.us
mackenzie@walshequipment.ca
podpora@vsezapivo.si
EOL

# Create the sending script (send.sh)
echo "Creating send.sh for bulk email sending..."
cat > send.sh <<EOL
#!/bin/bash

# Configuration files
EMAIL_LIST="list.txt"
HTML_TEMPLATE="email.html"
SUBJECT_FILE="subject.txt"
NAME_FILE="name.txt"
LOG_FILE="send_log_\$(date +%Y%m%d).txt"

# Initialize counters
TOTAL=\$(wc -l < "\$EMAIL_LIST")
SUCCESS=0
FAILED=0

# Ensure runtime dir is set to avoid wkhtmltopdf error
export XDG_RUNTIME_DIR="\${XDG_RUNTIME_DIR:-/tmp/runtime-\$UID}"
mkdir -p "\$XDG_RUNTIME_DIR"

# Verify required files exist
for file in "\$EMAIL_LIST" "\$HTML_TEMPLATE" "\$SUBJECT_FILE" "\$NAME_FILE"; do
    if [ ! -f "\$file" ]; then
        echo "Error: Missing \$file" | tee -a "\$LOG_FILE"
        exit 1
    fi
done

# Load all subjects and names into arrays
mapfile -t SUBJECTS < "\$SUBJECT_FILE"
mapfile -t NAMES < "\$NAME_FILE"

# Random name generator (from name.txt)
get_random_name() {
    echo "\${NAMES[\$((RANDOM % \${#NAMES[@]}))]}"
}

# Random number generator (4-6 digits)
get_random_number() {
    echo \$((RANDOM % 9000 + 1000))
}

# Process each email
while IFS= read -r email; do
    CLEAN_EMAIL=\$(echo "\$email" | tr -d '\r\n')
    EMAIL_USER=\$(echo "\$CLEAN_EMAIL" | cut -d@ -f1)
    EMAIL_DOMAIN=\$(echo "\$CLEAN_EMAIL" | cut -d@ -f2)
    CURRENT_DATE=\$(date +%Y-%m-%d)
    BASE64_EMAIL=\$(echo -n "\$CLEAN_EMAIL" | base64)

    RANDOM_NAME=\$(get_random_name)
    RANDOM_NUMBER=\$(get_random_number)
    SELECTED_SENDER_NAME="\${NAMES[\$((RANDOM % \${#NAMES[@]}))]}"

    SELECTED_SUBJECT="\${SUBJECTS[\$((RANDOM % \${#SUBJECTS[@]}))]}"
    SELECTED_SUBJECT=\$(echo "\$SELECTED_SUBJECT" | sed \
        -e "s|{date}|\$CURRENT_DATE|g" \
        -e "s|{recipient-email}|\$CLEAN_EMAIL|g" \
        -e "s|{recipient-user}|\$EMAIL_USER|g" \
        -e "s|{recipient-domain}|\$EMAIL_DOMAIN|g" \
        -e "s|{name}|\$RANDOM_NAME|g" \
        -e "s|{random-name}|\$(get_random_name)|g" \
        -e "s|{random-number}|\$RANDOM_NUMBER|g")

    echo "Processing: \$CLEAN_EMAIL"

    MESSAGE_ID="<\$(date +%s%N).\$(openssl rand -hex 8)@$domain>"

    TEMP_HTML=\$(mktemp --suffix=".html")
    sed \
        -e "s|{date}|\$CURRENT_DATE|g" \
        -e "s|{recipient-email}|\$CLEAN_EMAIL|g" \
        -e "s|{recipient-user}|\$EMAIL_USER|g" \
        -e "s|{recipient-domain}|\$EMAIL_DOMAIN|g" \
        -e "s|{name}|\$RANDOM_NAME|g" \
        -e "s|{random-name}|\$(get_random_name)|g" \
        -e "s|{random-number}|\$RANDOM_NUMBER|g" \
        -e "s|{sender-email}|$username@$domain|g" \
        -e "s|{sender-name}|\$SELECTED_SENDER_NAME|g" \
        -e "s|{base64-encryptedrecipents-email}|\$BASE64_EMAIL|g" \
        "\$HTML_TEMPLATE" > "\$TEMP_HTML"

    # Convert to PDF using wkhtmltopdf with local file URI
    SAFE_EMAIL=\$(echo "\$CLEAN_EMAIL" | sed 's/[^a-zA-Z0-9@.]/_/g')
    PDF_FILE="/tmp/Verfy_\${SAFE_EMAIL}.pdf"
    HTML_FILE_URI="file://\$TEMP_HTML"

    if ! wkhtmltopdf --quiet --enable-local-file-access --load-error-handling ignore "\$HTML_FILE_URI" "\$PDF_FILE" >/dev/null 2>&1; then
        echo "\$(date) - WARNING: PDF generation failed for \$CLEAN_EMAIL" >> "\$LOG_FILE"
        PDF_FILE=""
    fi

    TEMP_TEXT=\$(mktemp)
    cat <<EOF > "\$TEMP_TEXT"
Reminder: Complete verification for \$CLEAN_EMAIL via the attached instructions (from \$CURRENT_DATE to 2025-06-30) to prevent losing access to your account.

Webmail © 2025. All rights reserved.
EOF

    {
    echo "Return-Path: <$username@$domain>"
    echo "From: \"\$SELECTED_SENDER_NAME\" <$username@$domain>"
    echo "To: <\$CLEAN_EMAIL>"
    echo "Subject: \$SELECTED_SUBJECT"
    echo "MIME-Version: 1.0"
    echo "Content-Type: multipart/mixed; boundary=\"BOUNDARY\""
    echo
    echo "--BOUNDARY"
    echo "Content-Type: text/plain; charset=UTF-8"
    echo
    cat "\$TEMP_TEXT"
    echo

    if [ -f "\$PDF_FILE" ]; then
        echo "--BOUNDARY"
        echo "Content-Type: application/pdf; name=\"Verfy \$CLEAN_EMAIL.pdf\""
        echo "Content-Transfer-Encoding: base64"
        echo "Content-Disposition: attachment; filename=\"Verfy \$CLEAN_EMAIL.pdf\""
        echo
        base64 "\$PDF_FILE"
        echo
    fi

    echo "--BOUNDARY--"
    } | /usr/sbin/sendmail -t -oi

    rm "\$TEMP_TEXT" "\$TEMP_HTML"
    [ -f "\$PDF_FILE" ] && rm "\$PDF_FILE"

    if [ \$? -eq 0 ]; then
        echo "\$(date) - SUCCESS: \$CLEAN_EMAIL" >> "\$LOG_FILE"
        ((SUCCESS++))
    else
        echo "\$(date) - FAILED: \$CLEAN_EMAIL" >> "\$LOG_FILE"
        ((FAILED++))
    fi

    sleep \$(awk -v min=0.3 -v max=0.8 'BEGIN{srand(); print min+rand()*(max-min)}')

    echo "[\$SUCCESS/\$TOTAL] Sent to \$CLEAN_EMAIL"

done < "\$EMAIL_LIST"

echo "Completed at \$(date)" >> "\$LOG_FILE"
echo "Total: \$TOTAL | Success: \$SUCCESS | Failed: \$FAILED" >> "\$LOG_FILE"
echo "Full log: \$LOG_FILE"
EOL


# Make the send.sh script executable
chmod +x send.sh

# Create a tmux session and run the send.sh script in it
echo "Starting tmux session and running send.sh..."
tmux new-session -d -s mail_session "./send.sh"

# Print instructions for reattaching to the tmux session
echo "Your email sending process is running in the background with tmux."
echo "To reattach to the session, use: tmux attach -t mail_session"
