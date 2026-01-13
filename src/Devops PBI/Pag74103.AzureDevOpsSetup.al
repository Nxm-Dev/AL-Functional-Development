page 74103 "Azure DevOps Setup"
{
    Caption = 'Azure DevOps Setup';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Azure DevOps Setup";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Configuration)
            {
                Caption = 'Configuration';

                field("Personal Access Token"; Rec."Personal Access Token")
                {
                    ApplicationArea = All;
                    Caption = 'Personal Access Token';
                    ToolTip = 'Enter your Azure DevOps Personal Access Token (PAT) for authentication.';
                    ExtendedDatatype = Masked;
                }
                field("Organization Name"; Rec."Organization Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Azure DevOps organization name.';
                }
                field("Project Name"; Rec."Project Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Azure DevOps project name.';
                }
            }
            group(Instructions)
            {
                Caption = 'Instructions';

                field(InstructionText; InstructionLbl)
                {
                    ApplicationArea = All;
                    Caption = 'How to get PAT';
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TestConnection)
            {
                ApplicationArea = All;
                Caption = 'Test Connection';
                ToolTip = 'Test the connection to Azure DevOps using the configured PAT.';
                Image = TestDatabase;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    AzureDevOpsIntegration: Codeunit "Azure DevOps Integration";
                begin
                    if AzureDevOpsIntegration.TestConnection() then
                        Message('Connection to Azure DevOps was successful.')
                    else
                        Error('Failed to connect to Azure DevOps. Please check your PAT configuration.');
                end;
            }
        }
    }

    var
        InstructionLbl: Label 'To generate a Personal Access Token (PAT):\1. Go to https://dev.azure.com/Browns-ERP-BC\2. Click on User Settings (gear icon) > Personal Access Tokens\3. Click "New Token"\4. Give it a name and set expiration\5. Select "Work Items" with "Read" scope\6. Click "Create" and copy the token\7. Paste the token in the field above and save the record';

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
    end;
}
