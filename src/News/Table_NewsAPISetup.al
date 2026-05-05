// ============================================================
//  Table 74113 - HK News API Setup
//  Stores the API configuration so it can be changed without
//  touching the code.  One record per company (singleton).
// ============================================================
table 74113 "HK News API Setup"
{
    Caption = 'News API Setup';
    DataClassification = CustomerContent;
    DataPerCompany = true;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = CustomerContent;
        }
        field(2; "Endpoint URL"; Text[1024])
        {
            Caption = 'Endpoint URL';
            DataClassification = CustomerContent;
            // Default: https://www.helakuru.lk/esana/load
        }
        field(3; "Request Timeout Sec"; Integer)
        {
            Caption = 'Request Timeout (sec)';
            DataClassification = CustomerContent;
            InitValue = 30;
        }
        field(4; "News Per Fetch"; Integer)
        {
            Caption = 'News Items Per Fetch';
            DataClassification = CustomerContent;
            InitValue = 10;
            // Passed as POST body param 'newsLimit'
        }
        field(5; "Last Fetch DateTime"; DateTime)
        {
            Caption = 'Last Fetch Date/Time';
            DataClassification = CustomerContent;
        }
        field(6; "Last FIRST_NEWS_ID"; Integer)
        {
            Caption = 'Last First News ID';
            DataClassification = CustomerContent;
            // Used to fetch only newer articles on next run
        }
        field(7; "Enabled"; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(8; "Origin Header"; Text[512])
        {
            Caption = 'Origin Header';
            DataClassification = CustomerContent;
            InitValue = 'https://www.helakuru.lk';
        }
        field(9; "Referer Header"; Text[512])
        {
            Caption = 'Referer Header';
            DataClassification = CustomerContent;
            InitValue = 'https://www.helakuru.lk/';
        }
        field(10; "Cookie Value"; Text[2048])
        {
            Caption = 'Cookie';
            DataClassification = CustomerContent;
            // Auto-populated by the preflight GET to /esana.
            // Shows the last esp-ak=<hash> value for diagnostic purposes.
            // You do NOT need to manually paste a cookie — the codeunit
            // harvests a fresh CSRF token + cookie on every run.
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }

    // ----------------------------------------------------------
    //  Get or create the singleton setup record
    // ----------------------------------------------------------
    procedure GetOrCreate(var Rec: Record "HK News API Setup")
    begin
        if not Rec.Get('') then begin
            Rec.Init();
            Rec."Primary Key" := '';
            Rec."Endpoint URL" := 'https://www.helakuru.lk/esana/load';
            Rec."Request Timeout Sec" := 30;
            Rec."News Per Fetch" := 10;
            Rec."Enabled" := true;
            Rec."Origin Header" := 'https://www.helakuru.lk';
            Rec."Referer Header" := 'https://www.helakuru.lk/';
            Rec.Insert(true);
        end;
    end;
}
