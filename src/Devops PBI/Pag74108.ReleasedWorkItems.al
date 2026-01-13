page 74108 "Released Work Items"
{
    ApplicationArea = All;
    Caption = 'Released Work Items';
    PageType = ListPart;
    SourceTable = "Released Work Items";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Company; Rec.Company)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company associated with the work item in Azure DevOps.';
                }
                field("Work Item ID"; Rec."Work Item ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Work Item ID from Azure DevOps.';

                    trigger OnValidate()
                    begin
                        UpdateDevopsData();
                    end;
                }
                field("PBI description"; Rec."PBI description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description fetched from Azure DevOps.';
                }
                field("Created By User"; Rec."Created By User")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user who created the work item in Azure DevOps.';
                }
                field("Assigned To"; Rec."Assigned To")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user who is assigned to the work item in Azure DevOps.';
                }
                field("Requested User"; Rec."Requested User")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user who requested the work item in Azure DevOps.';
                }

            }
        }
    }

    local procedure UpdateDevopsData()
    var
        AzureDevOpsIntegration: Codeunit "Azure DevOps Integration";
    begin
        AzureDevOpsIntegration.FetchWorkItemDetails(Rec);
    end;
}
