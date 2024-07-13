public with sharing class CopilotContactOverview {
    @InvocableMethod(label='Contact Overview' description='Returns a contact summary and a list of open cases and opportunities')
    public static List<Response> createContactOverview(List<Request> input)
    {
        Integer days=input[0].numberOfDays;
        
        Contact cont=input[0].contact;
        Contact contFromDB=[select id, Name from Contact where id=:cont.Id];

        List<OpportunityContactRole> oppContactRoles=[select id, Contact.Id, Role, Opportunity.Id 
                                                      from OpportunityContactRole
                                                      where Contact.Id=:cont.Id];

        Set<Id> oppIds=new Set<Id>();
        for (OpportunityContactRole ocr : oppContactRoles)
        {
            oppIds.add(ocr.Opportunity.Id);
        }

        Date daysCutoff=System.today().addDays(-days);
        Date yearCutoff=System.today().addYears(-1);
        Decimal daysTotal=0.0;
        Decimal yearTotal=0.0;
        Decimal lifetimeTotal=0.0;

        // find the closed opportunities anmd group into 
        for (Opportunity opp : [select Id, CloseDate, ConvertCurrency(Amount) currAmt 
                                from Opportunity 
                                where IsClosed=true
                                and id in:oppIds
                                order by CloseDate desc])
        {
            Decimal amount=(Decimal) opp.get('currAmt');
            if (opp.CloseDate>=daysCutoff)
            {
                daysTotal+=amount;
            }

            if (opp.CloseDate>=yearCutoff)
            {
                yearTotal+=amount;
            }

            lifetimeTotal+=amount;
        }

        List<Response> result=new List<Response>();
        
        Response response=new Response();
        result.add(response);

        String ccyCode=UserInfo.getDefaultCurrency();

        response.aSpendSummary='The value of ' + contFromDB.Name + ' to our business is :\n' +
                       'Last ' + days + ' days : ' + ccyCode + ' ' + formatCurrency(daysTotal) + '\n' + 
                       'Last year : ' + ccyCode + ' ' + formatCurrency(yearTotal) + '\n' + 
                       'Lifetime : ' + ccyCode + ' ' + formatCurrency(lifetimeTotal); 

        // get up to 5 highest value open opps
        List<Opportunity> topOpps=[select Id, CloseDate, Amount, StageName
                             from Opportunity 
                             where IsClosed=false
                               and id in:oppIds
                             order by Amount desc
                             limit 5];
        
        response.opps.commentary='Here are the highest value open opportunities';
        response.opps.records=topOpps;

        // get up to 5 recent open cases
        List<Case> recentCases=[select Id, CreatedDate, Subject 
                             from Case 
                             where IsClosed=false
                               and ContactId=:cont.Id
                             order by CreatedDate desc
                             limit 5];

        response.cases.commentary='Here are the most recent open cases';
        response.cases.records=recentCases;

        return result;
    }

    private static String formatCurrency(Decimal value) {
	    if (value == null) 
            return '0.00';
        
    	value = Decimal.valueOf(Math.roundToLong(value * 100)) / 100;
	    String formatted = (value.setScale(2) + (value >= 0 ? 0.001 : -0.001)).format();
    	return formatted.substring(0, formatted.length() - 1);
	}


    public class Response
    {
        @InvocableVariable
        public String aSpendSummary;

        @InvocableVariable
        public RecsWrapper cases;

        @InvocableVariable
        public RecsWrapper opps;

        public Response()
        {
            cases=new RecsWrapper();
            opps=new RecsWrapper();
        }
    }    

    public class RecsWrapper
    {
        @InvocableVariable
        public String commentary;

        @InvocableVariable
        public List<SObject> records;
    }

    public class Request 
    {
        @InvocableVariable(label='Contact' description='The contact to create the summary for')
        public Contact contact;

        @InvocableVariable(label='Number of Days' description='The numnber of days to look back and calculate the account spend')
        public Integer numberOfDays;
    }

}