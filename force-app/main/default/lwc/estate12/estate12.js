import { LightningElement, track } from 'lwc';
import createLead from '@salesforce/apex/LeadController.createLead';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 

export default class Estate1 extends LightningElement {
    @track formData = {
        firstName: '',
        lastName: '',
        phone: '',
        email: '',
        apartmentType: '',
        budget: ''
    };

    apartmentOptions = [
        { label: 'A', value: 'A' },
        { label: 'B', value: 'B' },
        { label: 'C', value: 'C' },
        { label: 'D', value: 'D' }
    ];
    
    handleChange(event) {
        this.formData[event.target.name] = event.target.value;
    }

    handleSubmit() {
        createLead({
            firstName: this.formData.firstName,
            lastName: this.formData.lastName,
            phone: this.formData.phone,
            email: this.formData.email,
            apartmentType: this.formData.apartmentType,
            budget: parseFloat(this.formData.budget) || 0
        })
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Lead created successfully! Email will be sent shortly.',
                    variant: 'success'
                })
            );
            this.clearForm();
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Lead creation failed: ' + (error.body ? error.body.message : error.message),
                    variant: 'error'
                })
            );
            console.error('Error:', error);
        });
    }

    clearForm() {
        this.formData = {
            firstName: '',
            lastName: '',
            phone: '',
            email: '',
            apartmentType: '',
            budget: ''
        };
    }
}
