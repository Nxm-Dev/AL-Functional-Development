page 74105 "Releases Automation List"
{
    Caption = 'Releases Automation List';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Releases Automation";
    CardPageId = "Production Release";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Sprint No"; Rec."Sprint No")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique code for this email automation record.';
                }
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the email subject line.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ConfigurePAT)
            {
                ApplicationArea = All;
                Caption = 'Configure PAT';
                ToolTip = 'Configure the Personal Access Token for Azure DevOps integration.';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Page.RunModal(Page::"Azure DevOps Setup");
                end;
            }
        }
    }
}
