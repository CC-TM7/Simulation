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
page 50300 "Cycle Simulation Setup"
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
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Item whose ledger entries were used to auto-calculate the parameters. Blank if parameters are set manually.';
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
                    SimCompletedQst: Label 'Simulation completed. Do you want to view the results?';
                begin
                    CurrPage.SaveRecord();
                    SimEngine.RunSimulation();
                    if Confirm(SimCompletedQst, true) then
                        Page.Run(Page::"Cycle Simulation Entries");
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
                    ConfirmDeleteQst: Label 'Delete all simulation entries?';
                begin
                    if Confirm(ConfirmDeleteQst, false) then
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

            action(ShowHistory)
            {
                Caption = 'Show History';
                Image = History;
                ApplicationArea = All;
                ToolTip = 'Opens the simulation history to view all past runs.';
                RunObject = page "Cycle Simulation History";
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

            action(CalculateFromItem)
            {
                Caption = 'Calculate from Item';
                Image = CalculateLines;
                ApplicationArea = All;
                ToolTip = 'Reads the selected item''s sales and purchase ledger entries (last 24 months) and calculates A, B, C, D, K, and Initial Price automatically.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    Item: Record Item;
                    SimEngine: Codeunit "Cycle Simulation Engine";
                begin
                    if Page.RunModal(Page::"Item Lookup", Item) = Action::LookupOK then begin
                        CurrPage.SaveRecord();
                        SimEngine.CalculateFromItemLedger(Rec, Item."No.");
                        CurrPage.Update(false);
                    end;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetSetup(Rec);
    end;

    // ════════════════════════════════════════════════════════════════════════════
    //  Display helpers
    // ════════════════════════════════════════════════════════════════════════════

    local procedure GetStabilityRatioText(): Text
    var
        SimEngine: Codeunit "Cycle Simulation Engine";
    begin
        exit(SimEngine.GetStabilityRatioText(Rec));
    end;

    local procedure GetEquilibriumPriceText(): Text
    var
        SimEngine: Codeunit "Cycle Simulation Engine";
    begin
        exit(SimEngine.GetEquilibriumPriceText(Rec));
    end;
}
