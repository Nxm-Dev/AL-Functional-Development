page 74100 "Generate Web Token"
{
    ApplicationArea = All;
    Caption = 'Access Credential';
    PageType = Card;
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Token';
                field(Token; Token)
                {
                    ApplicationArea = All;
                    Caption = 'Token';
                    ToolTip = 'Token to be used for the API call.';
                    ShowMandatory = true;
                    RowSpan = 20;
                    MultiLine = true;
                    Editable = false;
                }

            }
        }
    }

    actions
    {
        area(Promoted)
        {
            actionref(AskMrBC; "Request Token") { }
        }
        area(Processing)
        {
            action("Request Token")
            {
                ApplicationArea = All;
                Caption = 'Request Token';
                ToolTip = 'Request a token from Mr.BC.';
                Image = LinkWeb;
                ShortcutKey = 'Ctrl+R';

                trigger OnAction()
                begin
                    PostToken := GenerateAToken('ERPUser@brownsgroup.com', 'ERp@123#');
                    AuthToken := GetAuthKey(PostToken);
                    if AuthToken = '' then
                        Error('Failed to get Auth Token.')
                    else
                        Message('Auth Token Generated');
                    Token := AuthToken;
                end;
            }
        }
    }

    procedure GenerateAToken(UserName: Text[250]; Password: Text[250]): Text
    var
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;
        HttpResponse: HttpResponseMessage;
        RequestBody: Text;
        ResponseBody: Text;
        JsonToken: JsonToken;
        JsonObject: JsonObject;
        ErrorMessage: Text;
    begin
        HttpClient.Clear();
        RequestBody := StrSubstNo(
            '{ "username": "%1", "password": "%2" }',
            UserName,
            Password
        );

        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Clear();
        HttpHeaders.Add('Content-Type', 'application/json');

        if not HttpClient.Post(
            StrSubstNo('https://vehicle-mgt-dev-api.azurewebsites.net/api/v2/security/is-authorization'),
            HttpContent,
            HttpResponse)
        then
            Error('Failed to connect to API.');

        if not HttpResponse.IsSuccessStatusCode() then begin
            ErrorMessage := GetErrorMessage(ResponseBody);
            if ErrorMessage <> '' then
                Error('API error: %1 - %2 - %3', HttpResponse.HttpStatusCode(), HttpResponse.ReasonPhrase(), ErrorMessage)
            else
                Error('API error: %1 - %2', HttpResponse.HttpStatusCode(), HttpResponse.ReasonPhrase());
        end;

        if not HttpResponse.Content.ReadAs(ResponseBody) then
            Error('Failed to read response content.');

        exit(GetPostToken(ResponseBody));
    end;

    local procedure GetAuthKey(JsonResponse: Text) AuthKeyText: Text
    var
        HttpClient: HttpClient;
        HttpHeaders: HttpHeaders;
        HttpResponse: HttpResponseMessage;
    begin
        HttpClient.Clear();
        HttpClient.DefaultRequestHeaders().Add('Authorization', 'Bearer ' + JsonResponse);

        if not HttpClient.Get(
            StrSubstNo('https://vehicle-mgt-dev-api.azurewebsites.net/api/v2/ERPToken/GetAccessToken'),
            HttpResponse)
        then
            Error('Failed to connect to API.');

        if not HttpResponse.IsSuccessStatusCode() then
            Error('API error: %1 - %2', HttpResponse.HttpStatusCode(), HttpResponse.ReasonPhrase());
        if not HttpResponse.Content.ReadAs(AuthKeyText) then
            Error('Failed to read response content.');

        exit(GetAuthToken(AuthKeyText));
    end;

    local procedure GetPostToken(JsonResponse: Text) TokenText: Text
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
    begin
        if not JsonObject.ReadFrom(JsonResponse) then
            Error('Failed to parse JSON response.');

        JsonObject.SelectToken('result.token', JsonToken);
        TokenText := JsonToken.AsValue().AsText();
        exit(TokenText);
    end;

    local procedure GetAuthToken(JsonResponse: Text) AuthTokenText: Text
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
    begin
        if not JsonObject.ReadFrom(JsonResponse) then
            Error('Failed to parse JSON response.');

        JsonObject.SelectToken('result', JsonToken);
        AuthTokenText := JsonToken.AsValue().AsText();
        exit(AuthTokenText);
    end;

    local procedure GetErrorMessage(JsonResponse: Text) ErrorMsg: Text
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
    begin
        if not JsonObject.ReadFrom(JsonResponse) then
            exit('');

        if JsonObject.SelectToken('msg', JsonToken) then
            ErrorMsg := JsonToken.AsValue().AsText();

        exit(ErrorMsg);
    end;

    trigger OnOpenPage()
    var
        Dialog: Dialog;
    begin
        Dialog.Open('Generating Token, please wait...');
        PostToken := GenerateAToken('ERPUser@brownsgroup.com', 'ERp@123#');
        AuthToken := GetAuthKey(PostToken);
        if AuthToken = '' then
            Error('Failed to get Auth Token.')
        else
            Message('Auth Token Generated');
        Token := AuthToken;
        Dialog.Close();
    end;

    var
        Token: Text;
        AuthToken: Text;
        PostToken: Text;
}