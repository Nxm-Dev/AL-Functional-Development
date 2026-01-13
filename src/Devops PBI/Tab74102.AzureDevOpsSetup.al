table 74102 "Azure DevOps Setup"
{
    Caption = 'Azure DevOps Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = CustomerContent;
        }
        field(2; "Personal Access Token"; Text[250])
        {
            Caption = 'Personal Access Token';
            DataClassification = EndUserIdentifiableInformation;
            ExtendedDatatype = Masked;
        }
        field(3; "Organization Name"; Text[100])
        {
            Caption = 'Organization Name';
            DataClassification = CustomerContent;
            InitValue = 'Browns-ERP-BC';
        }
        field(4; "Project Name"; Text[100])
        {
            Caption = 'Project Name';
            DataClassification = CustomerContent;
            InitValue = 'Browns-ERP-BC';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetSetup(): Boolean
    begin
        if not Get() then begin
            Init();
            "Primary Key" := '';
            Insert();
        end;
        exit(true);
    end;
}
