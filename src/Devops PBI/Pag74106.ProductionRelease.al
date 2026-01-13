page 74106 "Production Release"
{
    ApplicationArea = All;
    Caption = 'Production Release';
    PageType = Card;
    SourceTable = "Releases Automation";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Sprint No"; Rec."Sprint No")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sprint number for this release automation record.';
                }
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the email subject line.';

                }
            }

            group(Recipients)
            {
                Caption = 'Recipients';

                part(RecipientsPart; "Reciept List")
                {
                    ApplicationArea = All;
                    UpdatePropagation = Both;
                }
            }

            group(WorkItems)
            {
                Caption = 'Released Work Items';

                part(ReleasedWorkItemsPart; "Released Work Items")
                {
                    ApplicationArea = All;
                    SubPageLink = "Sprint No" = field("Sprint No");
                    UpdatePropagation = Both;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SendEmail)
            {
                ApplicationArea = All;
                Caption = 'Send Email';
                ToolTip = 'Send the email using the configured recipients and content.';
                Image = SendMail;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    AzureDevOpsIntegration: Codeunit "Azure DevOps Integration";
                begin
                    if not Confirm('Do you want to send this email?', false) then
                        exit;

                    AzureDevOpsIntegration.SendEmail(Rec);
                end;
            }
        }
    }
}
