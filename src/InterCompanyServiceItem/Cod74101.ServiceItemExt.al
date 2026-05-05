codeunit 74101 "Service Item Ext"
{
    [EventSubscriber(ObjectType::Codeunit, 5920, 'OnCreateServItemOnSalesLineShpt', '', true, true)]
    local procedure OnCreateServItemOnSalesLineShpt(VAR ServiceItem: Record "Service Item"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    begin
        CreateServItemReleventDivision(SalesHeader, ServiceItem);
    end;

    procedure CreateServItemReleventDivision(SalesHeader: Record "Sales Header"; var SourceServiceItem: Record "Service Item"): Boolean
    var
        ServMgtSetup: Record "Service Mgt. Setup";
        ServMgtSetupTarget: Record "Service Mgt. Setup";
        TargetServiceItem: Record "Service Item";
        TargetCompanyName: Text[30];
    begin
        if not ServMgtSetup.FindFirst() then begin
            Error('Service Mgt. Setup not found in %1', CompanyName());
        end;

        TargetCompanyName := ServMgtSetup."Service Item Creation Company";

        if TargetCompanyName = '' then begin
            Error('Service Item Creation Company is not configured in Service Mgt. Setup');
        end;

        if TargetCompanyName = CompanyName() then begin
            Error('Target company cannot be the same as current company');
        end;

        ServMgtSetupTarget.ChangeCompany(TargetCompanyName);
        if not ServMgtSetupTarget.FindFirst() then begin
            Error('Service Mgt. Setup not found in company: %1', TargetCompanyName);
        end;

        if ServMgtSetupTarget."Service Item Nos." = '' then begin
            Error('Service Item Nos. is not configured in %1', TargetCompanyName);
        end;

        TargetServiceItem.ChangeCompany(TargetCompanyName);
        if ExecuteInTargetCompany(TargetServiceItem, SourceServiceItem, ServMgtSetupTarget."Service Item Nos.", TargetCompanyName, SalesHeader) then begin
            exit(true);
        end else begin
            Error('Failed to create Service Item in %1', TargetCompanyName);
        end;
    end;

    procedure ExecuteInTargetCompany(var TargetServiceItem: Record "Service Item"; SourceServiceItem: Record "Service Item"; NoSeriesCode: Code[20]; TargetCompanyName: Text[30]; SalesHeader: Record "Sales Header"): Boolean
    var
        NoSeriesMgt: Codeunit "No. Series";
    begin
        TargetServiceItem.Init();
        TargetServiceItem.TransferFields(SourceServiceItem, false);
        TargetServiceItem."No. Series" := NoSeriesCode;
        TargetServiceItem."No." := GetTargetServItemNo(NoSeriesCode, TargetCompanyName);
        TargetServiceItem."Sync From" := CompanyName();
        TargetServiceItem."Invoice No." := SalesHeader."Posting No.";
        exit(TargetServiceItem.Insert(false));
    end;

    local procedure GetTargetServItemNo(NoSeriesCode: Code[20]; TargetCompanyName: Text[30]): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
        LastDocNo: Code[20];
        NxtDocNo: Code[20];
    begin
        NoSeriesLine.Reset();
        NoSeriesLine.ChangeCompany(TargetCompanyName);
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);

        if NoSeriesLine.FindFirst() then begin
            LastDocNo := NoSeriesLine."Last No. Used";
            if LastDocNo <> '' then begin
                NxtDocNo := IncrementDocumentNo(LastDocNo);
            end else begin
                NxtDocNo := NoSeriesLine."Starting No.";
            end;
            NoSeriesLine."Last No. Used" := NxtDocNo;
            NoSeriesLine.Modify();

            exit(NxtDocNo);
        end else begin
            Error('No. Series Line not found for %1 in company %2', NoSeriesCode, TargetCompanyName);
        end;
    end;

    [Scope('onPrem')]
    procedure IncrementDocumentNo(InputCode: Code[50]): Code[50]
    var
        Prefix: Text;
        NumericPart: Text;
        Number: Integer;
        i: Integer;
        SeparatorFound: Boolean;
    begin
        if InputCode = '' then
            exit('');

        for i := StrLen(InputCode) downto 1 do begin
            if not (InputCode[i] in ['0' .. '9']) then
                break;
        end;

        if i = StrLen(InputCode) then
            exit(InputCode + '1');

        Prefix := CopyStr(InputCode, 1, i);
        NumericPart := CopyStr(InputCode, i + 1);

        if NumericPart = '' then
            exit(InputCode + '1');

        if Evaluate(Number, NumericPart) then begin
            Number += 1;
            exit(Prefix + PadStr('', StrLen(NumericPart) - StrLen(Format(Number)), '0') + Format(Number));
        end;

        exit(InputCode + '1');
    end;
}
