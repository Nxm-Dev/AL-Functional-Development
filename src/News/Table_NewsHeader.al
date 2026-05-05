// ============================================================
//  Table 74111 - News Header (Master Table)
//  Stores the main metadata for each news article fetched
//  from the Helakuru Esana API.
// ============================================================
table 74111 "HK News Header"
{
    Caption = 'News Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "News ID"; Integer)
        {
            Caption = 'News ID';
            DataClassification = CustomerContent;
        }
        field(2; "Title SI"; Text[2048])
        {
            Caption = 'Title (Sinhala)';
            DataClassification = CustomerContent;
        }
        field(3; "Title EN"; Text[2048])
        {
            Caption = 'Title (English)';
            DataClassification = CustomerContent;
        }
        field(4; "Category"; Integer)
        {
            Caption = 'Category';
            DataClassification = CustomerContent;
        }
        field(5; "Thumb URL"; Text[1024])
        {
            Caption = 'Thumbnail URL';
            DataClassification = CustomerContent;
        }
        field(6; "Cover URL"; Text[1024])
        {
            Caption = 'Cover Image URL';
            DataClassification = CustomerContent;
        }
        field(7; "Published DateTime"; DateTime)
        {
            Caption = 'Published Date/Time';
            DataClassification = CustomerContent;
        }
        field(8; "Share URL"; Text[1024])
        {
            Caption = 'Share URL';
            DataClassification = CustomerContent;
        }
        field(9; "Total Comments"; Integer)
        {
            Caption = 'Total Comments';
            DataClassification = CustomerContent;
        }
        field(10; "Total Likes"; Integer)
        {
            Caption = 'Total Likes';
            DataClassification = CustomerContent;
        }
        field(11; "Total Love"; Integer)
        {
            Caption = 'Total Love';
            DataClassification = CustomerContent;
        }
        field(12; "Total Haha"; Integer)
        {
            Caption = 'Total Haha';
            DataClassification = CustomerContent;
        }
        field(13; "Total Wow"; Integer)
        {
            Caption = 'Total Wow';
            DataClassification = CustomerContent;
        }
        field(14; "Total Sad"; Integer)
        {
            Caption = 'Total Sad';
            DataClassification = CustomerContent;
        }
        field(15; "Total Angry"; Integer)
        {
            Caption = 'Total Angry';
            DataClassification = CustomerContent;
        }
        field(16; "Comment Rate"; Decimal)
        {
            Caption = 'Comment Rate';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 2;
        }
        field(17; "Status"; Option)
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            OptionMembers = Active,Archived;
            OptionCaption = 'Active,Archived';
        }
        field(18; "First News Batch ID"; Integer)
        {
            Caption = 'First News Batch ID';
            DataClassification = CustomerContent;
        }
        field(19; "Last Synced DateTime"; DateTime)
        {
            Caption = 'Last Synced';
            DataClassification = CustomerContent;
        }
        field(20; "Comments Sin"; Integer)
        {
            Caption = 'Comments (Sinhala)';
            DataClassification = CustomerContent;
        }
        field(21; "Comments Eng"; Integer)
        {
            Caption = 'Comments (English)';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "News ID")
        {
            Clustered = true;
        }
        key(K2; "Published DateTime")
        {
        }
        key(K3; "Status", "Published DateTime")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "News ID", "Title EN", "Published DateTime") { }
    }
}
