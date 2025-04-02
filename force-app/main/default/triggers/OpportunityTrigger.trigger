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
        Datetime currentDateTime = System.now(); 

        String presentDate = currentDateTime.format('yyyy-MM-dd'); 
        String presentTime = currentDateTime.format('HH:mm a'); 
        Date nextDay = currentDateTime.date().addDays(1); 
        Date nextDay3 = currentDateTime.date().addDays(3); 
        // Get the next day's date

        // If-Else instead of Switch
        if (opp.StageName == 'Site Visit Scheduled') {
            emailSubject = 'Your Site Visit is Scheduled – See You Soon!';
            emailBody = 'Dear ' + con.FirstName + ',\n\n'
                + 'We’re excited to confirm your site visit for ' + opp.Name + '. Here are the details:\n\n'
                + '📅 Date: '+ nextDay+'\n'
                + '⏰ Time: 9:30 AM TO 12:30 PM \n'
                + '📍 Location: SWEETHOMES \n\n'
                + 'Our team will be there to assist you and answer any questions you may have. '
                + 'If you need to reschedule, please let us know at thirdvizion@gmail.com or 6382734615.\n\n'
                + 'Looking forward to meeting you!\n\n'
                + 'Best Regards,\nSweetHome CRM Team\nSweetHomes\n thirdvizion@gmail.com or 6382734615';

        } else if (opp.StageName == 'Advance Payment Received') {
            emailSubject = 'Payment Received – Thank You!';
            emailBody = 'Dear ' + con.FirstName + ',\n\n'
                + 'We have successfully received your advance payment of [Amount] for ' + opp.Name + '. '
                + 'Thank you for your trust in SweetHomes.\n\n'
                + 'Here are your payment details:\n'
                + '💳 Amount Paid: [Amount]\n'
                + '📅 Date:' +presentDate+ ' \n'
                + '📝 Transaction ID: [Transaction ID]\n\n'
                + 'Your next steps will be submiting the  document for verification sent these legal document through email to thirdvizion@gmail.com  '
                + 'If you have any questions, feel free to reach out.\n\n'
                + 'Best Regards,\nSweetHome CRM Team\nSweetHomes\nthirdvizion@gmail.com or 6382734615';

        } else if (opp.StageName == 'Legal Document Acquisition') {
            emailSubject = 'Important Update – Legal Documents Acquired';
            emailBody = 'Dear ' + con.FirstName + ',\n\n'
                + 'We are pleased to inform you that the necessary legal documents for ' + opp.Name + ' have been successfully acquired.\n\n'
                + 'The documents include:\n'
                + '📜 Sale Agreement, Title Deed, Buyer Id proof and other documents\n\n'
                + 'Please let us know if you would like to review them or require any further clarifications. '
                + 'You can reach us at thirdvizion@gmail.com or 6382734615.\n\n'
                + 'Best Regards,\nSweetHome CRM Team\nSweetHomes\nthirdvizion@gmail.com or 6382734615';

        } else if (opp.StageName == 'Registration Slot Date Sent') {
            emailSubject = 'Your Property Registration Slot is Confirmed';
            emailBody = 'Dear ' + con.FirstName + ',\n\n'
                + 'We are happy to inform you that your property registration slot has been scheduled. Here are the details:\n\n'
                + '📅 Date: '+nextDay3+'\n'
                + '⏰ Time: 10:00 AM\n'
                + '🏛 Location: Registration Office Near your location\n\n'
                + 'Please ensure you carry all required documents. If you have any queries or need to reschedule, '
                + 'please contact us at thirdvizion@gmail.com or 6382734615.\n\n'
                + 'We look forward to completing this final step with you!\n\n'
                + 'Best Regards,\nSweetHome CRM Team\nSweetHomes\nthirdvizion@gmail.com or 6382734615';

        } else {
            // Default email if StageName does not match predefined cases
            emailSubject = 'Update on Your Property Opportunity';
            emailBody = 'Dear ' + con.FirstName + ',\n\n'
                + 'Your opportunity status has changed to: ' + opp.StageName + '.\n\n'
                + 'Please contact us for more details.\n\n'
                + 'Best regards,\nSweetHome CRM Team \nSweetHomes\nthirdvizion@gmail.com or 6382734615';
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
