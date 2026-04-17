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
/// Stability condition (|d/b| < 1):
///   Stable      if d/b < 1  (oscillations dampen)
///   Oscillating if d/b = 1  (constant-amplitude oscillations)
///   Exploding   if d/b > 1  (oscillations amplify)
///
/// Usage
/// ─────
///   1. Call RunSimulation() to execute a full simulation using the current setup.
///   2. Call ResetSimulation() to delete all previous entries.
///   3. Export via ExportToExcelBuffer() if further analysis is needed.
/// </summary>
codeunit 50100 "Cycle Simulation Engine"
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
        // ── stability guard ───────────────────────────────────────────────────────
        MaxAbsPrice: Decimal;
        ExplodingThreshold: Decimal;
    begin
        // ── 1. Load validated setup ───────────────────────────────────────────────
        Setup := Setup.GetSetup();
        ValidateSetup(Setup);

        ParamA := Setup."Parameter A";
        ParamB := Setup."Parameter B";
        ParamC := Setup."Parameter C";
        ParamD := Setup."Parameter D";
        ParamK := Setup."Adjustment Factor K";
        CurrentPrice := Setup."Initial Price";
        NumPeriods := Setup."Number of Periods";

        // ── 2. Clear previous results ────────────────────────────────────────────
        SimEntry.DeleteAll();

        // ── 3. Initialise loop state ─────────────────────────────────────────────
        // At t = 0 there is no prior period, so S(0) uses P(-1) ≡ P(0).
        PreviousPrice := CurrentPrice;
        ExplodingThreshold := 1E9; // guard against IEEE overflow
        MaxAbsPrice := 0;

        // ── 4. Main simulation loop ──────────────────────────────────────────────
        for TimeStep := 0 to NumPeriods - 1 do begin
            // D(t) = a - b·P(t)
            CurrentDemand := ParamA - ParamB * CurrentPrice;

            // S(t) = c + d·P(t-1)
            CurrentSupply := ParamC + ParamD * PreviousPrice;

            // Δ(t) = D(t) - S(t)
            ExcessDemand := CurrentDemand - CurrentSupply;

            // Persist time-step record
            SimEntry.Init();
            SimEntry."Time Step" := TimeStep;
            SimEntry."Price" := CurrentPrice;
            SimEntry."Demand" := CurrentDemand;
            SimEntry."Supply" := CurrentSupply;
            SimEntry."Delta" := ExcessDemand;
            SimEntry."Created At" := CurrentDateTime();
            SimEntry.Insert();

            // Track maximum absolute price to help detect divergence
            if Abs(CurrentPrice) > MaxAbsPrice then
                MaxAbsPrice := Abs(CurrentPrice);

            // Abort early if price is exploding beyond the safety threshold
            if Abs(CurrentPrice) > ExplodingThreshold then begin
                Message('Simulation stopped early at time step %1: price exceeded stability threshold (%2).', TimeStep, ExplodingThreshold);
                break;
            end;

            // P(t+1) = P(t) + k·(D(t) − S(t))
            NextPrice := CurrentPrice + ParamK * ExcessDemand;

            // Advance state
            PreviousPrice := CurrentPrice;
            CurrentPrice := NextPrice;
        end;

        // ── 5. Classify behavior and stamp last entry ─────────────────────────────
        BehaviorType := ClassifyBehavior(Setup);
        StampBehaviorType(BehaviorType);
    end;

    /// <summary>
    /// Deletes all records in the "Cycle Simulation Entry" table.
    /// Call before re-running to start fresh.
    /// </summary>
    procedure ResetSimulation()
    var
        SimEntry: Record "Cycle Simulation Entry";
    begin
        SimEntry.DeleteAll();
        Message('Simulation data has been reset.');
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
    begin
        ExcelBuffer.DeleteAll();
        RowNo := 1;

        // Header row
        AddExcelCell(ExcelBuffer, RowNo, 1, 'Time Step', true);
        AddExcelCell(ExcelBuffer, RowNo, 2, 'Price P(t)', true);
        AddExcelCell(ExcelBuffer, RowNo, 3, 'Demand D(t)', true);
        AddExcelCell(ExcelBuffer, RowNo, 4, 'Supply S(t)', true);
        AddExcelCell(ExcelBuffer, RowNo, 5, 'Delta D-S', true);
        AddExcelCell(ExcelBuffer, RowNo, 6, 'Behavior Type', true);

        // Data rows
        SimEntry.SetCurrentKey("Time Step");
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
    begin
        if Setup."Parameter A" <= 0 then
            Error('Parameter A (demand intercept) must be greater than zero.');
        if Setup."Parameter B" <= 0 then
            Error('Parameter B (demand slope) must be greater than zero.');
        if Setup."Parameter D" <= 0 then
            Error('Parameter D (supply slope) must be greater than zero.');
        if Setup."Adjustment Factor K" <= 0 then
            Error('Adjustment Factor K must be greater than zero.');
        if Setup."Initial Price" < 0 then
            Error('Initial Price must be zero or positive.');
        if Setup."Number of Periods" < 2 then
            Error('Number of Periods must be at least 2.');
    end;

    /// <summary>
    /// Classifies overall system behavior based on the ratio d/b.
    ///
    /// Theoretical result (Cobweb theorem):
    ///   d/b < 1  → supply reacts less than demand → price deviations shrink → Stable
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
    local procedure StampBehaviorType(BehaviorType: Enum "Cycle Behavior Type")
    var
        SimEntry: Record "Cycle Simulation Entry";
    begin
        SimEntry.SetCurrentKey("Time Step");
        if SimEntry.FindLast() then begin
            SimEntry."Behavior Type" := BehaviorType;
            SimEntry.Modify();
        end;
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
}
