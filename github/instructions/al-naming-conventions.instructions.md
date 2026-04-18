---
description: Comprehensive naming conventions for AL files, objects, variables, and functions including COSMO-specific standards
applyTo: "**/*.al"
---

# Naming Conventions Rules

Consistent naming conventions improve code readability, maintainability, and help AI assistants understand code structure and intent.

## Rule 1: Object Prefixes and Naming (COSMO-Specific)

### Intent

All COSMO objects must be prefixed to avoid naming conflicts. Use "CCO" for customer projects (ID 50000-99999; these are customer-specific apps/extensions) or "CCS <SolutionPrefix>" for solution apps (ID >99999; these are sold and licensed as products). Use PascalCase with spaces, avoid capslock except for prefix. Names must not exceed 30 characters total. Follow Microsoft Base App naming patterns and abbreviations (e.g., `No.` instead of `Number`).

### Examples

```al
// CCO (Customer Projects) - Full Objects
table 50100 "CCO Customer Ledger Entry"
page 50101 "CCO Sales Invoice"
codeunit 50102 "CCO Sales Posting"

tableextension 50103 "CCO Item Card Ext." extends Item
pageextension 50104 "CCO Sales Header Ext." extends "Sales Header"
codeunit 50105 "CCO Sales Events Sub."

// CCS (Solution Apps) - Requires solution prefix
table 5100100 "CCS DIS Setup"
page 5100101 "CCS TEX Configuration"
codeunit 5100102 "CCS DMS Document Handler"
tableextension 5100103 "CCS TM Sales Header Ext." extends "Sales Header"
table 5100104 "CCS DMS SUB Archive Setup"

// Bad examples
table 50100 "CCOTEXSETUP"                         // No spaces, all caps
table 50101 "cco sales invoice"                   // Lowercase prefix
table 50102 "CCO Very Long Customer Ledger Entry" // 35 chars - exceeds limit
codeunit 5100100 "CCS TEX ADAPTER"                // All caps name
```

## Rule 2: File Naming Conventions

### Intent

Follow Microsoft's file naming notation: `<ObjectNameExcludingAffix>.<FullTypeName>.al` for full objects and `<ObjectNameExcludingAffix>.<FullTypeName>Ext.al` for extensions. Exclude the CCO/CCS prefix from filenames. For multiple extensions of same object, add feature/prefix name to filename.

### Examples

```al
// Full Objects (exclude CCO/CCS prefix from filename)
SalesSetup.Table.al               // object: "CCO Sales Setup"
CustomerCard.Page.al              // object: "CCO Customer Card"
ServiceProcessor.Codeunit.al      // object: "CCS DIS Service Processor"

// Extension Objects
ItemCard.PageExt.al               // object: "CCO Item Card Ext."
SalesHeader.TableExt.al           // object: "CCO Sales Header Ext."
DISSomeSetup.PageExt.al           // object: "CCS DIS Some Setup Ext."

// Multiple extensions of same object
FeatureItemCard.PageExt.al
AnotherPrefixItemCard.PageExt.al

// Interfaces and Implementations
ICustomerService.Interface.al
CustomerServiceImpl.Codeunit.al

// Test files
SalesPostingTests.Codeunit.al

## Rule 3: Global Procedures in Extensions

### Intent

Global procedures in extension objects (table/page extensions) and public keys in table extensions must start with the prefix without spaces, for CCS apps including the solution prefix (e.g., `CCSDIS`, `CCSTEX`, `CCO`), to ensure uniqueness and avoid conflicts with other apps in the same database.

### Examples

```al
// Good examples - CCS global procedures
tableextension 5100100 "CCS CA Item Ext." extends Item
{
    keys
    {
        key(CCSCAItemKey; "No.", "CCS CA Custom Field") { }
    }
    
    procedure CCSCACalculateUnitCost(): Decimal
    begin
        // Implementation
    end;
    
    procedure CCSCAValidateInventory(): Boolean
    begin
        // Implementation
    end;
}

