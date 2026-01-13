table 74103 "Releases Automation"
{
    Caption = 'Releases Automation';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Sprint No"; Code[20])
        {
            Caption = 'Sprint No';
        }
        field(2; "Subject"; Text[100])
        {
            Caption = 'Subject';
        }
    }
    keys
    {
        key(PK; "Sprint No")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Sprint No")
        {
        }
    }

    trigger OnInsert()
    begin
        Rec.Subject := 'Production Weekly Release Log - Sprint : ' + Rec."Sprint No";
    end;


}
