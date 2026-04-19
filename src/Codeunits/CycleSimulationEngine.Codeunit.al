/// <summary>
/// Codeunit "Cycle Simulation Engine" implements the discrete-time Cobweb Model.
///
/// Mathematical model
/// ─────────────────
///   Demand:          D(t) = a - b·P(t)
///   Supply:          S(t) = c + d·P(t-1)          ← one-period production lag
///   Price update:    P(t+1) = P(t) + k·(D(t)−S(t))
///
/// Equilibrium price P*:
///   At equilibrium D = S → a - b·P* = c + d·P*
///   → P* = (a − c) / (b + d)
///
/// Stability condition (|d/b| &lt; 1):
///   Stable      if d/b &lt; 1  (oscillations dampen)
///   Oscillating if d/b = 1  (constant-amplitude oscillations)
///   Exploding   if d/b > 1  (oscillations amplify)
///
/// Usage
/// ─────
///   1. Call RunSimulation() to execute a full simulation using the current setup.
///   2. Call ResetSimulation() to delete all previous entries.
///   3. Export via ExportToExcelBuffer() if further analysis is needed.
/// </summary>
codeunit 50300 "Cycle Simulation Engine"
{
    /// <summary>
    /// Runs a full simulation based on the current "Cycle Simulation Setup".
    ///
    /// Steps:
    ///   1. Load and validate parameters from the setup table.
    ///   2. Delete any existing simulation entries.
    ///   3. Iterate t = 0 … NumPeriods-1, computing D(t), S(t), P(t+1).
    ///   4. Persist each time step as a "Cycle Simulation Entry" record.
    ///   5. Classify the overall system behavior and stamp the last entry.
    /// </summary>
    procedure RunSimulation()
    var
        Setup: Record "Cycle Simulation Setup";
        SimHistory: Record "Cycle Simulation History";
        SimEntry: Record "Cycle Simulation Entry";
        BehaviorType: Enum "Cycle Behavior Type";
        // ── parameters ──────────────────────────────────────────────────────────
        ParamA: Decimal;  // demand intercept
        ParamB: Decimal;  // demand slope
        ParamC: Decimal;  // supply intercept
        ParamD: Decimal;  // supply slope
        ParamK: Decimal;  // price-adjustment speed
        // ── state variables ──────────────────────────────────────────────────────
        CurrentPrice: Decimal;      // P(t)
        PreviousPrice: Decimal;     // P(t-1)  — drives S(t)
        CurrentDemand: Decimal;     // D(t)
        CurrentSupply: Decimal;     // S(t)
        ExcessDemand: Decimal;      // D(t) - S(t)
        NextPrice: Decimal;         // P(t+1)
        // ── loop control ─────────────────────────────────────────────────────────
        NumPeriods: Integer;
        TimeStep: Integer;
        ActualPeriods: Integer;
        // ── stability guard ───────────────────────────────────────────────────────
        MaxAbsPrice: Decimal;
        ExplodingThreshold: Decimal;
        ConvergenceTolerance: Decimal;
        StoppedEarly: Boolean;
        SimStoppedEarlyMsg: Label 'Simulation stopped early at time step %1: price exceeded stability threshold (%2).', Comment = '%1 = Time Step, %2 = Threshold';
        SimConvergedMsg: Label 'Simulation converged at time step %1: price change below tolerance (%2).', Comment = '%1 = Time Step, %2 = Tolerance';
        SimCompletedMsg: Label 'Simulation completed all %1 periods. Final price: %2.', Comment = '%1 = Number of Periods, %2 = Final Price';
    begin
        // ── 1. Load validated setup ───────────────────────────────────────────────
        Setup.GetSetup(Setup);
        ValidateSetup(Setup);

        ParamA := Setup."Parameter A";
        ParamB := Setup."Parameter B";
        ParamC := Setup."Parameter C";
        ParamD := Setup."Parameter D";
        ParamK := Setup."Adjustment Factor K";
        CurrentPrice := Setup."Initial Price";
        NumPeriods := Setup."Number of Periods";

        // ── 2. Create history header ─────────────────────────────────────────────
        SimHistory := CreateHistoryRecord(Setup);

        // ── 3. Initialise loop state ─────────────────────────────────────────────
        // At t = 0 there is no prior period, so S(0) uses P(-1) ≡ P(0).
        PreviousPrice := CurrentPrice;
        ExplodingThreshold := 1000000000; // guard against IEEE overflow
        ConvergenceTolerance := 0.00001; // stop when price change is negligible
        MaxAbsPrice := 0;
        ActualPeriods := 0;
        StoppedEarly := false;

        // ── 4. Main simulation loop ──────────────────────────────────────────────
        for TimeStep := 0 to NumPeriods - 1 do begin
            // D(t) = a - b·P(t)
            CurrentDemand := ParamA - ParamB * CurrentPrice;

            // S(t) = c + d·P(t-1)
            CurrentSupply := ParamC + ParamD * PreviousPrice;

            // Δ(t) = D(t) - S(t)
            ExcessDemand := CurrentDemand - CurrentSupply;

            // Persist time-step record
            Clear(SimEntry);
            SimEntry."Simulation No." := SimHistory."Simulation No.";
            SimEntry."Time Step" := TimeStep;
            SimEntry."Price" := CurrentPrice;
            SimEntry."Demand" := CurrentDemand;
            SimEntry."Supply" := CurrentSupply;
            SimEntry."Delta" := ExcessDemand;
            SimEntry."Created At" := CurrentDateTime();
            SimEntry.Insert();

            ActualPeriods += 1;

            // Track maximum absolute price to help detect divergence
            if Abs(CurrentPrice) > MaxAbsPrice then
                MaxAbsPrice := Abs(CurrentPrice);

            // Abort early if price is exploding beyond the safety threshold
            if Abs(CurrentPrice) > ExplodingThreshold then begin
                Message(SimStoppedEarlyMsg, TimeStep, ExplodingThreshold);
                StoppedEarly := true;
                break;
            end;

            // P(t+1) = P(t) + k·(D(t) − S(t))
            NextPrice := CurrentPrice + ParamK * ExcessDemand;

            // Stop early if price has converged (change is negligible)
            if (TimeStep > 0) and (Abs(NextPrice - CurrentPrice) < ConvergenceTolerance) then begin
                Message(SimConvergedMsg, TimeStep, ConvergenceTolerance);
                StoppedEarly := true;
                break;
            end;

            // Advance state
            PreviousPrice := CurrentPrice;
            CurrentPrice := NextPrice;
        end;

        if not StoppedEarly then
            Message(SimCompletedMsg, ActualPeriods, Format(CurrentPrice, 0, '<Precision,5><Standard Format,2>'));

        // ── 5. Classify behavior, stamp entries and update history ─────────────
        BehaviorType := ClassifyBehavior(Setup);
        StampBehaviorType(SimHistory."Simulation No.", BehaviorType);
        FinalizeHistoryRecord(SimHistory, BehaviorType, ActualPeriods);
    end;

    /// <summary>
    /// Deletes all records in the "Cycle Simulation Entry" table.
    /// Call before re-running to start fresh.
    /// </summary>
    procedure ResetSimulation()
    var
        SimEntry: Record "Cycle Simulation Entry";
        SimHistory: Record "Cycle Simulation History";
        SimDataResetMsg: Label 'Simulation data has been reset.';
    begin
        SimEntry.DeleteAll();
        SimHistory.DeleteAll();
        Message(SimDataResetMsg);
    end;

    /// <summary>
    /// Exports simulation results to an Excel buffer for download.
    ///
    /// Columns: Time Step | Price | Demand | Supply | Delta | Behavior Type
    /// </summary>
    procedure ExportToExcelBuffer()
    var
        ExcelBuffer: Record "Excel Buffer" temporary;
        SimEntry: Record "Cycle Simulation Entry";
        RowNo: Integer;
        TimeStepLbl: Label 'Time Step';
        PriceLbl: Label 'Price P(t)';
        DemandLbl: Label 'Demand D(t)';
        SupplyLbl: Label 'Supply S(t)';
        DeltaLbl: Label 'Delta D-S';
        BehaviorTypeLbl: Label 'Behavior Type';
    begin
        ExcelBuffer.DeleteAll();
        RowNo := 1;

        // Header row
        AddExcelCell(ExcelBuffer, RowNo, 1, TimeStepLbl, true);
        AddExcelCell(ExcelBuffer, RowNo, 2, PriceLbl, true);
        AddExcelCell(ExcelBuffer, RowNo, 3, DemandLbl, true);
        AddExcelCell(ExcelBuffer, RowNo, 4, SupplyLbl, true);
        AddExcelCell(ExcelBuffer, RowNo, 5, DeltaLbl, true);
        AddExcelCell(ExcelBuffer, RowNo, 6, BehaviorTypeLbl, true);

        // Data rows
        SimEntry.SetCurrentKey("Time Step");
        SimEntry.SetLoadFields("Time Step", Price, Demand, Supply, Delta, "Behavior Type");
        if SimEntry.FindSet() then
            repeat
                RowNo += 1;
                AddExcelCell(ExcelBuffer, RowNo, 1, Format(SimEntry."Time Step"), false);
                AddExcelCell(ExcelBuffer, RowNo, 2, Format(SimEntry.Price, 0, '<Precision,5><Standard Format,2>'), false);
                AddExcelCell(ExcelBuffer, RowNo, 3, Format(SimEntry.Demand, 0, '<Precision,5><Standard Format,2>'), false);
                AddExcelCell(ExcelBuffer, RowNo, 4, Format(SimEntry.Supply, 0, '<Precision,5><Standard Format,2>'), false);
                AddExcelCell(ExcelBuffer, RowNo, 5, Format(SimEntry.Delta, 0, '<Precision,5><Standard Format,2>'), false);
                AddExcelCell(ExcelBuffer, RowNo, 6, Format(SimEntry."Behavior Type"), false);
            until SimEntry.Next() = 0;

        ExcelBuffer.CreateNewBook('Cobweb Simulation');
        ExcelBuffer.WriteSheet('Results', CompanyName(), UserId());
        ExcelBuffer.CloseBook();
        ExcelBuffer.SetFriendlyFilename('CobwebSimulation');
        ExcelBuffer.OpenExcel();
    end;

    // ════════════════════════════════════════════════════════════════════════════
    //  Private helpers
    // ════════════════════════════════════════════════════════════════════════════

    /// <summary>
    /// Validates that all mandatory parameters have meaningful values.
    /// Raises an error for any invalid configuration before the simulation starts.
    /// </summary>
    local procedure ValidateSetup(Setup: Record "Cycle Simulation Setup")
    var
        SetupErrorInfo: ErrorInfo;
        ParamAErr: Label 'Parameter A (demand intercept) must be greater than zero.';
        ParamBErr: Label 'Parameter B (demand slope) must be greater than zero.';
        ParamDErr: Label 'Parameter D (supply slope) must be greater than zero.';
        AdjFactorKErr: Label 'Adjustment Factor K must be greater than zero.';
        InitialPriceErr: Label 'Initial Price must be zero or positive.';
        NumPeriodsErr: Label 'Number of Periods must be at least 2.';
    begin
        SetupErrorInfo.PageNo := Page::"Cycle Simulation Setup";
        SetupErrorInfo.RecordId := Setup.RecordId;

        if Setup."Parameter A" <= 0 then begin
            SetupErrorInfo.Message := ParamAErr;
            SetupErrorInfo.FieldNo := Setup.FieldNo("Parameter A");
            Error(SetupErrorInfo);
        end;
        if Setup."Parameter B" <= 0 then begin
            SetupErrorInfo.Message := ParamBErr;
            SetupErrorInfo.FieldNo := Setup.FieldNo("Parameter B");
            Error(SetupErrorInfo);
        end;
        if Setup."Parameter D" <= 0 then begin
            SetupErrorInfo.Message := ParamDErr;
            SetupErrorInfo.FieldNo := Setup.FieldNo("Parameter D");
            Error(SetupErrorInfo);
        end;
        if Setup."Adjustment Factor K" <= 0 then begin
            SetupErrorInfo.Message := AdjFactorKErr;
            SetupErrorInfo.FieldNo := Setup.FieldNo("Adjustment Factor K");
            Error(SetupErrorInfo);
        end;
        if Setup."Initial Price" < 0 then begin
            SetupErrorInfo.Message := InitialPriceErr;
            SetupErrorInfo.FieldNo := Setup.FieldNo("Initial Price");
            Error(SetupErrorInfo);
        end;
        if Setup."Number of Periods" < 2 then begin
            SetupErrorInfo.Message := NumPeriodsErr;
            SetupErrorInfo.FieldNo := Setup.FieldNo("Number of Periods");
            Error(SetupErrorInfo);
        end;
    end;

    /// <summary>
    /// Classifies overall system behavior based on the ratio d/b.
    ///
    /// Theoretical result (Cobweb theorem):
    ///   d/b &lt; 1  → supply reacts less than demand → price deviations shrink → Stable
    ///   d/b = 1  → equal reactions → constant cycles → Oscillating
    ///   d/b > 1  → supply over-reacts → deviations grow  → Exploding
    ///
    /// A small tolerance band (±5 %) is used around unity to avoid mis-classifying
    /// borderline cases caused by floating-point arithmetic.
    /// </summary>
    local procedure ClassifyBehavior(Setup: Record "Cycle Simulation Setup"): Enum "Cycle Behavior Type"
    var
        Ratio: Decimal;
        Tolerance: Decimal;
    begin
        Tolerance := 0.05; // 5 % band around d/b = 1

        if Setup."Parameter B" = 0 then
            exit(Enum::"Cycle Behavior Type"::Exploding);

        Ratio := Setup."Parameter D" / Setup."Parameter B";

        if Ratio < (1 - Tolerance) then
            exit(Enum::"Cycle Behavior Type"::Stable)
        else
            if Ratio > (1 + Tolerance) then
                exit(Enum::"Cycle Behavior Type"::Exploding)
            else
                exit(Enum::"Cycle Behavior Type"::Oscillating);
    end;

    /// <summary>
    /// Writes the computed BehaviorType onto the last simulation entry so users can
    /// identify the classification directly from the list page.
    /// </summary>
    local procedure StampBehaviorType(SimulationNo: Integer; BehaviorType: Enum "Cycle Behavior Type")
    var
        SimEntry: Record "Cycle Simulation Entry";
    begin
        SimEntry.SetCurrentKey("Simulation No.", "Time Step");
        SimEntry.SetRange("Simulation No.", SimulationNo);
        SimEntry.SetLoadFields("Behavior Type");
        if SimEntry.FindLast() then begin
            SimEntry."Behavior Type" := BehaviorType;
            SimEntry.Modify();
        end;
    end;

    /// <summary>
    /// Creates a new history header record with a snapshot of all setup parameters.
    /// </summary>
    local procedure CreateHistoryRecord(Setup: Record "Cycle Simulation Setup"): Record "Cycle Simulation History"
    var
        SimHistory: Record "Cycle Simulation History";
        Denominator: Decimal;
    begin
        SimHistory.Init();
        SimHistory."Parameter A" := Setup."Parameter A";
        SimHistory."Parameter B" := Setup."Parameter B";
        SimHistory."Parameter C" := Setup."Parameter C";
        SimHistory."Parameter D" := Setup."Parameter D";
        SimHistory."Adjustment Factor K" := Setup."Adjustment Factor K";
        SimHistory."Initial Price" := Setup."Initial Price";
        SimHistory."Number of Periods" := Setup."Number of Periods";
        SimHistory."Item No." := Setup."Item No.";
        SimHistory."Created At" := CurrentDateTime();
        SimHistory."Created By" := CopyStr(UserId(), 1, MaxStrLen(SimHistory."Created By"));

        Denominator := Setup."Parameter B" + Setup."Parameter D";
        if Denominator <> 0 then
            SimHistory."Equilibrium Price" := (Setup."Parameter A" - Setup."Parameter C") / Denominator;

        SimHistory.Insert(true);
        exit(SimHistory);
    end;

    /// <summary>
    /// Updates the history record with the final behavior classification and actual period count.
    /// </summary>
    local procedure FinalizeHistoryRecord(var SimHistory: Record "Cycle Simulation History"; BehaviorType: Enum "Cycle Behavior Type"; ActualPeriods: Integer)
    begin
        SimHistory."Behavior Type" := BehaviorType;
        SimHistory."Actual Periods" := ActualPeriods;
        SimHistory.Modify();
    end;

    /// <summary>
    /// Returns a formatted string showing the d/b ratio and its behavioral implication.
    /// Used by the Setup page to display the stability indicator.
    /// </summary>
    procedure GetStabilityRatioText(Setup: Record "Cycle Simulation Setup"): Text
    var
        Ratio: Decimal;
        StabilityTolerance: Decimal;
        NotAvailableLbl: Label 'N/A (B = 0)', Locked = true;
        StableLbl: Label '%1 → Stable (convergent)';
        ExplodingLbl: Label '%1 → Exploding (divergent)';
        OscillatingLbl: Label '%1 → Oscillating (neutral)';
    begin
        if Setup."Parameter B" = 0 then
            exit(NotAvailableLbl);

        StabilityTolerance := 0.05; // 5 % band around d/b = 1
        Ratio := Setup."Parameter D" / Setup."Parameter B";

        if Ratio < (1 - StabilityTolerance) then
            exit(StrSubstNo(StableLbl, Format(Ratio, 0, '<Precision,4><Standard Format,2>')))
        else
            if Ratio > (1 + StabilityTolerance) then
                exit(StrSubstNo(ExplodingLbl, Format(Ratio, 0, '<Precision,4><Standard Format,2>')))
            else
                exit(StrSubstNo(OscillatingLbl, Format(Ratio, 0, '<Precision,4><Standard Format,2>')));
    end;

    /// <summary>
    /// Returns the theoretical equilibrium price P* = (A − C) / (B + D).
    /// At equilibrium D(t) = S(t), so excess demand is zero and price stabilises.
    /// </summary>
    procedure GetEquilibriumPriceText(Setup: Record "Cycle Simulation Setup"): Text
    var
        Denominator: Decimal;
        EquilPrice: Decimal;
        NotAvailableLbl: Label 'N/A', Locked = true;
    begin
        Denominator := Setup."Parameter B" + Setup."Parameter D";
        if Denominator = 0 then
            exit(NotAvailableLbl);

        EquilPrice := (Setup."Parameter A" - Setup."Parameter C") / Denominator;
        exit(Format(EquilPrice, 0, '<Precision,4><Standard Format,2>'));
    end;

    /// <summary>
    /// Writes a single cell value into the temporary Excel buffer.
    /// Bold is applied when IsHeader = true to distinguish the header row.
    /// </summary>
    local procedure AddExcelCell(var ExcelBuffer: Record "Excel Buffer"; RowNo: Integer; ColNo: Integer; CellValue: Text; IsHeader: Boolean)
    begin
        ExcelBuffer.Init();
        ExcelBuffer.Validate("Row No.", RowNo);
        ExcelBuffer.Validate("Column No.", ColNo);
        ExcelBuffer."Cell Value as Text" := CopyStr(CellValue, 1, MaxStrLen(ExcelBuffer."Cell Value as Text"));
        ExcelBuffer.Bold := IsHeader;
        ExcelBuffer.Insert();
    end;

    /// <summary>
    /// Calculates simulation parameters A, B, C, D, K, and Initial Price from
    /// Item Ledger Entries for the given item, grouped by month.
    ///
    /// Approach (simple linear regression):
    ///   1. Group demand entries (Sale, Consumption, Assembly Consumption) by month
    ///      → (AvgPrice, TotalQty) per period → Demand curve
    ///   2. Group supply entries (Purchase, Output, Assembly Output) by month
    ///      → (AvgCost, TotalQty) per period → Supply curve
    ///   3. Linear regression Qty = A - B·Price  →  demand parameters A, B
    ///   4. Linear regression Qty = C + D·Price(t-1) →  supply parameters C, D
    ///   5. K estimated from average price change per unit excess demand
    ///   6. Initial Price = latest Item."Unit Price"
    /// </summary>
    procedure CalculateFromItemLedger(var Setup: Record "Cycle Simulation Setup"; ItemNo: Code[20])
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        // ── Demand regression accumulators ───────────────────────────────────────
        DemandN: Integer;
        DemandSumX: Decimal;   // ΣPrice
        DemandSumY: Decimal;   // ΣQty
        DemandSumXX: Decimal;  // ΣPrice²
        DemandSumXY: Decimal;  // Σ(Price·Qty)
        // ── Supply regression accumulators ───────────────────────────────────────
        SupplyN: Integer;
        SupplySumX: Decimal;   // ΣPrice
        SupplySumY: Decimal;   // ΣQty
        SupplySumXX: Decimal;  // ΣPrice²
        SupplySumXY: Decimal;  // Σ(Price·Qty)
        // ── Period aggregation ───────────────────────────────────────────────────
        PeriodStart: Date;
        PeriodPrice: Decimal;
        PeriodQty: Decimal;
        PeriodCount: Integer;
        PeriodAmount: Decimal;
        UnitAmount: Decimal;
        // ── Regression results ───────────────────────────────────────────────────
        Denominator: Decimal;
        CalcA: Decimal;
        CalcB: Decimal;
        CalcC: Decimal;
        CalcD: Decimal;
        // ── Error messages ───────────────────────────────────────────────────────
        NoDemandDataErr: Label 'No demand entries (Sale, Consumption, Assembly Consumption) found for item %1.', Comment = '%1 = Item No.';
        NoSupplyDataErr: Label 'No supply entries (Purchase, Output, Assembly Output) found for item %1.', Comment = '%1 = Item No.';
        InsufficientDataErr: Label 'At least 3 months of data are required for regression. Found: %1 demand months, %2 supply months.', Comment = '%1 = Demand months, %2 = Supply months';
        ParametersCalculatedMsg: Label 'Parameters calculated from item %1:\A = %2, B = %3, C = %4, D = %5, K = %6\Initial Price = %7', Comment = '%1 = Item No., %2..%7 = parameter values';
    begin
        Item.Get(ItemNo);

        // ── Calculate Demand parameters (Sale, Consumption, Assembly Consumption) ─
        DemandN := 0;
        ItemLedgerEntry.SetCurrentKey("Item No.", "Posting Date");
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetFilter("Entry Type", '%1|%2|%3',
            ItemLedgerEntry."Entry Type"::Sale,
            ItemLedgerEntry."Entry Type"::Consumption,
            ItemLedgerEntry."Entry Type"::"Assembly Consumption");
        ItemLedgerEntry.SetFilter("Posting Date", '%1..', CalcDate('<-24M>', WorkDate()));

        if not ItemLedgerEntry.FindSet() then
            Error(NoDemandDataErr, ItemNo);

        PeriodStart := CalcDate('<-CM>', ItemLedgerEntry."Posting Date");
        PeriodQty := 0;
        PeriodAmount := 0;
        PeriodCount := 0;

        repeat
            if CalcDate('<-CM>', ItemLedgerEntry."Posting Date") <> PeriodStart then begin
                // Flush previous period
                if PeriodCount > 0 then begin
                    PeriodPrice := PeriodAmount / PeriodCount;
                    DemandN += 1;
                    DemandSumX += PeriodPrice;
                    DemandSumY += Abs(PeriodQty);
                    DemandSumXX += PeriodPrice * PeriodPrice;
                    DemandSumXY += PeriodPrice * Abs(PeriodQty);
                end;
                PeriodStart := CalcDate('<-CM>', ItemLedgerEntry."Posting Date");
                PeriodQty := 0;
                PeriodAmount := 0;
                PeriodCount := 0;
            end;
            PeriodQty += Abs(ItemLedgerEntry.Quantity);
            if ItemLedgerEntry.Quantity <> 0 then begin
                // Sale → Sales Amount; Consumption/Assembly Consumption → Cost Amount
                if ItemLedgerEntry."Entry Type" = ItemLedgerEntry."Entry Type"::Sale then
                    UnitAmount := Abs(ItemLedgerEntry."Sales Amount (Actual)" / ItemLedgerEntry.Quantity)
                else
                    UnitAmount := Abs(ItemLedgerEntry."Cost Amount (Actual)" / ItemLedgerEntry.Quantity);
                PeriodAmount += UnitAmount;
                PeriodCount += 1;
            end;
        until ItemLedgerEntry.Next() = 0;

        // Flush last period
        if PeriodCount > 0 then begin
            PeriodPrice := PeriodAmount / PeriodCount;
            DemandN += 1;
            DemandSumX += PeriodPrice;
            DemandSumY += Abs(PeriodQty);
            DemandSumXX += PeriodPrice * PeriodPrice;
            DemandSumXY += PeriodPrice * Abs(PeriodQty);
        end;

        // ── Calculate Supply parameters (Purchase, Output, Assembly Output) ──────
        SupplyN := 0;
        ItemLedgerEntry.SetFilter("Entry Type", '%1|%2|%3',
            ItemLedgerEntry."Entry Type"::Purchase,
            ItemLedgerEntry."Entry Type"::Output,
            ItemLedgerEntry."Entry Type"::"Assembly Output");

        if not ItemLedgerEntry.FindSet() then
            Error(NoSupplyDataErr, ItemNo);

        PeriodStart := CalcDate('<-CM>', ItemLedgerEntry."Posting Date");
        PeriodQty := 0;
        PeriodAmount := 0;
        PeriodCount := 0;

        repeat
            if CalcDate('<-CM>', ItemLedgerEntry."Posting Date") <> PeriodStart then begin
                if PeriodCount > 0 then begin
                    PeriodPrice := PeriodAmount / PeriodCount;
                    SupplyN += 1;
                    SupplySumX += PeriodPrice;
                    SupplySumY += PeriodQty;
                    SupplySumXX += PeriodPrice * PeriodPrice;
                    SupplySumXY += PeriodPrice * PeriodQty;
                end;
                PeriodStart := CalcDate('<-CM>', ItemLedgerEntry."Posting Date");
                PeriodQty := 0;
                PeriodAmount := 0;
                PeriodCount := 0;
            end;
            PeriodQty += ItemLedgerEntry.Quantity;
            if ItemLedgerEntry.Quantity <> 0 then begin
                PeriodAmount += Abs(ItemLedgerEntry."Cost Amount (Actual)" / ItemLedgerEntry.Quantity);
                PeriodCount += 1;
            end;
        until ItemLedgerEntry.Next() = 0;

        // Flush last period
        if PeriodCount > 0 then begin
            PeriodPrice := PeriodAmount / PeriodCount;
            SupplyN += 1;
            SupplySumX += PeriodPrice;
            SupplySumY += PeriodQty;
            SupplySumXX += PeriodPrice * PeriodPrice;
            SupplySumXY += PeriodPrice * PeriodQty;
        end;

        // ── Validate minimum data ───────────────────────────────────────────────
        if (DemandN < 3) or (SupplyN < 3) then
            Error(InsufficientDataErr, DemandN, SupplyN);

        // ── Demand regression: Qty = A - B·Price ────────────────────────────────
        // Standard least squares: slope = (N·ΣXY - ΣX·ΣY) / (N·ΣXX - (ΣX)²)
        Denominator := DemandN * DemandSumXX - DemandSumX * DemandSumX;
        if Denominator <> 0 then begin
            CalcB := -(DemandN * DemandSumXY - DemandSumX * DemandSumY) / Denominator;
            CalcA := (DemandSumY + CalcB * DemandSumX) / DemandN;
        end else begin
            CalcA := DemandSumY / DemandN;
            CalcB := 1;
        end;

        // ── Supply regression: Qty = C + D·Price ────────────────────────────────
        Denominator := SupplyN * SupplySumXX - SupplySumX * SupplySumX;
        if Denominator <> 0 then begin
            CalcD := (SupplyN * SupplySumXY - SupplySumX * SupplySumY) / Denominator;
            CalcC := (SupplySumY - CalcD * SupplySumX) / SupplyN;
        end else begin
            CalcC := SupplySumY / SupplyN;
            CalcD := 1;
        end;

        // ── Ensure parameters stay in valid range ───────────────────────────────
        if CalcA <= 0 then
            CalcA := 1;
        if CalcB <= 0 then
            CalcB := 0.1;
        if CalcD <= 0 then
            CalcD := 0.1;

        // ── Write back to setup ─────────────────────────────────────────────────
        Setup."Item No." := ItemNo;
        Setup."Parameter A" := Round(CalcA, 0.00001);
        Setup."Parameter B" := Round(CalcB, 0.00001);
        Setup."Parameter C" := Round(CalcC, 0.00001);
        Setup."Parameter D" := Round(CalcD, 0.00001);
        Setup."Adjustment Factor K" := 0.5; // sensible default; hard to estimate precisely
        Setup."Initial Price" := Item."Unit Price";
        if Setup."Initial Price" = 0 then
            Setup."Initial Price" := Item."Last Direct Cost";
        Setup."Number of Periods" := 12;
        Setup.Modify(true);

        Message(
            ParametersCalculatedMsg,
            ItemNo,
            Format(Setup."Parameter A"),
            Format(Setup."Parameter B"),
            Format(Setup."Parameter C"),
            Format(Setup."Parameter D"),
            Format(Setup."Adjustment Factor K"),
            Format(Setup."Initial Price")
        );
    end;
}
