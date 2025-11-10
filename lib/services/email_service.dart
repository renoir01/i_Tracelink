import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/constants.dart';

enum EmailProvider {
  sendgrid,
  mailgun,
  ses,
}

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  late final EmailProvider _provider;
  late final String _apiKey;
  late final String _fromEmail;
  late final String _fromName;
  late final String _domain;

  void initialize() {
    final provider = dotenv.env['EMAIL_SERVICE_PROVIDER'] ?? 'sendgrid';
    _provider = _parseProvider(provider);
    _apiKey = dotenv.env['EMAIL_API_KEY'] ?? '';
    _fromEmail = dotenv.env['EMAIL_FROM_EMAIL'] ?? 'noreply@itracelink.rw';
    _fromName = dotenv.env['EMAIL_FROM_NAME'] ?? 'iTraceLink';
    _domain = dotenv.env['EMAIL_TEMPLATE_DOMAIN'] ?? 'mg.itracelink.rw';
  }

  EmailProvider _parseProvider(String provider) {
    switch (provider.toLowerCase()) {
      case 'mailgun':
        return EmailProvider.mailgun;
      case 'ses':
        return EmailProvider.ses;
      case 'sendgrid':
      default:
        return EmailProvider.sendgrid;
    }
  }

  // Send email via SendGrid
  Future<bool> _sendViaSendGrid(EmailMessage message) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.sendgrid.com/v3/mail/send'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'personalizations': [
            {
              'to': [
                {'email': message.toEmail, 'name': message.toName}
              ],
              'subject': message.subject,
            }
          ],
          'from': {
            'email': _fromEmail,
            'name': _fromName,
          },
          'content': [
            {
              'type': 'text/html',
              'value': message.htmlContent,
            }
          ],
        }),
      );

      return response.statusCode == 202;
    } catch (e) {
      print('SendGrid Error: $e');
      return false;
    }
  }

  // Send email via Mailgun
  Future<bool> _sendViaMailgun(EmailMessage message) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.mailgun.net/v3/$_domain/messages'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('api:$_apiKey'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'from': '$_fromName <$_fromEmail>',
          'to': '${message.toName} <${message.toEmail}>',
          'subject': message.subject,
          'html': message.htmlContent,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Mailgun Error: $e');
      return false;
    }
  }

  // Send email via AWS SES (placeholder - would need AWS SDK)
  Future<bool> _sendViaSES(EmailMessage message) async {
    // AWS SES implementation would go here
    // For now, return false
    print('AWS SES not implemented yet');
    return false;
  }

  // Main send method
  Future<bool> sendEmail(EmailMessage message) async {
    switch (_provider) {
      case EmailProvider.sendgrid:
        return _sendViaSendGrid(message);
      case EmailProvider.mailgun:
        return _sendViaMailgun(message);
      case EmailProvider.ses:
        return _sendViaSES(message);
    }
  }

  // ========== EMAIL TEMPLATES ==========

  // Welcome email for new users
  Future<bool> sendWelcomeEmail({
    required String toEmail,
    required String userName,
    required String userType,
  }) async {
    final message = EmailMessage(
      toEmail: toEmail,
      toName: userName,
      subject: 'Welcome to iTraceLink - Your Account is Ready!',
      htmlContent: _buildWelcomeEmailTemplate(userName, userType),
    );

    return sendEmail(message);
  }

  // Account verification email
  Future<bool> sendVerificationEmail({
    required String toEmail,
    required String userName,
    required String verificationLink,
  }) async {
    final message = EmailMessage(
      toEmail: toEmail,
      toName: userName,
      subject: 'Verify Your iTraceLink Account',
      htmlContent: _buildVerificationEmailTemplate(userName, verificationLink),
    );

    return sendEmail(message);
  }

  // Password reset email
  Future<bool> sendPasswordResetEmail({
    required String toEmail,
    required String userName,
    required String resetLink,
  }) async {
    final message = EmailMessage(
      toEmail: toEmail,
      toName: userName,
      subject: 'Reset Your iTraceLink Password',
      htmlContent: _buildPasswordResetEmailTemplate(userName, resetLink),
    );

    return sendEmail(message);
  }

  // Order confirmation email
  Future<bool> sendOrderConfirmationEmail({
    required String toEmail,
    required String buyerName,
    required String orderId,
    required String sellerName,
    required double quantity,
    required double totalAmount,
    required String deliveryAddress,
  }) async {
    final message = EmailMessage(
      toEmail: toEmail,
      toName: buyerName,
      subject: 'Order Confirmation - $orderId',
      htmlContent: _buildOrderConfirmationEmailTemplate(
        buyerName, orderId, sellerName, quantity, totalAmount, deliveryAddress,
      ),
    );

    return sendEmail(message);
  }

  // Order status update email
  Future<bool> sendOrderStatusUpdateEmail({
    required String toEmail,
    required String userName,
    required String orderId,
    required String status,
    required String statusMessage,
  }) async {
    final message = EmailMessage(
      toEmail: toEmail,
      toName: userName,
      subject: 'Order Update - $orderId',
      htmlContent: _buildOrderStatusUpdateEmailTemplate(
        userName, orderId, status, statusMessage,
      ),
    );

    return sendEmail(message);
  }

  // Payment confirmation email
  Future<bool> sendPaymentConfirmationEmail({
    required String toEmail,
    required String userName,
    required String orderId,
    required double amount,
    required String paymentMethod,
    required String transactionId,
  }) async {
    final message = EmailMessage(
      toEmail: toEmail,
      toName: userName,
      subject: 'Payment Confirmation - Order $orderId',
      htmlContent: _buildPaymentConfirmationEmailTemplate(
        userName, orderId, amount, paymentMethod, transactionId,
      ),
    );

    return sendEmail(message);
  }

  // Quality certification notification
  Future<bool> sendCertificationNotificationEmail({
    required String toEmail,
    required String userName,
    required String certificationType,
    required String batchId,
    required String status,
    String? notes,
  }) async {
    final message = EmailMessage(
      toEmail: toEmail,
      toName: userName,
      subject: 'Certification Update - $certificationType',
      htmlContent: _buildCertificationNotificationEmailTemplate(
        userName, certificationType, batchId, status, notes,
      ),
    );

    return sendEmail(message);
  }

  // Weekly summary email
  Future<bool> sendWeeklySummaryEmail({
    required String toEmail,
    required String userName,
    required Map<String, dynamic> summaryData,
  }) async {
    final message = EmailMessage(
      toEmail: toEmail,
      toName: userName,
      subject: 'Your Weekly iTraceLink Summary',
      htmlContent: _buildWeeklySummaryEmailTemplate(userName, summaryData),
    );

    return sendEmail(message);
  }

  // ========== EMAIL TEMPLATE BUILDERS ==========

  String _buildWelcomeEmailTemplate(String userName, String userType) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Welcome to iTraceLink</title>