// Bad examples
tableextension 5100100 "CCS CA Item Ext." extends Item
{
    procedure CalculateUnitCost(): Decimal  // Missing prefix
    procedure CCS CA ValidateInventory()     // Has spaces in prefix
}
```

## Rule 4: Page Captions and Search Terms (CCS Only)

### Intent

For CCS solution apps with UsageCategory property, use format `<Functionality> - <Shortened App Name>` for captions. Include affixes, English object name, and custom terms in AdditionalSearchTerms (locked for translation). Name lists in plural or append "List". Setup pages should follow `<Shortened App | Module> Setup` pattern.

### Examples

```al
// Good example
page 5100960 "CCS DIS Mappings"
{
    Caption = 'Mappings - Data Integration Framework';
    AdditionalSearchTerms = 'DIS Mappings, DIF Mappings', Locked = true;
    UsageCategory = Lists;
    ApplicationArea = CCSDIS;
}

page 5100961 "CCS DIS Setup"
{
    Caption = 'Data Integration Framework Setup';
    AdditionalSearchTerms = 'DIS Setup, DIF Setup', Locked = true;
    UsageCategory = Administration;
}
```

## Rule 5: Test and Demo App Naming (CCS Only)

### Intent

Demo dataset apps must use unique prefix (add "D" after main prefix, e.g., CMID). Test apps should add "T" (e.g., CMIT). Test libraries use pattern `CCS <SolutionPrefix> Library - <Feature>`, test codeunits use `CCS <SolutionPrefix> <Feature> Tests`.

### Examples

```al
// Test library
codeunit 50000 "CCS CMIT Library - Contact"
{
    procedure CreateContact(var Contact: Record Contact)
    begin
        Contact."No." := '1234';
        Contact.Insert(true);
    end;
}

// Test codeunit
codeunit 50001 "CCS CMIT Contact Tests"
{
    Subtype = Test;
    
    [Test]
    procedure TestCreateContact()
    var
        Contact: Record Contact;
        ContactLib: Codeunit "CCS CMIT Library - Contact";
    begin
        ContactLib.CreateContact(Contact);
        Assert.IsTrue(Contact.FindSet(), 'Contact not created.');
    end;
}
```

## Rule 6: Variable and Function Naming

### Intent

Use PascalCase for variable and function names with descriptive names that clearly indicate purpose. Avoid abbreviations unless they are well-known business terms. Use consistent parameter naming and descriptive names in event subscribers (avoid generic names like "Rec").

### Examples

```al
// Good examples - Variables
var
    CustomerLedgerEntry: Record "Cust. Ledger Entry";
    TotalAmount: Decimal;
    IsValidTransaction: Boolean;

// Good examples - Functions
procedure CalculateCustomerBalance(CustomerNo: Code[20]): Decimal
procedure ValidateSalesDocument(var SalesHeader: Record "Sales Header")

// Good example - Event Subscriber
[EventSubscriber(ObjectType::Table, Database::"Sales Header", OnBeforeInsert, '', false, false)]
local procedure AddDefaultValuesOnBeforeInsertSalesHeader(var SalesHeader: Record "Sales Header"; RunTrigger: Boolean)
begin
    // Event handling logic
end;
```

## Rule 7: Interface and Implementation Naming

### Intent

Prefix interfaces with "I", use "Impl" suffix for implementation codeunits. Keep names closely related and within character limits. Apply CCO/CCS prefix rules to object names.

### Examples

```al
// Interface file: ICustomerService.Interface.al
interface ICustomerService
{
    procedure GetCustomerBalance(CustomerNo: Code[20]): Decimal;
}

// Implementation file: CustomerServiceImpl.Codeunit.al
codeunit 50100 "CCO Customer Service Impl" implements ICustomerService
{
    procedure GetCustomerBalance(CustomerNo: Code[20]): Decimal
    begin
        // Implementation
    end;
}
```