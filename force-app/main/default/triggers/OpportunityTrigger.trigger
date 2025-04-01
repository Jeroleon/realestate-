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

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{con.Email});
                mail.setSubject(opp.StageName);
                mail.setPlainTextBody(
                    'Dear ' + con.FirstName + ',\n\n'
                    + 'Your opportunity status has changed to: ' + opp.StageName + '.\n\n'
                    + 'Please contact us for more details.\n\nBest regards,\nSweetHome CRM Team'
                );

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
