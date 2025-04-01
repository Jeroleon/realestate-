public with sharing class OpportunityEmailService {
    @future(callout = false)
    public static void sendOpportunityEmails(List<Id> notificationIds) {
        List<OpportunityEmailNotification__c> notifications = [
            SELECT Id, Email__c, Stage__c, Status__c 
            FROM OpportunityEmailNotification__c 
            WHERE Id IN :notificationIds AND Status__c = 'Pending'
        ];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (OpportunityEmailNotification__c notification : notifications) {
            if (notification.Email__c != null && notification.Email__c.contains('@')) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{notification.Email__c});
                mail.setSubject('Your Opportunity Status Has Changed');
                mail.setPlainTextBody('Dear Customer,\n\n'
                    + 'Your opportunity status is now: ' + notification.Stage__c + '.\n\n'
                    + 'Best regards,\nSweetHome Team');

                emails.add(mail);
                notification.Status__c = 'Sent'; // Update status
            } else {
                System.debug('Invalid email: ' + notification.Email__c);
            }
        }

        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
                update notifications;  // Save updated statuses
                System.debug('Emails sent successfully!');
            } catch (Exception e) {
                System.debug('Email sending failed: ' + e.getMessage());
            }
        } else {
            System.debug('No valid emails found.');
        }
    }
}
