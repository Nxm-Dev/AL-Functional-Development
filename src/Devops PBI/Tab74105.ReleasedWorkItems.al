table 74105 "Released Work Items"
{
    Caption = 'Released Work Items';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Work Item ID"; Code[20])
        {
            Caption = 'Work Item ID';
        }
        field(2; "Sprint No"; Code[20])
        {
            Caption = 'Sprint No';
        }
        field(3; "PBI description"; Text[250])
        {
            Caption = 'PBI description';
        }
        field(4; "Created By User"; Text[100])
        {
            Caption = 'Created By User';
        }
        field(5; "Assigned To"; Text[100])
        {
            Caption = 'Assigned To';
        }
        field(6; "Requested User"; Text[100])
        {
            Caption = 'Requested User';
        }
        field(7; "Company"; Text[100])
        {
            Caption = 'Company';
        }
    }
    keys
    {
        key(PK; "Work Item ID", "Sprint No")
        {
            Clustered = true;
        }
    }
}
