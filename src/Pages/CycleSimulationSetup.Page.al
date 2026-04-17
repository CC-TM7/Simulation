/// <summary>
/// Page "Cycle Simulation Setup" is a card page for configuring the Cobweb Model
/// simulation parameters.
///
/// From this page the user can:
///   • Edit all mathematical parameters (A, B, C, D, K, Initial Price, Periods)
///   • Launch a fresh simulation run ("Run Simulation" action)
///   • Reset all simulation data ("Reset Simulation" action)
///   • Navigate to the results list
///   • Export results to Excel
/// </summary>
page 50100 "Cycle Simulation Setup"
{
    Caption = 'Cycle Simulation Setup';
    PageType = Card;
    SourceTable = "Cycle Simulation Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Identifies the setup record. Always DEFAULT.';
                }
            }

            group(DemandParameters)
            {
                Caption = 'Demand Function  D(t) = A − B·P(t)';

                field("Parameter A"; Rec."Parameter A")
                {
                    ApplicationArea = All;
                    ToolTip = 'Demand intercept (a). Maximum demand when price is zero. Must be > 0.';
                }
                field("Parameter B"; Rec."Parameter B")
                {
                    ApplicationArea = All;
                    ToolTip = 'Demand slope (b). Rate at which demand falls as price increases. Must be > 0.';
                }
            }

            group(SupplyParameters)
            {
                Caption = 'Supply Function  S(t) = C + D·P(t−1)';

                field("Parameter C"; Rec."Parameter C")
                {
                    ApplicationArea = All;
                    ToolTip = 'Supply intercept (c). Base supply independent of price. Can be zero.';
                }
                field("Parameter D"; Rec."Parameter D")
                {
                    ApplicationArea = All;
                    ToolTip = 'Supply slope (d). Rate at which supply rises in response to the PREVIOUS period''s price. Must be > 0.';
                }
            }

            group(PriceAdjustment)
            {
                Caption = 'Price Adjustment  P(t+1) = P(t) + K·(D(t)−S(t))';

                field("Adjustment Factor K"; Rec."Adjustment Factor K")
                {
                    ApplicationArea = All;
                    ToolTip = 'Speed at which prices correct excess demand/supply. Large K values accelerate adjustment but may cause instability. Must be > 0.';
                }
            }

            group(SimulationControl)
            {
                Caption = 'Simulation Control';

                field("Initial Price"; Rec."Initial Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'Starting price P(0). Deviations from the equilibrium price P* = (A−C)/(B+D) drive cyclical behavior.';
                }
                field("Number of Periods"; Rec."Number of Periods")
                {
                    ApplicationArea = All;
                    ToolTip = 'Total number of time steps to simulate (2–1000). More periods reveal long-run dynamics.';
                }
            }

            group(StabilityInfo)
            {
                Caption = 'Stability Indicator  (d / b)';
                Editable = false;

                field(StabilityRatioDisplay; GetStabilityRatioText())
                {
                    ApplicationArea = All;
                    Caption = 'Supply/Demand Slope Ratio (d/b)';
                    ToolTip = 'Stability indicator. Ratio < 1 → convergent (Stable). Ratio ≈ 1 → persistent oscillations. Ratio > 1 → divergent (Exploding).';
                    Editable = false;
                }
                field(EquilibriumPriceDisplay; GetEquilibriumPriceText())
                {
                    ApplicationArea = All;
                    Caption = 'Equilibrium Price P*';
                    ToolTip = 'Theoretical equilibrium price P* = (A − C) / (B + D). The simulation converges to this value when d/b < 1.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunSimulation)
            {
                Caption = 'Run Simulation';
                Image = Start;
                ApplicationArea = All;
                ToolTip = 'Executes the Cobweb Model simulation with the current parameters and stores the results.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    SimEngine: Codeunit "Cycle Simulation Engine";
                begin
                    CurrPage.SaveRecord();
                    SimEngine.RunSimulation();
                    Message('Simulation completed. Open the Simulation Entries page to review results.');
                end;
            }

            action(ResetSimulation)
            {
                Caption = 'Reset Simulation';
                Image = Delete;
                ApplicationArea = All;
                ToolTip = 'Deletes all previously stored simulation entries.';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    SimEngine: Codeunit "Cycle Simulation Engine";
                begin
                    if Confirm('Delete all simulation entries?', false) then
                        SimEngine.ResetSimulation();
                end;
            }

            action(ShowEntries)
            {
                Caption = 'Show Entries';
                Image = List;
                ApplicationArea = All;
                ToolTip = 'Opens the list of simulation entries.';
                RunObject = page "Cycle Simulation Entries";
                Promoted = true;
                PromotedCategory = Process;
            }

            action(ExportToExcel)
            {
                Caption = 'Export to Excel';
                Image = Export;
                ApplicationArea = All;
                ToolTip = 'Exports all simulation entries to an Excel workbook.';
                Promoted = true;
                PromotedCategory = Report;

                trigger OnAction()
                var
                    SimEngine: Codeunit "Cycle Simulation Engine";
                begin
                    SimEngine.ExportToExcelBuffer();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Setup: Record "Cycle Simulation Setup";
    begin
        // Ensure the singleton setup record exists before the page opens.
        Setup := Setup.GetSetup();
        if not Rec.Get(Setup.Code) then begin
            Rec := Setup;
            Rec.Insert();
        end;
    end;

    // ════════════════════════════════════════════════════════════════════════════
    //  Display helpers
    // ════════════════════════════════════════════════════════════════════════════

    /// <summary>
    /// Returns a formatted string showing the d/b ratio and its behavioral implication.
    /// Displayed in the Stability Indicator group for immediate user feedback.
    /// </summary>
    local procedure GetStabilityRatioText(): Text
    var
        Ratio: Decimal;
    begin
        if Rec."Parameter B" = 0 then
            exit('N/A (B = 0)');

        Ratio := Rec."Parameter D" / Rec."Parameter B";

        if Ratio < 0.95 then
            exit(StrSubstNo('%1 → Stable (convergent)', Format(Ratio, 0, '<Precision,4><Standard Format,2>')))
        else
            if Ratio > 1.05 then
                exit(StrSubstNo('%1 → Exploding (divergent)', Format(Ratio, 0, '<Precision,4><Standard Format,2>')))
            else
                exit(StrSubstNo('%1 → Oscillating (neutral)', Format(Ratio, 0, '<Precision,4><Standard Format,2>')));
    end;

    /// <summary>
    /// Returns the theoretical equilibrium price P* = (A − C) / (B + D).
    /// At equilibrium D(t) = S(t), so excess demand is zero and price stabilises.
    /// </summary>
    local procedure GetEquilibriumPriceText(): Text
    var
        Denominator: Decimal;
        EquilPrice: Decimal;
    begin
        Denominator := Rec."Parameter B" + Rec."Parameter D";
        if Denominator = 0 then
            exit('N/A');

        EquilPrice := (Rec."Parameter A" - Rec."Parameter C") / Denominator;
        exit(Format(EquilPrice, 0, '<Precision,4><Standard Format,2>'));
    end;
}
