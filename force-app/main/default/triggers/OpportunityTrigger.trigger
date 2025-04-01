trigger OpportunityTrigger on Opportunity (after update) {
    List<Opportunity> opportunitiesToNotify = new List<Opportunity>();
    Set<Id> accountIds = new Set<Id>();

    // Identify Opportunities where stage has changed to required values
    for (Opportunity opp : Trigger.new) {
        Opportunity oldOpp = Trigger.oldMap.get(opp.Id);

        if (oldOpp.StageName != opp.StageName && 
            (opp.StageName == 'Site Visit Scheduled' ||
             opp.StageName == 'Advance Payment Received' ||
             opp.StageName == 'Legal Document Acquisition' ||
             opp.StageName == 'Registration Slot Date Sent')) {
                 
            opportunitiesToNotify.add(opp);
            accountIds.add(opp.AccountId);
        }
    }

    if (!opportunitiesToNotify.isEmpty() && !accountIds.isEmpty()) {
        // Query Contacts linked to Accounts (fetch only necessary fields)
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
        for (Contact con : [
            SELECT Id, Email, FirstName, AccountId 
            FROM Contact 
            WHERE AccountId IN :accountIds
        ]) {
            contactMap.put(con.AccountId, con);
        }

        // Prepare emails to be sent
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Opportunity opp : opportunitiesToNotify) {
            if (contactMap.containsKey(opp.AccountId)) {
                Contact con = contactMap.get(opp.AccountId);

                String emailSubject;
        String emailBody;

        // If-Else instead of Switch
        if (opp.StageName == 'Site Visit Scheduled') {
            emailSubject = 'Your Site Visit is Scheduled – See You Soon!';
            emailBody = 'Dear ' + con.FirstName + ',\n\n'
                + 'We’re excited to confirm your site visit for ' + opp.Name + '. Here are the details:\n\n'
                + '📅 Date: [Scheduled Date]\n'
                + '⏰ Time: [Scheduled Time]\n'
                + '📍 Location: [Property Address]\n\n'
                + 'Our team will be there to assist you and answer any questions you may have. '
                + 'If you need to reschedule, please let us know at [contact details].\n\n'
                + 'Looking forward to meeting you!\n\n'
                + 'Best Regards,\n[Your Name]\n[Company Name]\n[Contact Details]';

        } else if (opp.StageName == 'Advance Payment Received') {
            emailSubject = 'Payment Received – Thank You!';
            emailBody = 'Dear ' + con.FirstName + ',\n\n'
                + 'We have successfully received your advance payment of [Amount] for ' + opp.Name + '. '
                + 'Thank you for your trust in [Company Name].\n\n'
                + 'Here are your payment details:\n'
                + '💳 Amount Paid: [Amount]\n'
                + '📅 Date: [Payment Date]\n'
                + '📝 Transaction ID: [Transaction ID]\n\n'
                + 'Your next steps will be [mention next steps like document verification, agreement signing, etc.]. '
                + 'If you have any questions, feel free to reach out.\n\n'
                + 'Best Regards,\n[Your Name]\n[Company Name]\n[Contact Details]';

        } else if (opp.StageName == 'Legal Document Acquisition') {
            emailSubject = 'Important Update – Legal Documents Acquired';
            emailBody = 'Dear ' + con.FirstName + ',\n\n'
                + 'We are pleased to inform you that the necessary legal documents for ' + opp.Name + ' have been successfully acquired.\n\n'
                + 'The documents include:\n'
                + '📜 [List of documents, e.g., Sale Agreement, Title Deed, etc.]\n\n'
                + 'Please let us know if you would like to review them or require any further clarifications. '
                + 'You can reach us at [contact details].\n\n'
                + 'Best Regards,\n[Your Name]\n[Company Name]\n[Contact Details]';

        } else if (opp.StageName == 'Registration Slot Date Sent') {
            emailSubject = 'Your Property Registration Slot is Confirmed';
            emailBody = 'Dear ' + con.FirstName + ',\n\n'
                + 'We are happy to inform you that your property registration slot has been scheduled. Here are the details:\n\n'
                + '📅 Date: [Scheduled Date]\n'
                + '⏰ Time: [Scheduled Time]\n'
                + '🏛 Location: [Registration Office Address]\n\n'
                + 'Please ensure you carry all required documents. If you have any queries or need to reschedule, '
                + 'please contact us at [contact details].\n\n'
                + 'We look forward to completing this final step with you!\n\n'
                + 'Best Regards,\n[Your Name]\n[Company Name]\n[Contact Details]';

        } else {
            // Default email if StageName does not match predefined cases
            emailSubject = 'Update on Your Property Opportunity';
            emailBody = 'Dear ' + con.FirstName + ',\n\n'
                + 'Your opportunity status has changed to: ' + opp.StageName + '.\n\n'
                + 'Please contact us for more details.\n\n'
                + 'Best regards,\nSweetHome CRM Team';
        }

        // Prepare and add the email message
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{con.Email});
        mail.setSubject(emailSubject);
        mail.setPlainTextBody(emailBody);
        emails.add(mail);
    }
}

        // Send emails only if there are valid recipients
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
