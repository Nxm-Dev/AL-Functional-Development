// ============================================================
//  Enum 74110 - HK Content Type
//  Used by HK News Content Line table field "Content Type"
// ============================================================
enum 74110 "HK Content Type"
{
    Extensible = true;
    Caption = 'Content Type';

    value(0; Text)
    {
        Caption = 'Text';
    }
    value(1; Image)
    {
        Caption = 'Image';
    }
}
