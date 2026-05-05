// ============================================================
//  Table 74112 - News Content Line (Detail Table)
//  Stores individual content items (text paragraphs / images)
//  for each news article in both Sinhala and English.
// ============================================================
table 74112 "HK News Content Line"
{
    Caption = 'News Content Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "News ID"; Integer)
        {
            Caption = 'News ID';
            DataClassification = CustomerContent;
            TableRelation = "HK News Header"."News ID";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(3; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            DataClassification = CustomerContent;
            // 'SI' = Sinhala  |  'EN' = English
        }
        field(4; "Content Type"; Enum "HK Content Type")
        {
            Caption = 'Content Type';
            DataClassification = CustomerContent;
        }
        field(5; "Content Data"; Blob)
        {
            Caption = 'Content Data';
            DataClassification = CustomerContent;
            // Stored as Blob to handle Sinhala text > 2048 chars and image URLs
        }
        field(6; "Font Size"; Code[20])
        {
            Caption = 'Font Size';
            DataClassification = CustomerContent;
            // e.g. 'normal', 'large', 'small'
        }
        field(7; "Alignment"; Code[20])
        {
            Caption = 'Alignment';
            DataClassification = CustomerContent;
            // e.g. 'left', 'center', 'right'
        }
        field(8; "Is Quote"; Boolean)
        {
            Caption = 'Is Quote';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "News ID", "Line No.", "Language Code")
        {
            Clustered = true;
        }
        key(K2; "News ID", "Language Code", "Content Type")
        {
        }
    }

    // ----------------------------------------------------------
    //  Helper: Write a text string into the Blob field
    // ----------------------------------------------------------
    procedure SetContentData(DataText: Text)
    var
        OStream: OutStream;
    begin
        Clear("Content Data");
        "Content Data".CreateOutStream(OStream, TextEncoding::UTF8);
        OStream.WriteText(DataText);
    end;

    // ----------------------------------------------------------
    //  Helper: Read text back from the Blob field
    // ----------------------------------------------------------
    procedure GetContentData(): Text
    var
        IStream: InStream;
        Result: Text;
        Line: Text;
    begin
        if "Content Data".HasValue() then begin
            "Content Data".CreateInStream(IStream, TextEncoding::UTF8);
            while not IStream.EOS() do begin
                IStream.ReadText(Line);
                Result += Line + '\';
            end;
            // Trim trailing backslash added by multi-line read
            if Result.EndsWith('\') then
                Result := Result.Substring(1, StrLen(Result) - 1);
        end;
        exit(Result);
    end;
}
