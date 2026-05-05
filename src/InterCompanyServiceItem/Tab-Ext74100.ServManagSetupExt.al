tableextension 74100 ServManagSetupExt extends "Service Mgt. Setup"
{
    fields
    {
        field(74100; "Service Item Creation Company"; Text[30])
        {
            Caption = 'Service Item Creation Company';
            DataClassification = ToBeClassified;
            TableRelation = Company.Name;
        }
    }
}
