---
description: AL Error handling patterns, debugging techniques, and troubleshooting guidelines for AL development
applyTo: "**/*.al"
---

# AL Error Handling & Troubleshooting Rules

Robust error handling and effective troubleshooting practices are essential for maintaining reliable Business Central applications.

## Rule 1: Error Handling Strategies

### Intent
Choose the appropriate error handling strategy based on your scenario. AL provides multiple error handling mechanisms, each suited for specific situations. Understanding when to use each approach is critical for building robust applications.

### Strategy 1: Codeunit.Run() - Database Operations with Automatic Rollback

Use `if not Codeunit.Run()` when you need automatic transaction rollback on error. This is the **recommended approach for database write operations** that should be atomic (all-or-nothing).
**Key behavior:** When the return value is used (`if not ...` or `OK := ...`), errors are caught and return false. When not used, errors are exposed normally.

**When to use:**
- Posting operations (sales, purchase, inventory transactions)
- Any multi-record database updates that must succeed together
- Operations where partial completion would leave data in an inconsistent state

```al
// Good example - Using Codeunit.Run for automatic rollback
procedure PostSalesDocument(var SalesHeader: Record "Sales Header"): Boolean
var
  SalesPost: Codeunit "Sales-Post";
  PostingFailedErr: Label 'Failed to post sales document %1: %2', Comment = '%1 = Document No., %2 = Error message';
begin
  // Codeunit.Run returns false on error and rolls back ALL database changes
  if not SalesPost.Run(SalesHeader) then begin
    Message(PostingFailedErr, SalesHeader."No.", GetLastErrorText());
    // code continues to execute but the database changes of the failed sales post run are rolled back
    exit(false);
  end;
  
  exit(true);
end;
```

### Strategy 2: TryFunctions - Catch Errors Without Rollback

Use TryFunctions to catch errors/exceptions without stopping execution. **CRITICAL: TryFunctions do NOT roll back database transactions.**
**Key behavior:** When the return value is used (`if not Try...` or `OK := Try...`), errors are caught and return false. When not used, errors are exposed normally.

**When to use:**
- External API/web service calls
- File operations that might fail
- Calculations that could throw errors (division by zero, parsing)

**AVOID:**
- Database write operations (use Codeunit.Run instead)

```al
// Good example - TryFunction for external service call
procedure SyncWithExternalSystem(CustomerNo: Code[20])
var
  SyncFailedLbl: Label 'Failed to synchronize customer %1: %2', Comment = '%1 = Customer No., %2 = Error message';
begin
  if not TrySyncCustomer(CustomerNo) then begin
    Message(SyncFailedLbl, CustomerNo, GetLastErrorText());
    // ...
  end;
  // ...
end;

[TryFunction]
local procedure TrySyncCustomer(CustomerNo: Code[20])
var
  ExternalService: Codeunit "External Service";
begin
  // External call that might fail - appropriate for TryFunction
  ExternalService.SyncCustomerData(CustomerNo);
end;
```

```al
// Bad example - Database writes in TryFunction (changes will NOT roll back!)
[TryFunction]
local procedure TryUpdateInventory(var Item: Record Item; Quantity: Decimal)
begin
  Item.Inventory += Quantity;
  Item.Modify(true); // DANGEROUS: If an error occurs after this Modify, the change is NOT rolled back!
  // ...
end;
```

### Strategy 3: ErrorInfo - Rich Error Dialogs with Context

Use ErrorInfo to provide contextual error information with actionable guidance, detailed messages, and navigation actions.

**When to use:**
- User-facing errors that need explanation
- Errors where users can take corrective action
- Situations requiring navigation to related records/pages
- Errors that need detailed troubleshooting information

