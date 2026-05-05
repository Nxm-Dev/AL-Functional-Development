pageextension 74100 ServMgtSetup extends "Service Mgt. Setup"
{
    layout
    {
        addafter(General)
        {
            group("Service Item Creation")
            {
                Caption = 'Service Item Creation';
                field("Service Item Creation Company"; Rec."Service Item Creation Company")
                {
                    ApplicationArea = All;
                    Caption = 'Service Item Creation Company';
                    ToolTip = 'Service Item Creation Company';
                }
            }
        }
    }
}
