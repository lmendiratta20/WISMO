/**
* @File Name : sendEmail.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 13, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 13, 2025 |   | Initial Version
**/

public class sendEmail {		
	
	
	public class Request {
	    @InvocableVariable(required=true label='User Question')
	    public String userQuestion;
	}
	public class Result {
	    @InvocableVariable
	    public String caseNumber;
	    @InvocableVariable
	    public Boolean emailSent;
	    @InvocableVariable
	    public String errorMessage;
		}
	public static final String ORG_WIDE_EMAIL_ADDRESS = 'lakshey.mendiratta@lirik.io';
	
	public static String getEmail() {
		System.debug('mail -> '+Cache.Org.get('userMail'));
        return (String) Cache.Org.get('userMail');
    }
	public static String userEmail = getEmail();
	@InvocableMethod(label='Create Case and Send Email')
	public static List<Result> createCaseAndEmail(List<Request> requests) {
	    List<Result> outcomes = new List<Result>();
		    Id orgWideEmailId = null;
     	try {
     	    OrgWideEmailAddress owea = [
     	        SELECT Id
     	        FROM OrgWideEmailAddress
     	        WHERE Address = :ORG_WIDE_EMAIL_ADDRESS
     	        LIMIT 1
     	    ];
     	    orgWideEmailId = owea.Id;
     	} catch (Exception e) {
     	    System.debug('Org-Wide Email Address not found for ' + ORG_WIDE_EMAIL_ADDRESS + ': ' + e.getMessage());
     	}
	    for (Request req : requests) {
	        Result r = new Result();
	        outcomes.add(r);
	        try {
	            Case c = new Case();
	            c.Origin = 'Web';
	            c.Status = 'New';
	            c.Subject = 'Your Question Has Been Escalated to Our Support Team';
	            c.Description = req.userQuestion;
	            c.Reason = userEmail;
	            insert c;
	            c = [SELECT Id, CaseNumber, CreatedDate FROM Case WHERE Id = :c.Id LIMIT 1];
	            r.caseNumber = c.CaseNumber;
	            String createdOn = c.CreatedDate.format('M/d/yyyy, h:mm a', UserInfo.getTimeZone().getID());
	            String body =
				'Hello,' + '\n\n' +
				'Thank you for your recent inquiry. While our virtual assistant couldn’t directly address your question, we’ve created a support case so our team can review it in detail and provide you with the right information.' + '\n\n' +
				'Case Details:' + '\n\n' +
				'Case Number: ' + c.CaseNumber + '\n' +
				'Created On: ' + createdOn + '\n' +
				'Your Question: ' + (req.userQuestion == null ? '' : req.userQuestion) + '\n' +
				'A member of our team will reach out to you shortly with an update. We appreciate your patience and look forward to assisting you.' + '\n\n' +
				'Best regards,' + '\n\n' +
				'AI Assistant System';
	            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	            mail.setToAddresses(new String[] {userEmail});
	            mail.setSubject('We created a support case for your question');
	            mail.setPlainTextBody(body);
	             if (orgWideEmailId != null) {
                 	mail.setOrgWideEmailAddressId(orgWideEmailId);
             	}
	            Messaging.SendEmailResult[] res = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }, false);
	            r.emailSent = res.size() > 0 && res[0].isSuccess();
	            if (!r.emailSent) {
	                r.errorMessage = (res.size() > 0 && res[0].getErrors().size() > 0) ? res[0].getErrors()[0].getMessage() : 'Unknown email error';
	            }
	        } catch (Exception e) {
	            r.emailSent = false;
	            r.errorMessage = e.getMessage();
	        }
	    }
	    return outcomes;
	 }

}