```al
// Good example - Using ErrorInfo for actionable error dialog
procedure ValidateCustomerCredit(var SalesHeader: Record "Sales Header")
var
  Customer: Record Customer;
  CreditLimitExceededErr: Label 'Credit limit exceeded for customer %1', Comment = '%1 = Customer No.';
  CreditDetailsMsg: Label 'Credit limit: %1, Current balance: %2, Order amount: %3', Comment = '%1 = Limit, %2 = Balance, %3 = Amount';
  ShowCustomerLbl: Label 'Show Customer';
  ErrorInfo: ErrorInfo;
begin
  Customer.Get(SalesHeader."Sell-to Customer No.");
  Customer.CalcFields(Balance);
  
  if (Customer.Balance + SalesHeader."Amount Including VAT") > Customer."Credit Limit (LCY)" then begin
    ErrorInfo.Title := StrSubstNo(CreditLimitExceededErr, Customer."No.");
    ErrorInfo.Message := StrSubstNo(CreditDetailsMsg, Customer."Credit Limit (LCY)", Customer.Balance, SalesHeader."Amount Including VAT");
    ErrorInfo.DetailedMessage := 'Contact customer for payment or request credit limit increase.';
    ErrorInfo.PageNo := Page::"Customer Card";
    ErrorInfo.RecordId := Customer.RecordId;
    ErrorInfo.AddNavigationAction(ShowCustomerLbl);
    Error(ErrorInfo);
  end;
end;
```

### Strategy 4: Collecting Errors - Bulk Validations

Use error collection to gather multiple validation errors and present them together, improving user experience by showing all issues at once rather than one at a time.

**When to use:**
- Validating multiple records or fields
- Import/data migration scenarios
- Batch processing with validation
- Any scenario where fixing multiple issues at once is more efficient

**Important:** Always handle collected errors explicitly. If errors remain when a procedure ends, users see a concatenated error dialog that can be confusing.

```al
// Good example - Collecting multiple validation errors
[ErrorBehavior(ErrorBehavior::Collect)]
procedure ValidateSalesLines(var SalesLine: Record "Sales Line")
var
  ErrorMessages: Record "Error Message" temporary;
  ErrorInfo: ErrorInfo;
  InsufficientInventoryErr: Label 'Line %1: Insufficient inventory for item %2', Comment = '%1 = Line No., %2 = Item No.';
begin
  if SalesLine.FindSet() then
    repeat
      // Collect all validation errors instead of stopping at first error
      if not CheckInventoryAvailable(SalesLine) then
        Error(ErrorInfo.Create(StrSubstNo(InsufficientInventoryErr, SalesLine."Line No.", SalesLine."No."), true, SalesLine, SalesLine.FieldNo("No.")));
    until SalesLine.Next() = 0;
  
  // Handle collected errors
  if HasCollectedErrors then begin
    foreach ErrorInfo in system.GetCollectedErrors() do begin
      ErrorMessages.ID += 1;
      ErrorMessages.Message := ErrorInfo.Message;
      ErrorMessages."Record ID" := ErrorInfo.RecordId;
      ErrorMessages.Insert();
    end;
    
    ClearCollectedErrors();
    Page.RunModal(Page::"Error Messages", ErrorMessages);
  end;
end;
```

## Rule 2: Use Error Labels for All Messages

### Intent
All error messages, warnings, and user messages must use label variables instead of hardcoded text. This ensures proper localization support and maintainability. Define labels with appropriate comments for translators and use Locked = true for technical messages that should not be translated.

## Rule 3: Custom Telemetry Implementation

### Intent
Add custom telemetry for tracking business-critical operations, but only when explicitly requested by the user. Use Session.LogMessage for custom telemetry with appropriate verbosity levels and data classification. Include relevant custom dimensions for context and use proper telemetry scope for extension publishers.

### Examples

```al
// Good example - Custom telemetry (only when user explicitly requests it)
// Use TryFunctions for external calls/validations, not database posting operations
procedure ValidateAndSyncCustomerData(CustomerNo: Code[20])
var
  TelemetryCustomDimensions: Dictionary of [Text, Text];
  DataSyncSuccessMsg: Label 'Customer data synchronized successfully', Locked = true;
  DataSyncFailedMsg: Label 'Customer data synchronization failed', Locked = true;
begin
  // Add context for telemetry
  TelemetryCustomDimensions.Add('CustomerNo', CustomerNo);
  
  // TryFunction for external service call (appropriate use case)
  if TrySyncCustomerDataWithExternalService(CustomerNo) then begin
    // Log successful operation
    Session.LogMessage('CUS001', DataSyncSuccessMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryCustomDimensions);
  end else begin
    // Log failed operation with error details
    TelemetryCustomDimensions.Add('ErrorText', GetLastErrorText());
    Session.LogMessage('CUS002', DataSyncFailedMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryCustomDimensions);
  end;
end;
```