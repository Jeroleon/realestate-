public with sharing class LeadController {
    @AuraEnabled
    public static Id createLead(String firstName, String lastName, String phone, String email, String apartmentType, Decimal budget) {
        try {
            // Validate required fields
            if (String.isBlank(firstName) || String.isBlank(lastName) || String.isBlank(email)) {
                throw new AuraHandledException('First Name, Last Name, and Email are required.');
            }

            // Create the Lead record
            Lead newLead = new Lead(
                FirstName = firstName,
                LastName = lastName,
                Phone = phone,
                Email = email,
                Company = 'Individual',  
                Status = 'Open - Not Contacted',
                SweetHome_Lead_Status__c = 'New',  // Check API Name
                Desired_Apartment_Type__c = apartmentType,  // Check API Name
                Budget__c = budget  // Check API Name
            );

            insert newLead;
            return newLead.Id;

        } catch (DmlException e) {
            System.debug('DML Exception: ' + e.getMessage()); // Add debug log
            throw new AuraHandledException('Lead creation failed: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage()); // Add debug log
            throw new AuraHandledException('Lead creation failed: ' + e.getMessage());
        }
    }
}
