// ============================================================
//  Codeunit 74114 - HK News API Integration Mgt.
//  Handles the HTTP POST call to the Helakuru Esana endpoint,
//  validates the response, and delegates parsing to Codeunit
//  74115 HK News JSON Parser.
//
//  403 FIX — ROOT CAUSE & SOLUTION:
//  The Helakuru /esana/load endpoint is protected by two layers:
//
//    A) Cloudflare WAF — blocks HTTP clients whose TLS/HTTP2
//       fingerprint does not match a real browser.  However,
//       BC's HttpClient is accepted for same-session GET+POST
//       when proper headers are set.
//
//    B) CodeIgniter CSRF double-submit — the POST body must
//       include a CSRF token that matches the session cookie.
//       The token name and hash are embedded in the HTML of
//       the /esana page as JavaScript variables:
//           var csrfName = 'csrf';
//           var csrfHash = '<32-char hex>';
//       The cookie name is "esp-ak" and its value equals csrfHash.
//
//  Algorithm:
//    1. GET https://www.helakuru.lk/esana  (harvests esp-ak cookie
//       and extracts csrfName + csrfHash from the HTML body).
//    2. POST to /esana/load with the CSRF token in the form body:
//           newsLimit=10&esanaWidget=false&csrf=<hash>&category=
//       The esp-ak cookie from step 1 is manually extracted from
//       Set-Cookie and set as a Cookie header (BC's HttpClient
//       has no automatic cookie jar).
//
//  This codeunit is also the target for the Job Queue Entry.
// ============================================================
codeunit 74114 "HK News API Integration Mgt."
{
    // ----------------------------------------------------------
    //  Job Queue Entry entry point
    //  BC calls this procedure when the job is triggered.
    // ----------------------------------------------------------
    trigger OnRun()
    begin
        FetchAndStoreNews();
    end;

    // ----------------------------------------------------------
    //  Main orchestration procedure (can also be called manually)
    // ----------------------------------------------------------
    procedure FetchAndStoreNews()
    var
        Setup: Record "HK News API Setup";
        ResponseBody: Text;
        FirstNewsID: Integer;
        ParsedCount: Integer;
        Parser: Codeunit "HK News JSON Parser";
    begin
        Setup.GetOrCreate(Setup);

        if not Setup."Enabled" then begin
            Message('News API fetch is disabled in setup. Enable it via HK News API Setup.');
            exit;
        end;

        // 1. Call the API (two-step: GET page → POST endpoint)
        if not CallAPI(Setup, ResponseBody, FirstNewsID) then
            exit; // Error already logged

        // 2. Parse JSON and upsert records
        ParsedCount := Parser.ParseAndStore(ResponseBody, FirstNewsID);

        // 3. Update setup with last fetch info
        Setup."Last Fetch DateTime" := CurrentDateTime();
        Setup."Last FIRST_NEWS_ID" := FirstNewsID;
        Setup.Modify(true);

        // 4. Notify (only shows in foreground calls; silent in Job Queue)
        if GuiAllowed() then
            Message('News sync complete. %1 new article(s) inserted.', ParsedCount);
    end;

    // ----------------------------------------------------------
    //  Two-step HTTP call to the Helakuru endpoint.
    //
    //  Step 1 — GET /esana page:
    //    • The server returns an HTML page containing:
    //        var csrfName = 'csrf';
    //        var csrfHash = '<hex token>';
    //    • The response also sets the "esp-ak" session cookie
    //      (whose value equals csrfHash) via Set-Cookie.
    //    • We manually extract the cookie and replay it on
    //      the POST request (BC has no automatic cookie jar).
    //
    //  Step 2 — POST /esana/load:
    //    • Body params:  newsLimit, esanaWidget, csrf=<hash>,
    //      category  (matching the JavaScript in esena-apis.js).
    //    • The esp-ak cookie is manually set via Cookie header.
    //
    //  Returns TRUE on success, FALSE on failure.
    //  Outputs the raw JSON body and FIRST_NEWS_ID.
    // ----------------------------------------------------------
    local procedure CallAPI(var Setup: Record "HK News API Setup"; var ResponseBody: Text; var FirstNewsID: Integer): Boolean
    var
        HttpClient: HttpClient;
        // ---- Step 1 vars ----
        PreflightRequest: HttpRequestMessage;
        PreflightResponse: HttpResponseMessage;
        PreflightHeaders: HttpHeaders;
        PageHtml: Text;
        CsrfName: Text;
        CsrfHash: Text;
        SessionCookie: Text;
        // ---- Step 2 vars ----
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        ContentHeaders: HttpHeaders;
        HttpContent: HttpContent;
        PostBody: Text;
        JObject: JsonObject;
        JToken: JsonToken;
        StatusToken: JsonToken;
        ErrorBody: Text;
    begin
        // ---- Shared timeout for both steps ----
        HttpClient.Timeout := Setup."Request Timeout Sec" * 1000;

        // ==============================================================
        //  STEP 1 — Preflight GET to /esana page
        //           Harvests the CSRF token + session cookie
        // ==============================================================
        PreflightRequest.Method := 'GET';
        PreflightRequest.SetRequestUri('https://www.helakuru.lk/esana');
        PreflightRequest.GetHeaders(PreflightHeaders);

        SetHeader(PreflightHeaders, 'accept',
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8');
        SetHeader(PreflightHeaders, 'accept-language', 'en-US,en;q=0.9');
        SetHeader(PreflightHeaders, 'cache-control', 'no-cache');
        SetHeader(PreflightHeaders, 'user-agent',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) ' +
            'AppleWebKit/537.36 (KHTML, like Gecko) ' +
            'Chrome/146.0.0.0 Safari/537.36');

        if not HttpClient.Send(PreflightRequest, PreflightResponse) then begin
            LogError('Preflight GET to /esana failed (network error). ' +
                     'Check DNS and outbound HTTPS connectivity.');
            exit(false);
        end;

        if not PreflightResponse.IsSuccessStatusCode() then begin
            LogError(StrSubstNo(
                'Preflight GET to /esana returned HTTP %1. The site may be down.',
                PreflightResponse.HttpStatusCode));
            exit(false);
        end;

        // Read the full HTML page
        PreflightResponse.Content.ReadAs(PageHtml);

        // Extract csrfName and csrfHash from the inline <script> block:
        //   var csrfName = 'csrf';
        //   var csrfHash = 'ff56ffca2f95cccfc025676f58154fff';
        if not ExtractCsrfFromHtml(PageHtml, CsrfName, CsrfHash) then begin
            LogError('Could not extract CSRF token from the /esana page HTML. ' +
                     'The page structure may have changed. ' +
                     'First 300 chars of page: ' + CopyStr(PageHtml, 1, 300));
            exit(false);
        end;

        // IMPORTANT: BC's HttpClient does NOT have a cookie jar.
        // We must manually extract the Set-Cookie from the preflight
        // response and explicitly set it on the POST request.
        // The esp-ak cookie value always equals the csrfHash.
        SessionCookie := ExtractCookiesFromResponse(PreflightResponse);
        if SessionCookie = '' then
            // Fallback: build the cookie from the CSRF hash
            SessionCookie := 'esp-ak=' + CsrfHash;

        // Persist for diagnostic purposes
        Setup."Cookie Value" := CopyStr(SessionCookie, 1, MaxStrLen(Setup."Cookie Value"));
        if Setup.Modify(false) then; // best-effort

        // ==============================================================
        //  STEP 2 — POST to /esana/load
        //           Cookie must be set EXPLICITLY (no auto-forwarding)
        // ==============================================================

        // ---- Build POST body with correct parameter names ----
        PostBody := BuildPostBody(Setup, CsrfName, CsrfHash);

        // ---- Set Content ----
        HttpContent.WriteFrom(PostBody);
        HttpContent.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');

        // ---- Build Request ----
        HttpRequest.Method := 'POST';
        HttpRequest.SetRequestUri(Setup."Endpoint URL");
        HttpRequest.Content := HttpContent;

        // ---- Set Request Headers (including Cookie) ----
        HttpRequest.GetHeaders(RequestHeaders);
        SetRequestHeaders(RequestHeaders, Setup, SessionCookie);

        // ---- Send ----
        if not HttpClient.Send(HttpRequest, HttpResponse) then begin
            LogError('HTTP POST send failed for URL: ' + Setup."Endpoint URL");
            exit(false);
        end;

        // ---- Check HTTP Status ----
        if not HttpResponse.IsSuccessStatusCode() then begin
            HttpResponse.Content.ReadAs(ErrorBody);
            LogError(
                StrSubstNo('HTTP %1 received from /esana/load. ' +
                           'CSRF name=%2, hash=%3 (first 8 chars). ' +
                           'URL: %4. ' +
                           'Hint: The CSRF token or session cookie may have expired. ' +
                           'Response body: %5',
                    HttpResponse.HttpStatusCode,
                    CsrfName,
                    CopyStr(CsrfHash, 1, 8),
                    Setup."Endpoint URL",
                    CopyStr(ErrorBody, 1, 500)));
            exit(false);
        end;

        // ---- Read body ----
        HttpResponse.Content.ReadAs(ResponseBody);

        if ResponseBody = '' then begin
            LogError('Empty response body received from API.');
            exit(false);
        end;

        // ---- Validate STATUS: true ----
        if not JObject.ReadFrom(ResponseBody) then begin
            LogError('Response body is not valid JSON. First 200 chars: ' +
                     CopyStr(ResponseBody, 1, 200));
            exit(false);
        end;

        if JObject.Get('STATUS', StatusToken) then
            if not StatusToken.AsValue().AsBoolean() then begin
                LogError('API returned STATUS: false. No news data available.');
                exit(false);
            end;

        // ---- Extract FIRST_NEWS_ID ----
        if JObject.Get('FIRST_NEWS_ID', JToken) then
            FirstNewsID := JToken.AsValue().AsInteger();

        exit(true);
    end;

    // ----------------------------------------------------------
    //  Extract the CSRF token name and hash from the Esana
    //  page HTML.  The page contains an inline <script> block:
    //
    //    var csrfName = 'csrf';
    //    var csrfHash = 'ff56ffca2f95cccfc025676f58154fff';
    //
    //  We use simple string searching (no Regex in AL) to
    //  locate these values.
    // ----------------------------------------------------------
    local procedure ExtractCsrfFromHtml(PageHtml: Text; var CsrfName: Text; var CsrfHash: Text): Boolean
    var
        NameMarker: Text;
        HashMarker: Text;
        StartPos: Integer;
        EndPos: Integer;
    begin
        // ---- Extract csrfName ----
        NameMarker := 'var csrfName = ''';
        StartPos := StrPos(PageHtml, NameMarker);
        if StartPos = 0 then
            exit(false);

        StartPos += StrLen(NameMarker);
        EndPos := StrPos(CopyStr(PageHtml, StartPos), '''');
        if EndPos = 0 then
            exit(false);

        CsrfName := CopyStr(PageHtml, StartPos, EndPos - 1);

        // ---- Extract csrfHash ----
        HashMarker := 'var csrfHash = ''';
        StartPos := StrPos(PageHtml, HashMarker);
        if StartPos = 0 then
            exit(false);

        StartPos += StrLen(HashMarker);
        EndPos := StrPos(CopyStr(PageHtml, StartPos), '''');
        if EndPos = 0 then
            exit(false);

        CsrfHash := CopyStr(PageHtml, StartPos, EndPos - 1);

        // Basic sanity: csrfHash should be a 32-char hex string
        if StrLen(CsrfHash) < 16 then
            exit(false);

        exit(true);
    end;

    // ----------------------------------------------------------
    //  Reads Set-Cookie headers from the HTTP response and
    //  builds a single Cookie: header value string.
    //  e.g.  "esp-ak=abc123; _ga=GA1.2.xxx"
    //
    //  BC's HttpClient does NOT have a cookie jar, so we must
    //  manually extract cookies and replay them on subsequent
    //  requests.
    // ----------------------------------------------------------
    local procedure ExtractCookiesFromResponse(HttpResponse: HttpResponseMessage): Text
    var
        ResponseHeaders: HttpHeaders;
        CookieParts: List of [Text];
        CookieLine: Text;
        CookieResult: Text;
        PairText: Text;
        SemiPos: Integer;
    begin
        ResponseHeaders := HttpResponse.Headers();

        // Try to read Set-Cookie header values
        if not ResponseHeaders.GetValues('Set-Cookie', CookieParts) then
            exit('');

        foreach CookieLine in CookieParts do begin
            // Each Set-Cookie line: name=value; Path=/; HttpOnly; ...
            // We only want the name=value part (before the first ;)
            SemiPos := StrPos(CookieLine, ';');
            if SemiPos > 1 then
                PairText := CopyStr(CookieLine, 1, SemiPos - 1)
            else
                PairText := CookieLine;

            if CookieResult <> '' then
                CookieResult += '; ';
            CookieResult += PairText;
        end;

        exit(CookieResult);
    end;

    // ----------------------------------------------------------
    //  Build the POST body form parameters.
    //
    //  The JavaScript in esena-apis.js sends:
    //    newsLimit=<n>&esanaWidget=false&<csrfName>=<csrfHash>&category=
    //
    //  Note: the old code used "limit" and "id" — these are
    //  WRONG parameter names.  The correct names are:
    //    newsLimit   — number of news items to fetch
    //    esanaWidget — false for full page, true for widget
    //    category    — news category filter (empty = all)
    //    <csrfName>  — the CSRF token (name is dynamic, usually "csrf")
    // ----------------------------------------------------------
    local procedure BuildPostBody(Setup: Record "HK News API Setup"; CsrfName: Text; CsrfHash: Text): Text
    var
        Body: Text;
    begin
        Body := 'newsLimit=' + Format(Setup."News Per Fetch");
        Body += '&esanaWidget=false';
        Body += '&' + CsrfName + '=' + CsrfHash;
        Body += '&category=';

        exit(Body);
    end;

    // ----------------------------------------------------------
    //  Apply all required headers matching the browser request
    //  captured in Postman / esena-apis.js.
    //
    //  IMPORTANT: BC's HttpClient does NOT have an automatic
    //  cookie jar.  The Cookie header must be set explicitly
    //  using the session cookie extracted from the preflight
    //  GET response.
    // ----------------------------------------------------------
    local procedure SetRequestHeaders(var Headers: HttpHeaders; Setup: Record "HK News API Setup"; SessionCookie: Text)
    begin
        SetHeader(Headers, 'accept', 'application/json, text/javascript, */*; q=0.01');
        SetHeader(Headers, 'accept-language', 'en-US,en;q=0.9');
        SetHeader(Headers, 'cache-control', 'no-cache');
        SetHeader(Headers, 'pragma', 'no-cache');
        SetHeader(Headers, 'x-requested-with', 'XMLHttpRequest');
        SetHeader(Headers, 'user-agent',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) ' +
            'AppleWebKit/537.36 (KHTML, like Gecko) ' +
            'Chrome/146.0.0.0 Safari/537.36');

        // Origin and Referer from setup (configurable)
        if Setup."Origin Header" <> '' then
            SetHeader(Headers, 'origin', Setup."Origin Header");
        if Setup."Referer Header" <> '' then
            SetHeader(Headers, 'referer', Setup."Referer Header");

        // Session cookie — MUST be set explicitly.
        // BC's HttpClient has no cookie jar; cookies from the
        // preflight GET are NOT auto-forwarded.
        if SessionCookie <> '' then
            SetHeader(Headers, 'cookie', SessionCookie);
    end;

    // ----------------------------------------------------------
    //  Safe header setter — removes existing before adding
    // ----------------------------------------------------------
    local procedure SetHeader(var Headers: HttpHeaders; HeaderKey: Text; HeaderValue: Text)
    begin
        if Headers.Contains(HeaderKey) then
            Headers.Remove(HeaderKey);
        Headers.Add(HeaderKey, HeaderValue);
    end;

    // ----------------------------------------------------------
    //  Error logger — writes to the Activity Log (or Error log)
    //  In production you may replace this with a proper
    //  activity log or notification codeunit.
    // ----------------------------------------------------------
    local procedure LogError(ErrorMsg: Text)
    begin
        // During a Job Queue run errors are captured automatically;
        // this message helps when run in the foreground.
        if GuiAllowed() then
            Error(ErrorMsg)
        else
            // Let the Job Queue framework catch and record the error
            Error(ErrorMsg);
    end;
}
