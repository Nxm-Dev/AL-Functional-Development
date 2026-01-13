table 74104 "Reciepts List"
{
    Caption = 'Reciepts List';
    DataClassification = ToBeClassified;

    fields
    {
        field(3; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = CustomerContent;
            TableRelation = User."User Name";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                User: Record User;
            begin
                if "User ID" = '' then begin
                    Email := '';
                    exit;
                end;

                User.SetRange("User Name", "User ID");
                if User.FindFirst() then begin
                    if User."Contact Email" <> '' then
                        Email := User."Contact Email"
                    else
                        Email := User."Authentication Email";
                end else
                    Error('User %1 not found.', "User ID");
            end;
        }
        field(4; Email; Text[250])
        {
            Caption = 'Email';
            DataClassification = CustomerContent;
            ExtendedDatatype = EMail;

        }
        field(5; "Recipient Type"; Option)
        {
            Caption = 'Recipient Type';
            DataClassification = CustomerContent;
            OptionMembers = CC,BCC,TOList;
            OptionCaption = 'CC,BCC,To';
        }
    }

    keys
    {
        key(PK; "User ID")
        {
            Clustered = true;
        }
    }
}