</head>
<body style="font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4;">
    <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff;">
        <!-- Header -->
        <div style="background-color: #2E7D32; padding: 20px; text-align: center;">
            <h1 style="color: #ffffff; margin: 0; font-size: 24px;">🌱 Welcome to iTraceLink</h1>
        </div>

        <!-- Content -->
        <div style="padding: 30px;">
            <h2 style="color: #333333;">Hello $userName!</h2>

            <p style="color: #666666; line-height: 1.6;">
                Welcome to iTraceLink, Rwanda's premier agricultural supply chain traceability platform.
                Your account as a <strong>$userType</strong> has been successfully created.
            </p>

            <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <h3 style="color: #2E7D32; margin-top: 0;">What's Next?</h3>
                <ul style="color: #666666; line-height: 1.8;">
                    <li>Complete your profile information</li>
                    <li>Explore available features for your role</li>
                    <li>Connect with other agricultural stakeholders</li>
                    <li>Start tracking your agricultural products</li>
                </ul>
            </div>

            <div style="text-align: center; margin: 30px 0;">
                <a href="${dotenv.env['BASE_URL'] ?? 'https://itracelink.rw'}"
                   style="background-color: #2E7D32; color: #ffffff; padding: 12px 30px;
                          text-decoration: none; border-radius: 6px; font-weight: bold;">
                    Get Started
                </a>
            </div>
        </div>

        <!-- Footer -->
        <div style="background-color: #f8f9fa; padding: 20px; text-align: center; border-top: 1px solid #eeeeee;">
            <p style="color: #666666; margin: 0; font-size: 12px;">
                This email was sent by iTraceLink<br>
                © 2025 iTraceLink. All rights reserved.
            </p>
        </div>
    </div>
