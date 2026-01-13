page 74107 "Reciept List"
{
    ApplicationArea = All;
    Caption = 'Reciept List';
    PageType = ListPart;
    SourceTable = "Reciepts List";
    
    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the User ID from the User table.';
                }
                field(Email; Rec.Email)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the email address of the recipient.';
                }
                field("Recipient Type"; Rec."Recipient Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this is a CC or BCC recipient.';
                }
            }
        }
    }
}
