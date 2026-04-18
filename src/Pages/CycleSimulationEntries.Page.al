/// <summary>
/// Page "Cycle Simulation Entries" is a read-only list page that displays all records
/// produced by the "Cycle Simulation Engine" codeunit.
///
/// Each row corresponds to one discrete time step t and shows:
///   Time Step | Price P(t) | Demand D(t) | Supply S(t) | Delta D-S | Behavior Type
///
/// The "Behavior Type" column is populated only on the last entry of each run and
/// reflects the overall system classification (Stable / Oscillating / Exploding).
///
/// Actions mirror those on the setup card for convenience.
/// </summary>
page 50301 "Cycle Simulation Entries"
{
    Caption = 'Cycle Simulation Entries';
    PageType = List;
    SourceTable = "Cycle Simulation Entry";
    SourceTableView = sorting("Time Step") order(ascending);
    UsageCategory = Lists;
    ApplicationArea = All;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(SimulationResults)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Unique record identifier (auto-incremented).';
                }
                field("Simulation No."; Rec."Simulation No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Identifies which simulation run produced this entry.';
                }
                field("Time Step"; Rec."Time Step")
                {
                    ApplicationArea = All;
                    ToolTip = 'Discrete time index t (0-based). Each step represents one production period.';
                }
                field(Price; Rec.Price)
                {
                    ApplicationArea = All;
                    Caption = 'Price P(t)';
                    ToolTip = 'Market price at time step t. Evolves according to P(t+1) = P(t) + K·(D(t)−S(t)).';
                }
                field(Demand; Rec.Demand)
                {
                    ApplicationArea = All;
                    Caption = 'Demand D(t)';
                    ToolTip = 'Demand at time step t computed as D(t) = A − B·P(t).';
                }
                field(Supply; Rec.Supply)
                {
                    ApplicationArea = All;
                    Caption = 'Supply S(t)';
                    ToolTip = 'Supply at time step t computed as S(t) = C + D·P(t−1). Supply lags behind price by one period.';
                }
                field(Delta; Rec.Delta)
                {
                    ApplicationArea = All;
                    Caption = 'Delta D(t)−S(t)';
                    ToolTip = 'Excess demand (positive) or excess supply (negative). Drives the price in the next period.';

                    StyleExpr = DeltaStyle;
                }
                field("Behavior Type"; Rec."Behavior Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Overall system classification stamped on the last entry. Stable / Oscillating / Exploding.';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Timestamp when this entry was written during the simulation run.';
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
                ToolTip = 'Executes the Cobweb Model simulation and refreshes this list.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    SimEngine: Codeunit "Cycle Simulation Engine";
                begin
                    SimEngine.RunSimulation();
                    CurrPage.Update(false);
                end;
            }

            action(ResetSimulation)
            {
                Caption = 'Reset Simulation';
                Image = Delete;
                ApplicationArea = All;
                ToolTip = 'Deletes all simulation entries.';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    SimEngine: Codeunit "Cycle Simulation Engine";
                    ConfirmDeleteQst: Label 'Delete all simulation entries?';
                begin
                    if Confirm(ConfirmDeleteQst, false) then begin
                        SimEngine.ResetSimulation();
                        CurrPage.Update(false);
                    end;
                end;
            }

            action(OpenSetup)
            {
                Caption = 'Open Setup';
                Image = Setup;
                ApplicationArea = All;
                ToolTip = 'Opens the Cycle Simulation Setup card to adjust parameters.';
                RunObject = page "Cycle Simulation Setup";
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
        }
    }

    // ════════════════════════════════════════════════════════════════════════════
    //  Style expression variables
    // ════════════════════════════════════════════════════════════════════════════

    var
        /// <summary>
        /// Drives the colour style of the Delta column:
        ///   Favorable  (green) = excess demand  (Delta > 0) → price rises
        ///   Unfavorable (red)  = excess supply   (Delta < 0) → price falls
        ///   Standard           = balanced market (Delta = 0)
        /// </summary>
        DeltaStyle: Text;

    trigger OnAfterGetRecord()
    begin
        if Rec.Delta > 0 then
            DeltaStyle := 'Favorable'
        else
            if Rec.Delta < 0 then
                DeltaStyle := 'Unfavorable'
            else
                DeltaStyle := 'Standard';
    end;
}