</body>
</html>
''';
  }

  String _buildVerificationEmailTemplate(String userName, String verificationLink) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Verify Your Account</title>
</head>
<body style="font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4;">
    <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff;">
        <div style="background-color: #1976D2; padding: 20px; text-align: center;">
            <h1 style="color: #ffffff; margin: 0; font-size: 24px;">Verify Your Account</h1>
        </div>

        <div style="padding: 30px;">
            <h2 style="color: #333333;">Hi $userName,</h2>

            <p style="color: #666666; line-height: 1.6;">
                Thank you for registering with iTraceLink. To complete your account setup and start using our platform,
                please verify your email address.
            </p>

            <div style="text-align: center; margin: 30px 0;">
                <a href="$verificationLink"
                   style="background-color: #1976D2; color: #ffffff; padding: 15px 40px;
                          text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block;">
                    Verify Email Address
                </a>
            </div>

            <p style="color: #666666; line-height: 1.6;">
                If the button doesn't work, you can copy and paste this link into your browser:<br>
                <span style="word-break: break-all; color: #1976D2;">$verificationLink</span>
            </p>

            <div style="background-color: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 6px; margin: 20px 0;">
                <p style="color: #856404; margin: 0; font-size: 14px;">
                    <strong>Note:</strong> This verification link will expire in 24 hours for security reasons.
                </p>
            </div>
        </div>

        <div style="background-color: #f8f9fa; padding: 20px; text-align: center; border-top: 1px solid #eeeeee;">
            <p style="color: #666666; margin: 0; font-size: 12px;">
                If you didn't create an account with iTraceLink, please ignore this email.<br>
                © 2025 iTraceLink. All rights reserved.
            </p>
        </div>
    </div>
</body>
</html>
''';
  }

  String _buildPasswordResetEmailTemplate(String userName, String resetLink) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Reset Your Password</title>
</head>
<body style="font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4;">
    <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff;">
        <div style="background-color: #FF9800; padding: 20px; text-align: center;">
            <h1 style="color: #ffffff; margin: 0; font-size: 24px;">🔐 Password Reset</h1>
        </div>

        <div style="padding: 30px;">
            <h2 style="color: #333333;">Hi $userName,</h2>

            <p style="color: #666666; line-height: 1.6;">
                We received a request to reset your password for your iTraceLink account.
                Click the button below to create a new password.
            </p>

            <div style="text-align: center; margin: 30px 0;">
                <a href="$resetLink"
                   style="background-color: #FF9800; color: #ffffff; padding: 15px 40px;
                          text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block;">
                    Reset Password
                </a>
            </div>

            <p style="color: #666666; line-height: 1.6;">
                If you didn't request a password reset, please ignore this email.
                Your password will remain unchanged.
            </p>

            <div style="background-color: #ffeaa7; border: 1px solid #ffeaa7; padding: 15px; border-radius: 6px; margin: 20px 0;">
                <p style="color: #856404; margin: 0; font-size: 14px;">
                    <strong>Security Notice:</strong> This reset link will expire in 1 hour. For your security,
                    never share this link with anyone.
                </p>
            </div>
        </div>

        <div style="background-color: #f8f9fa; padding: 20px; text-align: center; border-top: 1px solid #eeeeee;">
            <p style="color: #666666; margin: 0; font-size: 12px;">
                Need help? Contact our support team at support@itracelink.rw<br>
                © 2025 iTraceLink. All rights reserved.
            </p>
        </div>
    </div>
