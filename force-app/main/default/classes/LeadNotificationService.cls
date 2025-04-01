public with sharing class LeadNotificationService {
    public static void sendLeadConversionEmails(List<Lead> convertedLeads) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Lead lead : convertedLeads) {
            if (lead.Email != null && lead.Email.contains('@')) {  // Validate email format
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{lead.Email});
                mail.setSubject('Welcome to SweetHome – Your Dream Home Awaits!');
                mail.setPlainTextBody('Dear ' + lead.FirstName + ',\n\n'
                    + 'Welcome to SweetHome! We are delighted to assist you in finding your perfect home.\n\n'
                    + 'For queries, reach us at thirdvizion@gmail.com or 6382734615.\n\n'
                    + 'Best regards,\nSweetHome CRM Team');
                emails.add(mail);
            } else {
                System.debug('Skipping email for Lead: ' + lead.Id + ' - Invalid Email: ' + lead.Email);
            }
        }

        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
                System.debug('Emails sent successfully!');
            } catch (Exception e) {
                System.debug('Email sending failed: ' + e.getMessage());
            }
        } else {
            System.debug('No valid emails to send.');
        }
    }
}
