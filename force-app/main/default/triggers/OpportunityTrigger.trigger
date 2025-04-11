trigger OpportunityTrigger on Opportunity (after update) {
    List<Opportunity> opportunitiesToNotify = new List<Opportunity>();
    Set<Id> accountIds = new Set<Id>();

    // Identify Opportunities where stage has changed to required values
    for (Opportunity opp : Trigger.new) {
        Opportunity oldOpp = Trigger.oldMap.get(opp.Id);

        if (oldOpp.StageName != opp.StageName && 
            (opp.StageName == 'New' ||
             opp.StageName == 'Site Visit Scheduled' ||
             opp.StageName == 'Advance Payment Received' ||
             opp.StageName == 'Legal Document Acquisition' ||
             opp.StageName == 'Bank Loan' ||
             opp.StageName == 'Registration Slot Date Sent')) {
                 
            opportunitiesToNotify.add(opp);
            accountIds.add(opp.AccountId);
        }
    }

    if (!opportunitiesToNotify.isEmpty() && !accountIds.isEmpty()) {
        // Query Contacts linked to Accounts (fetch only necessary fields)
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
        for (Contact con : [
            SELECT Id, Email, FirstName, AccountId ,Account_Number__c
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
        
        // Get the next day's date

        // If-Else instead of Switch
        if (opp.StageName == 'Site Visit Scheduled') {
            emailSubject = 'Your Site Visit is Scheduled – See You Soon!';


            String visitDateStr = opp.Site_Visit_Date__c != null ? String.valueOf(opp.Site_Visit_Date__c) : 'TBD';
            String visitTimeStr = opp.Site_Visit_Time__c != null ? String.valueOf(opp.Site_Visit_Time__c) : 'TBD';

            emailBody = 'Dear ' + con.FirstName + ',\n\n'
                + 'We’re excited to confirm your site visit for ' + opp.Name + '. Here are the details:\n\n'
                + '📅 Date: ' + visitDateStr + '\n'
                + '⏰ Time: ' + visitTimeStr + '\n'
                + '📍 Location: SWEETHOMES \n\n'
                + 'Our team will be there to assist you and answer any questions you may have. '
                + 'If you need to reschedule, please let us know at thirdvizion@gmail.com or 6382734615.\n\n'
                + 'Looking forward to meeting you!\n\n'
                + 'Best Regards,\nSweetHome CRM Team\nSweetHomes\nthirdvizion@gmail.com or 6382734615';


        }else if (opp.StageName == 'New') {
            emailSubject = 'Welcome to SweetHomes – Your Journey Begins!';
            emailBody = 'Dear ' + con.FirstName + ',\n\n'
            + 'We are thrilled to welcome you to SweetHomes! We are excited to work with you on your property journey.\n\n'
            + 'Your opportunity details are as follows:\n'
            + 'Name: ' + opp.Name + '\n'
            + 'Stage: ' + opp.StageName + '\n'
            + 'Account Number: ' + con.Account_Number__c + '\n\n'
            + 'We will be in touch soon to discuss the next steps. If you have any questions contact us at thirdvizion@gmail.com or 6382734615.\n\n'
            + 'We look forward to working with you!\n\n'
            + 'please feel free to reach out.\n\n'
            + 'Best Regards,\nSweetHome CRM Team\nSweetHomes\nthirdvizion@gmail.com or 6382734615';
            

        }else if (opp.StageName == 'Advance Payment Received') {
            emailSubject = 'Payment Received – Thank You!';
            String amountPaid = opp.Advance_Amount__c != null ? String.valueOf(opp.Advance_Amount__c) : 'N/A';
            String paymentDate = opp.Advance_Payment_Date__c != null ? opp.Advance_Payment_Date__c.format() : 'N/A';
            emailBody = 'Dear ' + con.FirstName + ',\n\n'
                + 'We have successfully received your advance payment of [Amount] for ' + opp.Name + '. '
                + 'Thank you for your trust in SweetHomes.\n\n'
                + 'Here are your payment details:\n'
                + '💳 Amount Paid: ₹' + amountPaid + '\n'
                + '📅 Payment Date: ' + paymentDate + '\n'
                + 'Your next steps will be submitting the  document for verification sent these legal document through email to thirdvizion@gmail.com  '
                + 'If you have any questions, feel free to reach out.\n\n'
                + 'Best Regards,\nSweetHome CRM Team\nSweetHomes\nthirdvizion@gmail.com or 6382734615';

        } else if (opp.StageName == 'Legal Document Acquisition') {
            emailSubject = 'Important Update – Legal Documents Acquired';
            String documents = opp.Documents_Submitted__c != null ? opp.Documents_Submitted__c : 'No document details provided';
            emailBody = 'Dear ' + con.FirstName + ',\n\n'
                + 'We are pleased to inform you that the necessary legal documents for ' + opp.Name + ' have been successfully acquired.\n\n'
                + 'The documents include:\n'
                + documents + '\n\n'
                + 'Please let us know if you would like to review them or require any further clarifications. '
                + 'You can reach us at thirdvizion@gmail.com or 6382734615.\n\n'
                + 'Best Regards,\nSweetHome CRM Team\nSweetHomes\nthirdvizion@gmail.com or 6382734615';

        } else if (opp.StageName == 'Registration Slot Date Sent') {
            emailSubject = 'Your Property Registration Slot is Confirmed';
            String slotDate = opp.Registration_Date__c != null ? String.valueOf(opp.Registration_Date__c) : 'To Be Confirmed';
            String slotTime = 'To Be Confirmed';
            if (opp.Registration_Time__c != null) {
                Integer rawHour = opp.Registration_Time__c.hour();
                Integer hour12;
                if (rawHour == 0) {
                    hour12 = 12;
                } else if (rawHour > 12) {         
                    hour12 = rawHour - 12;
                } else {
                    hour12 = rawHour;
                }
                
                String ampm = rawHour >= 12 ? 'PM' : 'AM';
                Integer minute = opp.Registration_Time__c.minute();
                String minuteStr = minute < 10 ? '0' + minute : String.valueOf(minute);
                slotTime = hour12 + ':' + minuteStr + ' ' + ampm;
            }
            String location = opp.Registration_Office_Location__c != null ? opp.Registration_Office_Location__c : 'Registration Office Near your location';

            emailBody = 'Dear ' + con.FirstName + ',\n\n'
                + 'We are happy to inform you that your property registration slot has been scheduled. Here are the details:\n\n'
                + '📅 Date: ' + slotDate + '\n'
                + '⏰ Time: ' + slotTime + '\n'
                + '🏛 Location: ' + location + '\n\n'
                + 'Please ensure you carry all required documents. If you have any queries or need to reschedule, '
                + 'please contact us at thirdvizion@gmail.com or 6382734615.\n\n'
                + 'We look forward to completing this final step with you!\n\n'
                + 'Best Regards,\nSweetHome CRM Team\nSweetHomes\nthirdvizion@gmail.com or 6382734615';

        }else {
            // Default email if StageName does not match predefined cases
            emailSubject = 'Update on Your Property Opportunity';
            emailBody = 'Dear ' + con.FirstName + ',\n\n'
                + 'Your opportunity status has changed to: ' + opp.StageName + '.\n\n'
                +'We are pleased to inform you that your loan application with [Bank Name] has been successfully sanctioned.\n\n'
                + 'Here are the details:\n'
                +'Loan Amount: [₹X,XX,XXX]\n'
                +'Loan Account Number: [XXXXXXXXXXXX]\n\n'
                + 'Please contact us for more details.\n\n'
                + 'Best regards,\nSweetHome CRM Team \nSweetHomes\nthirdvizion@gmail.com or 6382734615';
                
        }

        // Prepare and add the email message
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{con.Email});
        mail.setSubject(emailSubject);
        mail.setPlainTextBody(emailBody);
        emails.add(mail);
        System.debug('Contact Email: ' + con.Email);

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