</body>
</html>
''';
  }

  String _buildOrderConfirmationEmailTemplate(
    String buyerName,
    String orderId,
    String sellerName,
    double quantity,
    double totalAmount,
    String deliveryAddress,
  ) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Order Confirmation</title>
</head>
<body style="font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4;">
    <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff;">
        <div style="background-color: #4CAF50; padding: 20px; text-align: center;">
            <h1 style="color: #ffffff; margin: 0; font-size: 24px;">✅ Order Confirmed</h1>
        </div>

        <div style="padding: 30px;">
            <h2 style="color: #333333;">Hi $buyerName,</h2>

            <p style="color: #666666; line-height: 1.6;">
                Great news! Your order has been confirmed and is now being processed.
                Here are the details of your order:
            </p>

            <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <h3 style="color: #2E7D32; margin-top: 0;">Order Details</h3>
                <table style="width: 100%; border-collapse: collapse;">
                    <tr>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eeeeee;"><strong>Order ID:</strong></td>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eeeeee;">$orderId</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eeeeee;"><strong>Seller:</strong></td>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eeeeee;">$sellerName</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eeeeee;"><strong>Quantity:</strong></td>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eeeeee;">${quantity.toStringAsFixed(0)} kg</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eeeeee;"><strong>Total Amount:</strong></td>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eeeeee;">RWF ${totalAmount.toStringAsFixed(0)}</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0;"><strong>Delivery Address:</strong></td>
                        <td style="padding: 8px 0;">$deliveryAddress</td>
                    </tr>
                </table>
            </div>

            <div style="background-color: #e3f2fd; border: 1px solid #bbdefb; padding: 15px; border-radius: 6px; margin: 20px 0;">
                <p style="color: #1565C0; margin: 0; font-size: 14px;">
                    <strong>What's Next?</strong><br>
                    • Our quality team will verify the order<br>
                    • You'll receive payment instructions<br>
                    • Track your order status in the app<br>
                    • Get notified when ready for pickup/delivery
                </p>
            </div>

            <div style="text-align: center; margin: 30px 0;">
                <a href="${dotenv.env['BASE_URL'] ?? 'https://itracelink.rw'}/orders/$orderId"
                   style="background-color: #4CAF50; color: #ffffff; padding: 12px 30px;
                          text-decoration: none; border-radius: 6px; font-weight: bold;">
                    Track Order
                </a>
            </div>
        </div>

        <div style="background-color: #f8f9fa; padding: 20px; text-align: center; border-top: 1px solid #eeeeee;">
            <p style="color: #666666; margin: 0; font-size: 12px;">
                Questions? Contact us at support@itracelink.rw<br>
                © 2025 iTraceLink. All rights reserved.
            </p>
        </div>
    </div>
</body>
</html>
''';
  }

  String _buildOrderStatusUpdateEmailTemplate(
    String userName,
    String orderId,
    String status,
    String statusMessage,
  ) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Order Status Update</title>
</head>
<body style="font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4;">
    <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff;">
        <div style="background-color: #2196F3; padding: 20px; text-align: center;">
            <h1 style="color: #ffffff; margin: 0; font-size: 24px;">📦 Order Update</h1>
        </div>

        <div style="padding: 30px;">
            <h2 style="color: #333333;">Hi $userName,</h2>

            <p style="color: #666666; line-height: 1.6;">
                We have an important update about your order <strong>$orderId</strong>:
            </p>

            <div style="background-color: #e3f2fd; border: 1px solid #bbdefb; padding: 20px; border-radius: 8px; margin: 20px 0; text-align: center;">
                <h3 style="color: #1565C0; margin: 0;">Status: $status</h3>
                <p style="color: #1565C0; margin: 10px 0 0 0;">$statusMessage</p>
            </div>

            <div style="text-align: center; margin: 30px 0;">
                <a href="${dotenv.env['BASE_URL'] ?? 'https://itracelink.rw'}/orders/$orderId"
                   style="background-color: #2196F3; color: #ffffff; padding: 12px 30px;
                          text-decoration: none; border-radius: 6px; font-weight: bold;">
                    View Order Details
                </a>
            </div>

            <p style="color: #666666; line-height: 1.6;">
                You can also check your order status anytime in the iTraceLink mobile app.
            </p>
        </div>

        <div style="background-color: #f8f9fa; padding: 20px; text-align: center; border-top: 1px solid #eeeeee;">
            <p style="color: #666666; margin: 0; font-size: 12px;">
                © 2025 iTraceLink. All rights reserved.
            </p>
        </div>
    </div>
