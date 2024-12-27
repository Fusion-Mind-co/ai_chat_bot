# email.py
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from ..config import Config
from flask import render_template

class EmailService:
    @staticmethod
    def send_email(to_email, subject, content, is_html=False):
        print('def send_email')
        # HTMLメールかプレーンテキストかを選択
        if is_html:
            msg = MIMEMultipart('alternative')
            msg.attach(MIMEText(content, 'html'))
        else:
            msg = MIMEText(content)
            
        msg['Subject'] = subject
        msg['From'] = Config.MAIL_USERNAME
        msg['To'] = to_email

        try:
            server = smtplib.SMTP(Config.MAIL_SERVER, Config.MAIL_PORT)
            server.starttls()
            server.login(Config.MAIL_USERNAME, Config.MAIL_PASSWORD)
            server.send_message(msg)
            server.quit()
            print(f"Email sent successfully to: {to_email}")
            return True
        except Exception as e:
            print(f"Failed to send email: {e}")
            return False

    @staticmethod
    def send_reset_password(to_email, reset_link):
        print('def send_reset_password')
        subject = "パスワードリセットリクエスト"
        content = f"パスワードリセットリンク: {reset_link}"
        return EmailService.send_email(to_email, subject, content, is_html=False)

    @staticmethod
    def send_unlock_notification(to_email, unlock_link):
        subject = "アカウントロック通知"
        content = f"アカウントがロックされました。解除するには次のリンクをクリックしてください: {unlock_link}"
        return EmailService.send_email(to_email, subject, content, is_html=False)
    
    @staticmethod
    def send_verification_email(to_email, username, verification_link):
        subject = "メールアドレス認証のお願い"
        content = f"""
    {username}様

    アカウント登録ありがとうございます。
    以下のリンクをクリックして、メールアドレスの認証を完了してください。

    {verification_link}

    このリンクの有効期限は24時間です。

    ※このメールに心当たりがない場合は、破棄してください。
    """
        return EmailService.send_email(to_email, subject, content)