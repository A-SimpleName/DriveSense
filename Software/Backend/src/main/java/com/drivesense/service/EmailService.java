package com.drivesense.service;

import com.drivesense.exceptions.ExternalApiException;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@Service
public class EmailService {

    @Autowired
    private JavaMailSender mailSender;

    @Value("${app.mail.from}")
    private String fromAddress;

    @Value("${app.mail.from-name}")
    private String fromName;

    @Value("${app.vehicle-invite.accept-url}")
    private String vehicleInviteAcceptUrl;

    // ──────────────────────────────────────────
    // PUBLIC METHODEN
    // ──────────────────────────────────────────

    @Async
    public void sendVerificationCode(String toEmail, String code) {
        String subject = "Dein DriveSense Bestätigungscode";
        String html = buildVerificationEmail(code);
        sendHtmlEmail(toEmail, subject, html);
    }

    @Async
    public void sendPasswordResetCode(String toEmail, String code) {
        String subject = "DriveSense – Passwort zurücksetzen";
        String html = buildPasswordResetEmail(code);
        sendHtmlEmail(toEmail, subject, html);
    }

    @Async
    public void sendGroupInvitation(String toEmail, String inviterName,
                                    String groupName, String code) {
        String subject = inviterName + " hat dich zu einer DriveSense-Gruppe eingeladen";
        String html = buildGroupInviteEmail(inviterName, groupName, code);
        sendHtmlEmail(toEmail, subject, html);
    }

    @Async
    public void sendVehicleInvitation(String toEmail,
                                      String inviterName,
                                      String vehicleName,
                                      String role,
                                      String code) {

        String subject = inviterName + " hat dich zu einem Fahrzeug eingeladen";
        String inviteUrl = vehicleInviteAcceptUrl.formatted(
                URLEncoder.encode(code, StandardCharsets.UTF_8)
        );

        String html = baseTemplate(
                "Fahrzeugeinladung",
                "Du wurdest eingeladen!",
                "<strong>" + escapeHtml(inviterName) + "</strong> hat dich zu dem Fahrzeug " +
                        "<strong>" + escapeHtml(vehicleName) + "</strong> eingeladen.<br><br>" +
                        "Rolle: <strong>" + escapeHtml(role) + "</strong><br><br>" +
                        "Klicke auf den Button, um Zugriff zu erhalten, oder gib den Code in der App ein." +
                        "<br><br><a href=\"" + escapeHtml(inviteUrl) + "\" style=\"display:inline-block;background:#4f8ef7;color:#ffffff;padding:12px 24px;border-radius:8px;text-decoration:none;font-weight:600;\">Fahrzeug annehmen</a>",
                code,
                "Der Code ist 48 Stunden gültig."
        );

        sendHtmlEmail(toEmail, subject, html);
    }

    // ──────────────────────────────────────────
    // INTERNER MAIL-VERSAND
    // ──────────────────────────────────────────

    private void sendHtmlEmail(String to, String subject, String html) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(fromAddress, fromName);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(html, true);
            mailSender.send(message);
      } catch (MailException e) {
        throw new ExternalApiException("E-Mail konnte nicht gesendet werden", e);
        } catch (MessagingException | java.io.UnsupportedEncodingException e) {
        throw new ExternalApiException("E-Mail konnte nicht vorbereitet werden", e);
        }
    }

    // ──────────────────────────────────────────
    // HTML TEMPLATES
    // ──────────────────────────────────────────

    private String buildVerificationEmail(String code) {
        return baseTemplate(
                "E-Mail bestätigen",
                "Willkommen bei DriveSense!",
                "Gib diesen Code ein, um deine E-Mail-Adresse zu bestätigen.",
                code,
                "Der Code ist 15 Minuten gültig."
        );
    }

    private String buildPasswordResetEmail(String code) {
        return baseTemplate(
                "Passwort zurücksetzen",
                "Passwort zurücksetzen",
                "Gib diesen Code in der App ein, um dein Passwort zu ändern.",
                code,
                "Der Code ist 15 Minuten gültig. Falls du keine Anfrage gestellt hast, ignoriere diese E-Mail."
        );
    }

    private String buildGroupInviteEmail(String inviterName, String groupName, String code) {
        String inviteUrl = "http://localhost:5173/invite?code=" + code;
        return baseTemplate(
                "Gruppeneinladung",
                "Du wurdest eingeladen!",
                "<strong>" + escapeHtml(inviterName) + "</strong> hat dich zur Gruppe " +
                        "<strong>" + escapeHtml(groupName) + "</strong> eingeladen. " +
                        "Klicke auf den Button oder gib den Code manuell ein." +
                        "<br><br><a href=\"" + inviteUrl + "\" style=\"display:inline-block;background:#4f8ef7;color:#ffffff;padding:12px 24px;border-radius:8px;text-decoration:none;font-weight:600;\">Einladung annehmen</a>",
                code,
                "Der Code ist 48 Stunden gültig."
        );
    }

    private String baseTemplate(String title, String heading,
                                String bodyText, String code, String footer) {
        String logoTag = buildLogoTag();

        return """
            <!DOCTYPE html>
            <html lang="de">
            <head>
              <meta charset="UTF-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <title>%s</title>
            </head>
            <body style="margin:0;padding:0;background-color:#f4f4f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
              <table width="100%%" cellpadding="0" cellspacing="0" style="background:#f4f4f5;padding:40px 20px;">
                <tr><td align="center">
                  <table width="100%%" cellpadding="0" cellspacing="0" style="max-width:480px;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 1px 4px rgba(0,0,0,0.08);">

                    <!-- Header -->
                    <tr>
                       <td style="background:#e2e8f0;padding:28px 32px;text-align:center;">
                         %s
                       </td>
                     </tr>

                    <!-- Body -->
                    <tr>
                      <td style="padding:36px 32px 28px;">
                        <h1 style="margin:0 0 12px;font-size:22px;font-weight:600;color:#111111;letter-spacing:-0.3px;">%s</h1>
                        <p style="margin:0 0 28px;font-size:15px;color:#555555;line-height:1.6;">%s</p>

                        <!-- Code Box -->
                        <div style="background:#f0f4ff;border:1px solid #d0deff;border-radius:10px;padding:20px;text-align:center;margin-bottom:24px;">
                          <span style="font-size:36px;font-weight:700;letter-spacing:10px;color:#1a1a2e;font-family:'Courier New',monospace;">%s</span>
                        </div>

                        <p style="margin:0;font-size:13px;color:#888888;line-height:1.5;">%s</p>
                      </td>
                    </tr>

                    <!-- Footer -->
                    <tr>
                      <td style="background:#f9f9f9;padding:16px 32px;border-top:1px solid #eeeeee;">
                        <p style="margin:0;font-size:12px;color:#aaaaaa;text-align:center;">
                          DriveSense &ndash; Automatische Fahrtenprotokollierung
                        </p>
                      </td>
                    </tr>

                  </table>
                </td></tr>
              </table>
            </body>
            </html>
            """.formatted(
                escapeHtml(title),
                logoTag,
                escapeHtml(heading),
                bodyText,
                escapeHtml(code),
                escapeHtml(footer)
        );
    }

    private String escapeHtml(String input) {
        if (input == null) return "";
        return input
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }

    private String buildLogoTag() {
        return "<img src=\"https://raw.githubusercontent.com/A-SimpleName/DriveSense/main/Design/Logos/DS_Logo_weißer-Hintergrund.png\" " +
                "alt=\"DriveSense\" style=\"height:70px;margin-bottom:10px;display:block;margin-left:auto;margin-right:auto;\">";
    }
}