</body>
</html>
''';
  }

  String _buildPaymentConfirmationEmailTemplate(
    String userName,
    String orderId,
    double amount,
    String paymentMethod,
    String transactionId,
  ) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Payment Confirmation</title>
</head>
<body style="font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4;">
    <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff;">
        <div style="background-color: #4CAF50; padding: 20px; text-align: center;">
            <h1 style="color: #ffffff; margin: 0; font-size: 24px;">💰 Payment Confirmed</h1>
        </div>

        <div style="padding: 30px;">
            <h2 style="color: #333333;">Hi $userName,</h2>

            <p style="color: #666666; line-height: 1.6;">
                Your payment has been successfully processed. Here are the payment details:
            </p>

            <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <h3 style="color: #2E7D32; margin-top: 0;">Payment Details</h3>
                <table style="width: 100%; border-collapse: collapse;">
                    <tr>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eeeeee;"><strong>Order ID:</strong></td>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eeeeee;">$orderId</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eeeeee;"><strong>Amount:</strong></td>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eeeeee;">RWF ${amount.toStringAsFixed(0)}</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eeeeee;"><strong>Payment Method:</strong></td>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eeeeee;">$paymentMethod</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eeeeee;"><strong>Transaction ID:</strong></td>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eeeeee;">$transactionId</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0;"><strong>Date:</strong></td>
                        <td style="padding: 8px 0;">${DateTime.now().toString().split(' ')[0]}</td>
                    </tr>
                </table>
            </div>

            <div style="background-color: #e8f5e8; border: 1px solid #c8e6c9; padding: 15px; border-radius: 6px; margin: 20px 0;">
                <p style="color: #2E7D32; margin: 0; font-size: 14px;">
                    <strong>✅ Payment Successful!</strong><br>
                    Your order is now being processed. You will receive updates on the order status.
                </p>
            </div>

            <div style="text-align: center; margin: 30px 0;">
                <a href="${dotenv.env['BASE_URL'] ?? 'https://itracelink.rw'}/orders/$orderId"
                   style="background-color: #4CAF50; color: #ffffff; padding: 12px 30px;
                          text-decoration: none; border-radius: 6px; font-weight: bold;">
                    View Order
                </a>
            </div>
        </div>

        <div style="background-color: #f8f9fa; padding: 20px; text-align: center; border-top: 1px solid #eeeeee;">
            <p style="color: #666666; margin: 0; font-size: 12px;">
                Keep this email for your records.<br>
                © 2025 iTraceLink. All rights reserved.
            </p>
        </div>
    </div>
</body>
</html>
''';
  }

  String _buildCertificationNotificationEmailTemplate(
    String userName,
    String certificationType,
    String batchId,
    String status,
    String? notes,
  ) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Certification Update</title>
