import os
import smtplib
import yaml
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from pathlib import Path
import shutil

# Configuration from environment variables
SENDER_EMAIL = os.getenv("EMAIL_SENDER")
SENDER_PASSWORD = os.getenv("EMAIL_PASSWORD").strip('"')
SMTP_SERVER = os.getenv("SMTP_SERVER")
SMTP_PORT = int(os.getenv("SMTP_PORT"))


# Path settings
OUTPUTS_DIR = os.getenv("OUTPUTS")
SENT_DIR = Path(OUTPUTS_DIR) / "sent"

def send_email(receiver_email, subject, body_html):
    msg = MIMEMultipart("alternative")
    msg["From"] = SENDER_EMAIL
    msg["To"] = receiver_email
    msg["Subject"] = subject

    msg.attach(MIMEText(body_html, "html"))

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
    
    for entry in Path(OUTPUTS_DIR).iterdir():
        if entry.name == "sent" or not entry.is_dir():
            continue

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
