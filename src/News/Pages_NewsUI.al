// ============================================================
//  Page 74116 - HK News API Setup
//  Configuration page for the API endpoint and credentials.
//  Accessible via Search > "HK News API Setup"
// ============================================================
page 74116 "HK News API Setup"
{
    Caption = 'News API Setup';
    PageType = Card;
    SourceTable = "HK News API Setup";
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Endpoint URL"; Rec."Endpoint URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'The full URL of the Helakuru Esana POST endpoint.';
                }
                field("Enabled"; Rec."Enabled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable or disable automatic news fetching.';
                }
                field("News Per Fetch"; Rec."News Per Fetch")
                {
                    ApplicationArea = All;
                    ToolTip = 'Number of news items to retrieve per API call.';
                }
                field("Request Timeout Sec"; Rec."Request Timeout Sec")
                {
                    ApplicationArea = All;
                    ToolTip = 'HTTP request timeout in seconds.';
                }
            }
            group(Headers)
            {
                Caption = 'Request Headers';
                field("Origin Header"; Rec."Origin Header")
                {
                    ApplicationArea = All;
                    ToolTip = 'Value for the Origin request header.';
                }
                field("Referer Header"; Rec."Referer Header")
                {
                    ApplicationArea = All;
                    ToolTip = 'Value for the Referer request header.';
                }
                field("Cookie Value"; Rec."Cookie Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Session cookie copied from browser DevTools.';
                    ExtendedDatatype = Masked;
                }
            }
            group(SyncInfo)
            {
                Caption = 'Last Sync';
                Editable = false;
                field("Last Fetch DateTime"; Rec."Last Fetch DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Date and time of the last successful API fetch.';
                }
                field("Last FIRST_NEWS_ID"; Rec."Last FIRST_NEWS_ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'The FIRST_NEWS_ID received in the last API response.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(FetchNow)
            {
                Caption = 'Fetch News Now';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Manually trigger an immediate API fetch and sync.';

                trigger OnAction()
                var
                    IntegrationMgt: Codeunit "HK News API Integration Mgt.";
                begin
                    IntegrationMgt.FetchAndStoreNews();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Setup: Record "HK News API Setup";
    begin
        Setup.GetOrCreate(Setup);
        if not Rec.Get('') then
            Rec.Get('');
    end;
}

// ============================================================
//  Page 74117 - HK News Header List
//  Shows all fetched news articles for review / monitoring.
// ============================================================
page 74117 "HK News Header List"
{
    Caption = 'News Articles';
    PageType = List;
    SourceTable = "HK News Header";
    UsageCategory = Lists;
    ApplicationArea = All;
    CardPageId = "HK News Header Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("News ID"; Rec."News ID")
                {
                    ApplicationArea = All;
                    Width = 8;
                }
                field("Published DateTime"; Rec."Published DateTime")
                {
                    ApplicationArea = All;
                    Width = 12;
                }
                field("Title EN"; Rec."Title EN")
                {
                    ApplicationArea = All;
                    Width = 50;
                }
                field("Title SI"; Rec."Title SI")
                {
                    ApplicationArea = All;
                    Width = 50;
                }
                field("Category"; Rec."Category")
                {
                    ApplicationArea = All;
                    Width = 6;
                }
                field("Total Comments"; Rec."Total Comments")
                {
                    ApplicationArea = All;
                    Width = 8;
                }
                field("Total Likes"; Rec."Total Likes")
                {
                    ApplicationArea = All;
                    Width = 8;
                }
                field("Status"; Rec."Status")
                {
                    ApplicationArea = All;
                    Width = 8;
                }
            }
        }
        area(FactBoxes)
        {
            systempart(Links; Links) { ApplicationArea = RecordLinks; }
            systempart(Notes; Notes) { ApplicationArea = Notes; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(FetchNews)
            {
                Caption = 'Refresh from API';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Fetch the latest news from the Helakuru API.';

                trigger OnAction()
                var
                    IntegrationMgt: Codeunit "HK News API Integration Mgt.";
                begin
                    IntegrationMgt.FetchAndStoreNews();
                    CurrPage.Update(false);
                end;
            }
            action(ArchiveSelected)
            {
                Caption = 'Archive';
                ApplicationArea = All;
                Image = Archive;
                ToolTip = 'Mark the selected news article as Archived.';

                trigger OnAction()
                begin
                    Rec."Status" := Rec."Status"::Archived;
                    Rec.Modify(true);
                end;
            }
        }
    }
}

