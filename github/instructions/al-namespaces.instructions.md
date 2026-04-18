---
description: Namespace conventions for AL code including COSMO-specific standards for customer projects and solution apps
applyTo: "**/*.al"
---

# Namespace Rules

Namespaces organize code, prevent naming conflicts, and improve code navigation. All COSMO projects with Business Central 23+ must use namespaces.

## Rule 1: Namespace Requirement and Limitations

### Intent

All AL objects (tables, pages, codeunits, enums, etc.) must include namespaces when targeting BC 23+. Important: Object names must still be prefixed (CCO/CCS) as namespaces do not yet eliminate the need for prefixes. Fields in extension objects must also be prefixed to avoid naming conflicts with other extensions. Even when extending objects that currently lack namespaces, use namespaces in your own objects to future-proof your code.

## Rule 2: Namespace Structure

### Intent

Use `CosmoConsult.Operations.<AppName>.<Area>.<Feature>` for CCO customer projects (ID 50000-99999) and `CosmoConsult.<Product>.<Area>.<Feature>` for CCS solution apps (ID >99999). Product/AppName excludes "COSMO" prefix. Area and Feature levels organize by functional domain, not object type. Area and Feature are optional for smaller solutions. Use PascalCase, avoid obscure product codes, use capital letters for acronyms. Keep namespaces focused on categorization, not detailed functionality.

### Examples

```al
// CCO Customer Projects
namespace CosmoConsult.Operations.CustomerPortal;
namespace CosmoConsult.Operations.CustomerPortal.SalesEnhancement;
namespace CosmoConsult.Operations.CustomerPortal.InventoryTracking;

// CCS Solution Apps - Simple
namespace CosmoConsult.VendorRating;
namespace CosmoConsult.DataIntegrationFramework;

// CCS Solution Apps - With area (and features)
namespace CosmoConsult.AdvancedManufacturingPack.ProcessManufacturing.Inventory;
namespace CosmoConsult.MobileSolution.Warehouse.ShippingIntegration;
namespace CosmoConsult.EDI.Automation;
namespace CosmoConsult.ProjectConstruction.IntegrationLibrary;

// Bad - Too detailed/specific (if table name is "CCS EDI Import Message")
namespace CosmoConsult.EDI.Automation.Import.Messages;  // Too specific

// Bad - Obscure codes
namespace CosmoConsult.MS.WH;  // Use full names: MobileSolution.Warehouse
```

## Rule 3: System Objects Best Practices (CCS)

### Intent

For common system-level objects in CCS solution apps, use `CosmoConsult.<Product>.System` namespace without further indents for the area / feature (like `Licensing`, `Install`, `Upgrade`, `Permissions`, ...). Place in appropriate subfolders for better organization while maintaining consistent namespace.

### Examples

```al
namespace CosmoConsult.Commission.System;
// Folders: ./app/src/System/Configuration, ./app/src/System/Licensing, ./app/src/System/Install, ./app/src/System/Upgrade, ./app/src/System/Permissions
```

## Rule 4: Test Namespaces

### Intent

At the moment, namespaces are not used in test apps.

## Rule 5: Namespace and Folder Alignment

### Intent

Maintain practical alignment between namespaces and folder structure for better code organization and navigation. While 1:1 relationship is recommended, prioritize logical namespace grouping over strict folder matching. Root feature folders should be reflected in namespaces.

### Examples

```al
// Good - Aligned structure
// Folder: ./app/src/Sales/Documents
namespace CosmoConsult.MyProduct.Sales.Documents;

// Folder: ./app/src/ProcessManufacturing/Production
namespace CosmoConsult.AdvancedManufacturingPack.ProcessManufacturing.Production;

// Acceptable - Grouped by namespace, different subfolders
// Folder: ./app/src/System/Configuration
// Folder: ./app/src/System/Licensing
namespace CosmoConsult.MyProduct.System;  // Same namespace, different folders
```

## Rule 6: Using Statements

### Intent
Use `using` statements within your code files whenever you need to reference objects from other namespaces. 

### Examples

```al
using Microsoft.Sales.Customer;

tableextension 50100 "CCO Customer Ext." extends Customer
{
    fields
    {
        field(50100; "Extension Field"; Integer)
        {
            Caption = 'Extension Field';
            DataClassification = CustomerContent;
        }
    }
}
```
