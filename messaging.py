import os
import smtplib
import yaml
from email.mime.image import MIMEImage
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from pathlib import Path
import shutil

# Configuration from environment variables
SENDER_EMAIL = os.getenv("EMAIL_SENDER")
SMTP_SERVER = os.getenv("SMTP_SERVER")
SMTP_PORT = int(os.getenv("SMTP_PORT"))

# Path settings
OUTPUTS_DIR = os.getenv("OUTPUTS")
SENT_DIR = Path(OUTPUTS_DIR) / "sent"

def send_email(receiver_email, subject, body_html):
    logo_path = "/srv/shiny-server/yaml_files/codes/src/logo.png"

    msg = MIMEMultipart("related")  # 'related' lets you include inline images
    msg["From"] = SENDER_EMAIL
    msg["To"] = receiver_email
    msg["Subject"] = subject

    # Alternative for HTML body
    msg_alt = MIMEMultipart("alternative")
    msg.attach(msg_alt)

    # Insert image reference into HTML
    img_tag = '<img src="cid:logo_image" alt="OmegaSync Logo" style="max-width:200px; margin-top:20px;">'
    body_html = body_html.replace("<!-- INSERT LOGO HERE -->", img_tag)
    msg_alt.attach(MIMEText(body_html, "html"))

    # Attach logo image (inline)
    if os.path.exists(logo_path):
        with open(logo_path, "rb") as img_file:
            img = MIMEImage(img_file.read())
            img.add_header("Content-ID", "<logo_image>")  # must match `cid:` in HTML
            img.add_header("Content-Disposition", "inline", filename="omegasync_logo.png")
            msg.attach(img)
    else:
        print(f"Warning: logo not found at {logo_path}, skipping image.")

    try:
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SENDER_EMAIL, SENDER_PASSWORD)
            server.sendmail(SENDER_EMAIL, receiver_email, msg.as_string())
            print(f"Email sent to {receiver_email} with subject: {subject}")
    except Exception as e:
        print(f"Failed to send email to {receiver_email}: {e}")

def main():
    SENT_DIR.mkdir(exist_ok=True)

    entries = [e for e in Path(OUTPUTS_DIR).iterdir() if e.is_dir() and e.name != "sent"]
    if not entries:
        print("No new files — exiting script.")
        exit(0)

    for entry in entries:
        message_yaml = entry / "message.yaml"

        if not message_yaml.exists():
            print(f"No message.yaml in {entry}, skipping.")
            continue

        with open(message_yaml, "r") as f:
            message_data = yaml.safe_load(f)

        subject = message_data.get("subject", "").strip()
        receiver_email = message_data.get("email", "").strip()
        body_file = entry / message_data.get("body", "").strip()

        if not subject or not receiver_email or not body_file.exists():
            print(f"Incomplete info in {entry}, skipping.")
            continue

        with open(body_file, "r") as f:
            body_html = f.read()

        send_email(receiver_email, subject, body_html)

        shutil.move(str(entry), SENT_DIR / entry.name)

if __name__ == "__main__":
    main()
