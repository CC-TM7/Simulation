---
description: AL Translation Guidelines for Captions, ToolTips, Labels and all other translatable properties
applyTo: "**/*.al"
---

# Translations in AL Source Code

All AL Source Code is written in english and is translated through one .xliff file per language. For the creation of the .xliff file the XLIFF Sync extension is used. Follow these rules to ensure proper creation of translations.

## Rule 1 Define Translations in AL Code
### Intent
For customer projects (ID range 50000-99999) Translations are defined within the AL Source Code using the AL comments functionality the following properties: Caption, ToolTip, Label, OptionCaption, AdditionalSearchTerms, AboutText, AboutTitle, Summary. For products (ID range >99999) Translations are defined within the XLIFF files only and must not be added in the AL Source Code.

### Examples
```al
// Good example - Translations Definition for Labels
procedure HelloWorld()
var
    HelloWorldLbl: Label 'Hello World', Comment = 'de-DE=Hallo Welt||fr-FR=Bonjour le monde';
begin
    Message(HelloWorldLbl);
end;
```

```al
// Good example - Translations Definition for Captions and ToolTips
table 50100 "CCO My Table"
{
    Caption = 'My Table', Comment = 'de-DE=Meine Tabelle';
    DataClassification = CustomerContent;

    fields
    {
        field(1; MyField; Integer)
        {
            Caption = 'My Field', Comment = 'de-DE=Mein Feld||fr-FR=Mon champ';
            ToolTip = 'Specifies the value of the MyField field.', Comment = 'de-DE=Gibt den Wert des Felds MyField an.||fr-FR=Indique la valeur de mon champ.';
        }
    }
}
```

## Rule 2 Check the supported Languages and used separators
### Intent 
Only add Translation using the developer comments for supported languages. Check the "supportedLocales" in the app.json of the current project for the supported languages. If none are defined do not add translation comments.

## Rule 3 Lock fixed texts
### Intent 
If the english text of a label, caption or other property is a constant value that doesn't contain any alphabetic characters, don't add translation comments. Instead add the property Locked = true to this property.

### Examples
```al
// Good example - no translation for empty enum value
enum 50100 "CCO My Enum"
{
    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
}
```