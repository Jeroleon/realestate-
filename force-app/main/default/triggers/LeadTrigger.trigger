trigger LeadTrigger on Lead (after update) {
    Map<Id, Account> accountMap = new Map<Id, Account>();
    Map<Id, Lead> leadMap = new Map<Id, Lead>();

    // Sets for duplicate checking
    Set<String> phoneNumbers = new Set<String>();
    Set<String> leadEmails = new Set<String>();

    // Identify Leads where status changed to "Converted"
    for (Lead lead : Trigger.new) {
        Lead oldLead = Trigger.oldMap.get(lead.Id);

        if (lead.Status == 'Closed - Converted' && oldLead.Status != 'Closed - Converted') {
            phoneNumbers.add(lead.Phone);
            leadEmails.add(lead.Email);
            leadMap.put(lead.Id, lead);
        }
    }

    if (leadMap.isEmpty()) {
        System.debug('No Leads to process for conversion.');
        return;
    }

    // Query existing Accounts and Contacts to prevent duplicates
    Map<String, Account> existingAccounts = new Map<String, Account>();
    Map<String, Contact> existingContacts = new Map<String, Contact>();

    if (!phoneNumbers.isEmpty()) {
        for (Account acc : [SELECT Id, Phone FROM Account WHERE Phone IN :phoneNumbers]) {
            existingAccounts.put(acc.Phone, acc);
        }

        for (Contact con : [SELECT Id, Phone, Email FROM Contact WHERE Phone IN :phoneNumbers OR Email IN :leadEmails]) {
            existingContacts.put(con.Phone, con);
        }
    }

    // Create new Accounts if they don’t exist
    for (Id leadId : leadMap.keySet()) {
        Lead lead = leadMap.get(leadId);

        Account acc;
        if (existingAccounts.containsKey(lead.Phone)) {
            acc = existingAccounts.get(lead.Phone);
            System.debug('Existing Account Found: ' + acc.Id);
        } else {
            // Extract last 8 digits of phone for Account Number
            String accNumber = (lead.Phone != null && lead.Phone.length() >= 8) 
                ? lead.Phone.right(8) 
                : '00000000';

            acc = new Account(
                Name = lead.LastName + ' Family',
                Phone = lead.Phone,
                AccountNumber = accNumber
            );
            accountMap.put(lead.Id, acc);
        }
    }

    if (!accountMap.isEmpty()) {
        insert accountMap.values();
    }

    // ✅ NEW CODE: Query existing Opportunities for inserted Accounts
    Set<Id> insertedAccountIds = new Set<Id>();
    for (Account a : accountMap.values()) {
        insertedAccountIds.add(a.Id);
    }

    Set<Id> accountsWithOpportunities = new Set<Id>();
    if (!insertedAccountIds.isEmpty()) {
        for (Opportunity o : [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :insertedAccountIds]) {
            accountsWithOpportunities.add(o.AccountId);
        }
    }

    // Create Contacts & Opportunities
    List<Contact> contactsToInsert = new List<Contact>();
    List<Opportunity> opportunitiesToInsert = new List<Opportunity>();

    for (Id leadId : accountMap.keySet()) {
        Account acc = accountMap.get(leadId);
        Lead lead = leadMap.get(leadId);

        Contact con;
        if (existingContacts.containsKey(lead.Phone)) {
            con = existingContacts.get(lead.Phone);
            System.debug('Existing Contact Found: ' + con.Id);
        } else {
            con = new Contact(
                FirstName = lead.FirstName,
                LastName = lead.LastName,
                Phone = lead.Phone,
                Email = lead.Email,
                AccountId = acc.Id
            );
            contactsToInsert.add(con);
        }

        // ✅ UPDATED: Only create Opportunity if one doesn't already exist
        if (!accountsWithOpportunities.contains(acc.Id)) {
            String aptType = lead.Desired_Apartment_Type__c != null ? lead.Desired_Apartment_Type__c : 'General';
            Opportunity opp = new Opportunity(
                Name = lead.LastName + ' ' + aptType,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                AccountId = acc.Id
            );
            opportunitiesToInsert.add(opp);
        } else {
            System.debug('Skipping Opportunity creation for Account: ' + acc.Id + ' (Already exists)');
        }
    }

    if (!contactsToInsert.isEmpty()) {
        insert contactsToInsert;
    }
    if (!opportunitiesToInsert.isEmpty()) {
        insert opportunitiesToInsert;
    }

    // Send email notification after successful Lead conversion
    if (!leadMap.isEmpty()) {
        try {
            LeadNotificationService.sendLeadConversionEmails(leadMap.values());
            System.debug('Lead conversion emails sent successfully.');
        } catch (Exception e) {
            System.debug('Error sending lead conversion emails: ' + e.getMessage());
        }
    }

    System.debug('Lead Conversion Process Completed Successfully.');
}
