public with sharing class CopilotCreateLeadFromJSON
{
    @InvocableMethod(label='Create Lead From JSON' description='Creates a lead record from a JSON string')
    public static List<LeadWrapper> createLeadFromJSON(List<String> leadsJSON) {

        JSONParser parser=JSON.createParser(leadsJSON[0]);
        Map<String, String> params=new Map<String, String>();

        while (null!=parser.nextToken()) 
        {
            if (JSONToken.FIELD_NAME==parser.getCurrentToken())
            {
                String name=parser.getText();
                parser.nextToken();
                String value=parser.getText();
                params.put(name, value);
            }
        }

        Lead lead=new Lead(FirstName=params.get('firstName'),
                           LastName=params.get('lastName'),
                           Description=params.get('description'),
                           Company=params.get('company'),
                           Title=params.get('role'),
                           Phone=params.get('phone'),
                           Email=params.get('email'),
                           OwnerId=UserInfo.getUserId());

        insert lead;

        LeadWrapper result=new LeadWrapper(lead, 
                                          'Here is the new lead - get out there and convert them!');

        return new List<LeadWrapper>{result};
    }

    public class LeadWrapper
    {
        @InvocableVariable
        public Lead lead;

        @InvocableVariable
        public String aMessage;

        public LeadWrapper(Lead lead, String message)
        {
            this.lead=lead;
            this.aMessage=message;
        }
    }
}