</head>
<body style="font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4;">
    <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff;">
        <div style="background-color: #FF9800; padding: 20px; text-align: center;">
            <h1 style="color: #ffffff; margin: 0; font-size: 24px;">🧪 Certification Update</h1>
        </div>

        <div style="padding: 30px;">
            <h2 style="color: #333333;">Hi $userName,</h2>

            <p style="color: #666666; line-height: 1.6;">
                We have an update regarding your certification submission:
            </p>

            <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <h3 style="color: #E65100; margin-top: 0;">Certification Details</h3>
                <table style="width: 100%; border-collapse: collapse;">
                    <tr>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eeeeee;"><strong>Type:</strong></td>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eeeeee;">$certificationType</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eeeeee;"><strong>Batch ID:</strong></td>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eeeeee;">$batchId</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0;"><strong>Status:</strong></td>
                        <td style="padding: 8px 0;">
                            <span style="color: ${status == 'Approved' ? '#4CAF50' : status == 'Rejected' ? '#F44336' : '#FF9800'}; font-weight: bold;">
                                $status
                            </span>
                        </td>
                    </tr>
                </table>
            </div>

            ${notes != null ? '''
            <div style="background-color: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 6px; margin: 20px 0;">
                <p style="color: #856404; margin: 0; font-size: 14px;">
                    <strong>Additional Notes:</strong><br>
                    $notes
                </p>
            </div>
            ''' : ''}

            <div style="text-align: center; margin: 30px 0;">
                <a href="${dotenv.env['BASE_URL'] ?? 'https://itracelink.rw'}/certifications"
                   style="background-color: #FF9800; color: #ffffff; padding: 12px 30px;
                          text-decoration: none; border-radius: 6px; font-weight: bold;">
                    View Certifications
                </a>
            </div>
        </div>

        <div style="background-color: #f8f9fa; padding: 20px; text-align: center; border-top: 1px solid #eeeeee;">
            <p style="color: #666666; margin: 0; font-size: 12px;">
                Questions about your certification? Contact quality@itracelink.rw<br>
                © 2025 iTraceLink. All rights reserved.
            </p>
        </div>
    </div>
</body>
</html>
''';
  }

  String _buildWeeklySummaryEmailTemplate(String userName, Map<String, dynamic> summaryData) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Weekly Summary</title>
</head>
<body style="font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4;">
    <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff;">
        <div style="background-color: #9C27B0; padding: 20px; text-align: center;">
            <h1 style="color: #ffffff; margin: 0; font-size: 24px;">📊 Your Weekly Summary</h1>
        </div>

        <div style="padding: 30px;">
            <h2 style="color: #333333;">Hi $userName,</h2>

            <p style="color: #666666; line-height: 1.6;">
                Here's a summary of your iTraceLink activity for the past week:
            </p>

            <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <h3 style="color: #6A1B9A; margin-top: 0;">Activity Summary</h3>
                <div style="display: flex; justify-content: space-around; margin: 20px 0;">
                    <div style="text-align: center;">
                        <div style="font-size: 24px; font-weight: bold; color: #4CAF50;">${summaryData['orders'] ?? 0}</div>
                        <div style="font-size: 12px; color: #666;">Orders</div>
                    </div>
                    <div style="text-align: center;">
                        <div style="font-size: 24px; font-weight: bold; color: #2196F3;">${summaryData['certifications'] ?? 0}</div>
                        <div style="font-size: 12px; color: #666;">Certifications</div>
                    </div>
                    <div style="text-align: center;">
                        <div style="font-size: 24px; font-weight: bold; color: #FF9800;">${summaryData['payments'] ?? 0}</div>
                        <div style="font-size: 12px; color: #666;">Payments</div>
                    </div>
                </div>
            </div>

            <div style="text-align: center; margin: 30px 0;">
                <a href="${dotenv.env['BASE_URL'] ?? 'https://itracelink.rw'}/dashboard"
                   style="background-color: #9C27B0; color: #ffffff; padding: 12px 30px;
                          text-decoration: none; border-radius: 6px; font-weight: bold;">
                    View Full Dashboard
                </a>
            </div>
        </div>

        <div style="background-color: #f8f9fa; padding: 20px; text-align: center; border-top: 1px solid #eeeeee;">
            <p style="color: #666666; margin: 0; font-size: 12px;">
                You're receiving this summary because you're an active iTraceLink user.<br>
                © 2025 iTraceLink. All rights reserved.
            </p>
        </div>
    </div>
</body>
</html>
''';
  }
}

// Email message structure
class EmailMessage {
  final String toEmail;
  final String toName;
  final String subject;
  final String htmlContent;

  const EmailMessage({
    required this.toEmail,
    required this.toName,
    required this.subject,
    required this.htmlContent,
  });
}
