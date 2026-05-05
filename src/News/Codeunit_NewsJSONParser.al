// ============================================================
//  Codeunit 74115 - HK News JSON Parser
//  Parses the raw JSON response body and upserts records
//  into HK News Header and HK News Content Line tables.
// ============================================================
codeunit 74115 "HK News JSON Parser"
{
    // Entry point called by the API Integration codeunit
    procedure ParseAndStore(JsonBody: Text; FirstNewsID: Integer): Integer
    var
        JToken: JsonToken;
        JObject: JsonObject;
        JArray: JsonArray;
        NewsJToken: JsonToken;
        NewsJObject: JsonObject;
        ParsedCount: Integer;
    begin
        ParsedCount := 0;

        if not JObject.ReadFrom(JsonBody) then
            Error('Failed to parse JSON response body.');

        // Extract the NEWS array
        if not JObject.Get('NEWS', JToken) then
            Error('JSON response does not contain a NEWS array.');

        JArray := JToken.AsArray();

        foreach NewsJToken in JArray do begin
            NewsJObject := NewsJToken.AsObject();
            if ParseNewsItem(NewsJObject, FirstNewsID) then
                ParsedCount += 1;
        end;

        exit(ParsedCount);
    end;

    // ----------------------------------------------------------
    //  Parse one NEWS object and upsert into BC tables
    //  Returns TRUE if a new record was inserted, FALSE if skipped
    // ----------------------------------------------------------
    local procedure ParseNewsItem(NewsObj: JsonObject; FirstNewsID: Integer): Boolean
    var
        NewsHeader: Record "HK News Header";
        NewsID: Integer;
        IsNew: Boolean;
    begin
        NewsID := GetIntValue(NewsObj, 'id');
        if NewsID = 0 then
            exit(false);

        IsNew := not NewsHeader.Get(NewsID);

        if IsNew then begin
            NewsHeader.Init();
            NewsHeader."News ID" := NewsID;
        end;

        // ---- Header fields ----
        NewsHeader."Title SI" := CopyStr(GetTextValue(NewsObj, 'titleSi'), 1, 2048);
        NewsHeader."Title EN" := CopyStr(GetTextValue(NewsObj, 'titleEn'), 1, 2048);
        NewsHeader."Category" := GetIntValue(NewsObj, 'category');
        NewsHeader."Thumb URL" := CopyStr(GetTextValue(NewsObj, 'thumb'), 1, 1024);
        NewsHeader."Cover URL" := CopyStr(GetTextValue(NewsObj, 'cover'), 1, 1024);
        NewsHeader."Share URL" := CopyStr(GetTextValue(NewsObj, 'share_url'), 1, 1024);
        NewsHeader."Total Comments" := GetIntValue(NewsObj, 'comments');
        NewsHeader."Comment Rate" := GetDecimalValue(NewsObj, 'comment_rate');
        NewsHeader."Published DateTime" := ParsePublishedDate(GetTextValue(NewsObj, 'published'));
        NewsHeader."First News Batch ID" := FirstNewsID;
        NewsHeader."Last Synced DateTime" := CurrentDateTime();
        NewsHeader."Status" := NewsHeader."Status"::Active;

        // ---- Reactions sub-object ----
        ParseReactions(NewsObj, NewsHeader);

        // ---- commentCounts sub-object ----
        ParseCommentCounts(NewsObj, NewsHeader);

        if IsNew then
            NewsHeader.Insert(true)
        else
            NewsHeader.Modify(true);

        // ---- Content Lines ----
        // Always re-insert content lines to keep in sync
        DeleteContentLines(NewsID);
        ParseContentArray(NewsObj, NewsID, 'contentSi', 'SI');
        ParseContentArray(NewsObj, NewsID, 'contentEn', 'EN');

        exit(IsNew);
    end;

    // ----------------------------------------------------------
    //  Parse reactions:{like,love,haha,wow,sad,angry}
    // ----------------------------------------------------------
    local procedure ParseReactions(NewsObj: JsonObject; var Header: Record "HK News Header")
    var
        JToken: JsonToken;
        ReactObj: JsonObject;
    begin
        if not NewsObj.Get('reactions', JToken) then
            exit;

        ReactObj := JToken.AsObject();
        Header."Total Likes" := GetIntFromObject(ReactObj, 'like');
        Header."Total Love" := GetIntFromObject(ReactObj, 'love');
        Header."Total Haha" := GetIntFromObject(ReactObj, 'haha');
        Header."Total Wow" := GetIntFromObject(ReactObj, 'wow');
        Header."Total Sad" := GetIntFromObject(ReactObj, 'sad');
        Header."Total Angry" := GetIntFromObject(ReactObj, 'angry');
    end;

    // ----------------------------------------------------------
    //  Parse commentCounts:{sin,eng}
    // ----------------------------------------------------------
    local procedure ParseCommentCounts(NewsObj: JsonObject; var Header: Record "HK News Header")
    var
        JToken: JsonToken;
        CountObj: JsonObject;
    begin
        if not NewsObj.Get('commentCounts', JToken) then
            exit;

        CountObj := JToken.AsObject();
        Header."Comments Sin" := GetIntFromObject(CountObj, 'sin');
        Header."Comments Eng" := GetIntFromObject(CountObj, 'eng');
    end;

    // ----------------------------------------------------------
    //  Delete existing content lines for a News ID
    // ----------------------------------------------------------
    local procedure DeleteContentLines(NewsID: Integer)
    var
        ContentLine: Record "HK News Content Line";
    begin
        ContentLine.SetRange("News ID", NewsID);
        ContentLine.DeleteAll(false);
    end;

    // ----------------------------------------------------------
    //  Parse contentSi or contentEn array and insert lines
    // ----------------------------------------------------------
    local procedure ParseContentArray(NewsObj: JsonObject; NewsID: Integer; ArrayKey: Text; LangCode: Code[10])
    var
        JToken: JsonToken;
        JArray: JsonArray;
        ItemToken: JsonToken;
        ItemObj: JsonObject;
        ContentLine: Record "HK News Content Line";
        LineNo: Integer;
        ItemType: Text;
        ItemData: Text;
        OptionsToken: JsonToken;
        OptionsObj: JsonObject;
    begin
        if not NewsObj.Get(ArrayKey, JToken) then
            exit;

        JArray := JToken.AsArray();
        LineNo := 10000; // start line numbering at 10000, increment by 10000

        foreach ItemToken in JArray do begin
            ItemObj := ItemToken.AsObject();
            ItemType := GetTextValue(ItemObj, 'type');
            ItemData := GetTextValue(ItemObj, 'data');

            // Skip blank spacer items
            if ItemData.Trim() <> '' then begin
                ContentLine.Init();
                ContentLine."News ID" := NewsID;
                ContentLine."Line No." := LineNo;
                ContentLine."Language Code" := LangCode;

                case LowerCase(ItemType) of
                    'text':
                        begin
                            ContentLine."Content Type" := ContentLine."Content Type"::Text;

                            // Parse options sub-object if present
                            if ItemObj.Get('options', OptionsToken) then begin
                                OptionsObj := OptionsToken.AsObject();
                                ContentLine."Font Size" := CopyStr(GetTextFromObject(OptionsObj, 'size'), 1, 20);
                                // Note: API has typo 'alingment' — handle both spellings
                                ContentLine."Alignment" := CopyStr(
                                    GetAlignmentValue(OptionsObj), 1, 20);
                                ContentLine."Is Quote" := GetBoolFromObject(OptionsObj, 'is_quote');
                            end;
                        end;
                    'image':
                        ContentLine."Content Type" := ContentLine."Content Type"::Image;
                    else
                        ContentLine."Content Type" := ContentLine."Content Type"::Text;
                end;

                ContentLine.SetContentData(ItemData);
                ContentLine.Insert(false);
            end;

            LineNo += 10000;
        end;
    end;

    // ----------------------------------------------------------
    //  Handle API typo: 'alingment' vs 'alignment'
    // ----------------------------------------------------------
    local procedure GetAlignmentValue(OptionsObj: JsonObject): Text
    var
        Val: Text;
    begin
        Val := GetTextFromObject(OptionsObj, 'alignment');
        if Val = '' then
            Val := GetTextFromObject(OptionsObj, 'alingment'); // API typo
        if Val = '' then
            Val := 'left';
        exit(Val);
    end;

    // ----------------------------------------------------------
    //  Parse "published": "2026-05-05 15:50:00"  → DateTime
    // ----------------------------------------------------------
    local procedure ParsePublishedDate(DateStr: Text): DateTime
    var
        DatePart: Text;
        TimePart: Text;
        Parts: List of [Text];
        D: Date;
        T: Time;
        Yr: Integer;
        Mo: Integer;
        Dy: Integer;
        Hr: Integer;
        Mn: Integer;
        Sc: Integer;
        DateParts: List of [Text];
        TimeParts: List of [Text];
    begin
        if DateStr = '' then
            exit(0DT);

        // Split on space into date and time
        Parts := DateStr.Split(' ');
        if Parts.Count() < 2 then
            exit(0DT);

        DatePart := Parts.Get(1);
        TimePart := Parts.Get(2);

        // Parse date: YYYY-MM-DD
        DateParts := DatePart.Split('-');
        if DateParts.Count() < 3 then
            exit(0DT);

        Evaluate(Yr, DateParts.Get(1));
        Evaluate(Mo, DateParts.Get(2));
        Evaluate(Dy, DateParts.Get(3));

        // Parse time: HH:MM:SS
        TimeParts := TimePart.Split(':');
        if TimeParts.Count() >= 3 then begin
            Evaluate(Hr, TimeParts.Get(1));
            Evaluate(Mn, TimeParts.Get(2));
            Evaluate(Sc, TimeParts.Get(3));
        end;

        D := DMY2Date(Dy, Mo, Yr);
        // Create time from hours, minutes, seconds using Evaluate
        Evaluate(T, StrSubstNo('%1:%2:%3', Hr, Mn, Sc));
        exit(CreateDateTime(D, T));
    end;

    // ============================================================
    //  JSON value helper procedures
    // ============================================================

    local procedure GetTextValue(Obj: JsonObject; JsonKey: Text): Text
    var
        JToken: JsonToken;
    begin
        if Obj.Get(JsonKey, JToken) then
            if JToken.IsValue() then
                exit(JToken.AsValue().AsText());
        exit('');
    end;

    local procedure GetIntValue(Obj: JsonObject; JsonKey: Text): Integer
    var
        JToken: JsonToken;
    begin
        if Obj.Get(JsonKey, JToken) then
            if JToken.IsValue() then
                exit(JToken.AsValue().AsInteger());
        exit(0);
    end;

    local procedure GetDecimalValue(Obj: JsonObject; JsonKey: Text): Decimal
    var
        JToken: JsonToken;
    begin
        if Obj.Get(JsonKey, JToken) then
            if JToken.IsValue() then
                exit(JToken.AsValue().AsDecimal());
        exit(0);
    end;

    local procedure GetTextFromObject(Obj: JsonObject; JsonKey: Text): Text
    var
        JToken: JsonToken;
    begin
        if Obj.Get(JsonKey, JToken) then
            if JToken.IsValue() then
                exit(JToken.AsValue().AsText());
        exit('');
    end;

    local procedure GetIntFromObject(Obj: JsonObject; JsonKey: Text): Integer
    var
        JToken: JsonToken;
    begin
        if Obj.Get(JsonKey, JToken) then
            if JToken.IsValue() then
                exit(JToken.AsValue().AsInteger());
        exit(0);
    end;

    local procedure GetBoolFromObject(Obj: JsonObject; JsonKey: Text): Boolean
    var
        JToken: JsonToken;
    begin
        if Obj.Get(JsonKey, JToken) then
            if JToken.IsValue() then
                exit(JToken.AsValue().AsBoolean());
        exit(false);
    end;
}