// ============================================================
//  Page 74118 - HK News Header Card
//  Full article view including content lines.
// ============================================================
page 74118 "HK News Header Card"
{
    Caption = 'News Article';
    PageType = Document;
    SourceTable = "HK News Header";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Article)
            {
                Caption = 'Article';
                field("News ID"; Rec."News ID") { ApplicationArea = All; Editable = false; }
                field("Published DateTime"; Rec."Published DateTime") { ApplicationArea = All; Editable = false; }
                field("Status"; Rec."Status") { ApplicationArea = All; }
                field("Category"; Rec."Category") { ApplicationArea = All; Editable = false; }
            }
            group(Titles)
            {
                Caption = 'Titles';
                field("Title EN"; Rec."Title EN") { ApplicationArea = All; MultiLine = true; }
                field("Title SI"; Rec."Title SI") { ApplicationArea = All; MultiLine = true; }
            }
            group(Media)
            {
                Caption = 'Media';
                field("Thumb URL"; Rec."Thumb URL") { ApplicationArea = All; }
                field("Cover URL"; Rec."Cover URL") { ApplicationArea = All; }
                field("Share URL"; Rec."Share URL") { ApplicationArea = All; }
            }
            group(Engagement)
            {
                Caption = 'Engagement';
                field("Total Comments"; Rec."Total Comments") { ApplicationArea = All; }
                field("Comments Sin"; Rec."Comments Sin") { ApplicationArea = All; }
                field("Comments Eng"; Rec."Comments Eng") { ApplicationArea = All; }
                field("Comment Rate"; Rec."Comment Rate") { ApplicationArea = All; }
                field("Total Likes"; Rec."Total Likes") { ApplicationArea = All; }
                field("Total Love"; Rec."Total Love") { ApplicationArea = All; }
                field("Total Haha"; Rec."Total Haha") { ApplicationArea = All; }
                field("Total Wow"; Rec."Total Wow") { ApplicationArea = All; }
                field("Total Sad"; Rec."Total Sad") { ApplicationArea = All; }
                field("Total Angry"; Rec."Total Angry") { ApplicationArea = All; }
            }
            part(ContentLinesSI; "HK News Content Lines Part")
            {
                Caption = 'Content — Sinhala (SI)';
                ApplicationArea = All;
                SubPageLink = "News ID" = field("News ID");
                SubPageView = where("Language Code" = const('SI'));
            }
            part(ContentLinesEN; "HK News Content Lines Part")
            {
                Caption = 'Content — English (EN)';
                ApplicationArea = All;
                SubPageLink = "News ID" = field("News ID");
                SubPageView = where("Language Code" = const('EN'));
            }
        }
    }
}

// ============================================================
//  Page 74119 - HK News Content Lines Part
//  Repeater subpage used on the Card page to show content.
// ============================================================
page 74119 "HK News Content Lines Part"
{
    Caption = 'Content Lines';
    PageType = ListPart;
    SourceTable = "HK News Content Line";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Width = 6;
                }
                field("Content Type"; Rec."Content Type")
                {
                    ApplicationArea = All;
                    Width = 8;
                }
                field("Font Size"; Rec."Font Size")
                {
                    ApplicationArea = All;
                    Width = 8;
                }
                field("Alignment"; Rec."Alignment")
                {
                    ApplicationArea = All;
                    Width = 8;
                }
                field("Is Quote"; Rec."Is Quote")
                {
                    ApplicationArea = All;
                    Width = 6;
                }
                field(ContentPreview; Rec.GetContentData())
                {
                    Caption = 'Content';
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Preview of the paragraph text or image URL.';
                }
            }
        }
    }
}
