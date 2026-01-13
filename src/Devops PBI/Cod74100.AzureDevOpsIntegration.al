codeunit 74100 "Azure DevOps Integration"
{
    var
        PATKeyLbl: Label 'AzureDevOpsPAT', Locked = true;
        InvalidPATErr: Label 'Invalid Personal Access Token. Please configure the PAT in the setup.';
        WorkItemNotFoundErr: Label 'Work Item %1 not found in Azure DevOps.', Comment = '%1 = Work Item ID';
        APICallFailedErr: Label 'Failed to retrieve Work Item from Azure DevOps. Status Code: %1', Comment = '%1 = HTTP Status Code';
        UnauthorizedErr: Label 'Unauthorized access to Azure DevOps. Please verify your Personal Access Token.';

    procedure FetchWorkItemDetails(var ReleaseWorkItem: Record "Released Work Items")
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        Url: Text;
    begin
        if ReleaseWorkItem."Work Item ID" = '' then
            exit;

        Url := StrSubstNo('https://dev.azure.com/Browns-ERP-BC/Browns-ERP-BC/_apis/wit/workitems/%1?api-version=7.2-preview.3',
            ReleaseWorkItem."Work Item ID");

        RequestMessage.Method := 'GET';
        RequestMessage.SetRequestUri(Url);
        AddAuthenticationHeader(RequestMessage);

        if not Client.Send(RequestMessage, ResponseMessage) then
            Error(APICallFailedErr, 'Connection Failed');

        if not ResponseMessage.IsSuccessStatusCode() then begin
            case ResponseMessage.HttpStatusCode() of
                401:
                    Error(UnauthorizedErr);
                404:
                    Error(WorkItemNotFoundErr, ReleaseWorkItem."Work Item ID");
                else
                    Error(APICallFailedErr, ResponseMessage.HttpStatusCode());
            end;
        end;

        ResponseMessage.Content().ReadAs(ResponseText);
        ParseWorkItemResponse(ResponseText, ReleaseWorkItem);
    end;

    local procedure AddAuthenticationHeader(var RequestMessage: HttpRequestMessage)
    var
        Headers: HttpHeaders;
        PAT: Text;
        AuthValue: Text;
    begin
        PAT := GetPAT();
        if PAT = '' then
            Error(InvalidPATErr);

        AuthValue := StrSubstNo('Basic %1', EncodeBase64(':' + PAT));

        RequestMessage.GetHeaders(Headers);
        Headers.Add('Authorization', AuthValue);
    end;

    local procedure ParseWorkItemResponse(ResponseText: Text; var ReleaseWorkItem: Record "Released Work Items")
    var
        JObject: JsonObject;
        JToken: JsonToken;
        JFields: JsonObject;
        Title: Text;
        CreatedBy: Text;
        Developer: Text;
        RequestedUser: Text;
        Company: Text;
        TempWorkItem: Record "Released Work Items";
    begin
        if not JObject.ReadFrom(ResponseText) then
            Error('Failed to parse JSON response from Azure DevOps.');

        if JObject.Get('fields', JToken) then begin
            JFields := JToken.AsObject();

            if JFields.Get('System.Title', JToken) then
                Title := JToken.AsValue().AsText();

            if JFields.Get('System.CreatedBy', JToken) then begin
                if JToken.IsObject() then begin
                    if JToken.AsObject().Get('displayName', JToken) then
                        CreatedBy := JToken.AsValue().AsText();
                end;
            end;
            if JFields.Get('System.AssignedTo', JToken) then begin
                if JToken.IsObject() then begin
                    if JToken.AsObject().Get('displayName', JToken) then
                        Developer := JToken.AsValue().AsText();
                end;
            end;

            if JFields.Get('Custom.RequestedBy', JToken) then begin
                RequestedUser := JToken.AsValue().AsText();
            end;

            if JFields.Get('System.AreaPath', JToken) then
                Company := JToken.AsValue().AsText();

            if Company <> '' then begin
                if Company = 'Browns-ERP-BC' then
                    Company := 'BROWNS'
                else if Company = 'AgStar' then
                    Company := 'AGSTAR'
                else if Company = 'Browns EV' then
                    Company := 'BROWNS EV';
            end

        end;
        ReleaseWorkItem."PBI description" := CopyStr(Title, 1, MaxStrLen(ReleaseWorkItem."PBI description"));
        ReleaseWorkItem."Created By User" := CopyStr(CreatedBy, 1, MaxStrLen(ReleaseWorkItem."Created By User"));
        ReleaseWorkItem."Assigned To" := CopyStr(Developer, 1, MaxStrLen(ReleaseWorkItem."Assigned To"));
        ReleaseWorkItem."Requested User" := CopyStr(RequestedUser, 1, MaxStrLen(ReleaseWorkItem."Requested User"));
        ReleaseWorkItem."Company" := CopyStr(Company, 1, MaxStrLen(ReleaseWorkItem."Company"));

        if TempWorkItem.Get(ReleaseWorkItem."Work Item ID", ReleaseWorkItem."Sprint No") then begin
            TempWorkItem."PBI description" := ReleaseWorkItem."PBI description";
            TempWorkItem."Created By User" := ReleaseWorkItem."Created By User";
            TempWorkItem."Assigned To" := ReleaseWorkItem."Assigned To";
            TempWorkItem."Requested User" := ReleaseWorkItem."Requested User";
            TempWorkItem."Company" := ReleaseWorkItem."Company";
            TempWorkItem.Modify();
        end;
    end;

    procedure SetPAT(PAT: Text)
    var
        AzureDevOpsSetup: Record "Azure DevOps Setup";
    begin
        if not AzureDevOpsSetup.GetSetup() then
            Error('Failed to initialize Azure DevOps Setup.');

        AzureDevOpsSetup."Personal Access Token" := CopyStr(PAT, 1, MaxStrLen(AzureDevOpsSetup."Personal Access Token"));
        AzureDevOpsSetup.Modify();
    end;

    procedure GetPAT(): Text
    var
        AzureDevOpsSetup: Record "Azure DevOps Setup";
    begin
        if AzureDevOpsSetup.GetSetup() then
            exit(AzureDevOpsSetup."Personal Access Token");
        exit('');
    end;

    local procedure EncodeBase64(InputText: Text): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(InputText);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        exit(Base64Convert.ToBase64(InStr));
    end;

    procedure SendEmail(var ReleasesAutomation: Record "Releases Automation")
    var
        EmailMessage: Codeunit "Email Message";
        Email: Codeunit Email;
        EmailAutomationRecipient: Record "Reciepts List";
        ReleaseItemWorks: Record "Released Work Items";
        CCList: List of [Text];
        BCCList: List of [Text];
        ToList: List of [Text];
        EmailAddress: Text;
        EmailBody: Text;
        EmailSubject: Text;
    begin
        if ReleasesAutomation.Subject = '' then
            Error('Email subject cannot be empty.');

        EmailAutomationRecipient.Reset();
        EmailAutomationRecipient.SetRange("Recipient Type", EmailAutomationRecipient."Recipient Type"::CC);
        if EmailAutomationRecipient.FindSet() then
            repeat
                if EmailAutomationRecipient.Email <> '' then
                    CCList.Add(EmailAutomationRecipient.Email);
            until EmailAutomationRecipient.Next() = 0;

        EmailAutomationRecipient.Reset();
        EmailAutomationRecipient.SetRange("Recipient Type", EmailAutomationRecipient."Recipient Type"::BCC);
        if EmailAutomationRecipient.FindSet() then
            repeat
                if EmailAutomationRecipient.Email <> '' then
                    BCCList.Add(EmailAutomationRecipient.Email);
            until EmailAutomationRecipient.Next() = 0;

        EmailAutomationRecipient.Reset();
        EmailAutomationRecipient.SetRange("Recipient Type", EmailAutomationRecipient."Recipient Type"::TOList);
        if EmailAutomationRecipient.FindSet() then
            repeat
                if EmailAutomationRecipient.Email <> '' then
                    ToList.Add(EmailAutomationRecipient.Email);
            until EmailAutomationRecipient.Next() = 0;

        EmailSubject := StrSubstNo(ReleasesAutomation.Subject);

        EmailBody := BuildEmailBodyHTML(ReleasesAutomation."Sprint No");

        EmailMessage.Create('', EmailSubject, EmailBody, true);

        foreach EmailAddress in ToList do
            EmailMessage.AddRecipient(Enum::"Email Recipient Type"::"To", EmailAddress);

        foreach EmailAddress in CCList do
            EmailMessage.AddRecipient(Enum::"Email Recipient Type"::Cc, EmailAddress);

        foreach EmailAddress in BCCList do
            EmailMessage.AddRecipient(Enum::"Email Recipient Type"::Bcc, EmailAddress);

        if not Email.Send(EmailMessage) then
            Error('Failed to send email. Please check your email configuration.');

        Message('Email sent successfully.');
    end;

    local procedure BuildEmailBodyHTML(SprintNo: Code[20]): Text
    var
        ReleaseItemWorks: Record "Released Work Items";
        EmailBody: Text;
        CurrentCompany: Text;
        CompanyList: List of [Text];
        Company: Text;
        HasItems: Boolean;

    begin
        EmailBody := '<!DOCTYPE html><html><head><meta charset="UTF-8"><style>';
        EmailBody += 'body{font-family:Calibri,Arial,"Segoe UI",sans-serif;font-size:15px;color:#333;margin:0;padding:20px;line-height:1.5;background-color:#ffffff;}';
        EmailBody += '.container{max-width:900px;margin:0 auto;background-color:#fff;padding:30px;}';
        EmailBody += 'p{margin:8px 0;padding:0;}';
        EmailBody += '.greeting{font-size:16px;font-weight:600;color:#2c3e50;margin-bottom:12px;}';
        EmailBody += '.intro{font-size:15px;color:#333;margin-bottom:20px;}';
        EmailBody += '.sprint-heading{text-align:center;font-size:18px;font-weight:bold;color:#1e3a8a;background:#e8f0fe;padding:14px;border:2px solid #1e3a8a;margin:15px 0 25px 0;}';
        EmailBody += '.company-heading{font-size:16px;font-weight:bold;color:#333;padding:10px 12px;margin:20px 0 5px 0;background-color:#F6F0D7;border-left:4px solid;text-transform:uppercase;}';
        EmailBody += '.browns-heading{border-left-color:#1e3a8a;}';
        EmailBody += '.agstar-heading{border-left-color:#1e3a8a;}';
        EmailBody += '.browns-ev-heading{border-left-color:#1e3a8a;}';
        EmailBody += '.ajax-heading{border-left-color:#1e3a8a;}';
        EmailBody += 'table{width:100%;border-collapse:collapse;margin:0 0 25px 0;}';
        EmailBody += 'th,td{border:1px solid #d1d5db;padding:10px;text-align:left;vertical-align:top;}';
        EmailBody += 'th{font-weight:600;font-size:15px;background-color:#f3f4f6;color:#1f2937;}';
        EmailBody += 'td{font-size:15px;background-color:#fff;color:#333;}';
        EmailBody += 'tr:nth-child(even) td{background-color:#f9fafb;}';
        EmailBody += '.footer{margin-top:30px;padding-top:20px;border-top:2px solid #e5e7eb;}';
        EmailBody += '.closing{font-size:15px;color:#333;font-style:italic;margin-bottom:15px;}';
        EmailBody += '.signature{font-size:16px;font-weight:600;color:#1e3a8a;margin-bottom:20px;}';
        EmailBody += '.logo-section{text-align:center;margin-top:25px;padding-top:20px;border-top:1px solid #e5e7eb;}';
        EmailBody += '.logo-img{max-width:250px;height:auto;margin:10px auto;display:block;}';
        EmailBody += '.contact-info{text-align:center;font-size:13px;color:#666;margin-top:15px;line-height:1.6;}';
        EmailBody += '</style></head><body><div class="container">';

        EmailBody += '<p class="greeting">Dear ERP Team,</p>';
        EmailBody += '<p class="intro">The following developments have been successfully deployed to the <strong>PRODUCTION</strong> environment.</p>';

        EmailBody += '<div class="sprint-heading">Sprint : ' + SprintNo + '</div>';

        ReleaseItemWorks.Reset();
        ReleaseItemWorks.SetRange("Sprint No", SprintNo);
        if ReleaseItemWorks.FindSet() then
            repeat
                if ReleaseItemWorks.Company <> '' then
                    if not CompanyList.Contains(ReleaseItemWorks.Company) then
                        CompanyList.Add(ReleaseItemWorks.Company);
            until ReleaseItemWorks.Next() = 0;

        foreach Company in CompanyList do begin
            if Company = 'BROWNS' then
                EmailBody += '<div class="company-heading browns-heading">' + Company + ' Production Release</div>'
            else if Company = 'AGSTAR' then
                EmailBody += '<div class="company-heading agstar-heading">' + Company + ' Production Release</div>'
            else if Company = 'BROWNS EV' then
                EmailBody += '<div class="company-heading browns-ev-heading">' + Company + ' Production Release</div>'
            else if Company = 'Ajax' then
                EmailBody += '<div class="company-heading ajax-heading">' + Company + ' Production Release</div>'
            else
                EmailBody += '<div class="company-heading browns-heading">' + Company + ' Production Release</div>';

            EmailBody += '<table><thead><tr>';
            EmailBody += '<th width="8%">ID</th>';
            EmailBody += '<th width="16%">Work Item Type</th>';
            EmailBody += '<th width="54%">Title</th>';
            EmailBody += '<th width="22%">Functional Consultant</th>';
            EmailBody += '</tr></thead><tbody>';

            ReleaseItemWorks.Reset();
            ReleaseItemWorks.SetRange("Sprint No", SprintNo);
            ReleaseItemWorks.SetRange(Company, Company);
            if ReleaseItemWorks.FindSet() then
                repeat
                    HasItems := true;
                    EmailBody += '<tr>';
                    EmailBody += '<td>' + Format(ReleaseItemWorks."Work Item ID") + '</td>';
                    EmailBody += '<td>User Story</td>';
                    EmailBody += '<td>' + ReleaseItemWorks."PBI description" + '</td>';
                    EmailBody += '<td>' + ReleaseItemWorks."Created By User" + '</td>';
                    EmailBody += '</tr>';
                until ReleaseItemWorks.Next() = 0;

            EmailBody += '</tbody></table>';
        end;

        EmailBody += '<div class="footer">';
        EmailBody += '<p class="closing">Thanks with best Regards!</p>';
        EmailBody += '<p class="signature">ERP Technical Team</p>';
        EmailBody += '</div>';

        EmailBody += '<div class="logo-section">';
        EmailBody += '<img src="https://www.brownsgroup.lk/images/site-specific/150-anniversary-celebrations/browns-150--logo.svg" alt="Browns Group" class="logo-img"/>';
        EmailBody += '<div class="contact-info">';
        EmailBody += '<p><strong>Brown & Company PLC - Digital Transformation Solutions</strong></p>';
        EmailBody += '<p>No. 34 Sir Mohamad Macan Markar Mawatha, Colombo 03.</p>';
        EmailBody += '<p>M +94 71 73 75 860 | E Nimsara@brownsgroup.com | T +94 11 50 63 000</p>';
        EmailBody += '<p>W <a href="https://www.brownsgroup.lk" style="color:#1e3a8a;text-decoration:none;">www.brownsgroup.lk</a></p>';
        EmailBody += '</div>';
        EmailBody += '</div>';

        EmailBody += '</div></body></html>';

        exit(EmailBody);
    end;

    procedure TestConnection(): Boolean
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Url: Text;
    begin
        Url := 'https://dev.azure.com/Browns-ERP-BC/_apis/projects?api-version=7.2-preview.4';

        RequestMessage.Method := 'GET';
        RequestMessage.SetRequestUri(Url);
        AddAuthenticationHeader(RequestMessage);

        if not Client.Send(RequestMessage, ResponseMessage) then
            exit(false);

        exit(ResponseMessage.IsSuccessStatusCode());
    end;

}
