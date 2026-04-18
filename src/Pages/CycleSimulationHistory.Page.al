/// <summary>
/// Page "Cycle Simulation History" displays all past simulation runs.
///
/// Each row shows the parameters used, behavior classification, and audit info.
/// Users can drill down into the detail entries for any run or delete old runs.
/// </summary>
page 50302 "Cycle Simulation History"
{
    Caption = 'Cycle Simulation History';
    PageType = List;
    SourceTable = "Cycle Simulation History";
    SourceTableView = sorting("Simulation No.") order(descending);
    UsageCategory = Lists;
    ApplicationArea = All;
    InsertAllowed = false;
    ModifyAllowed = true;
    DeleteAllowed = true;
    Editable = true;
    CardPageId = "Cycle Simulation History";

    layout
    {
        area(Content)
        {
            repeater(HistoryList)
            {
                field("Simulation No."; Rec."Simulation No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Unique identifier of the simulation run.';
                    Editable = false;
                }
                field("Description"; Rec."Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Optional description or label for this run.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Item whose ledger data was used to calculate the parameters. Blank if manual.';
                }
                field("Behavior Type"; Rec."Behavior Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Overall classification: Stable / Oscillating / Exploding.';
                    StyleExpr = BehaviorStyle;
                }
                field("Equilibrium Price"; Rec."Equilibrium Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'Theoretical equilibrium price P* = (A − C) / (B + D).';
                }
                field("Parameter A"; Rec."Parameter A")
                {
                    ApplicationArea = All;
                    ToolTip = 'Demand intercept (a) used for this run.';
                }
                field("Parameter B"; Rec."Parameter B")
                {
                    ApplicationArea = All;
                    ToolTip = 'Demand slope (b) used for this run.';
                }
                field("Parameter C"; Rec."Parameter C")
                {
                    ApplicationArea = All;
                    ToolTip = 'Supply intercept (c) used for this run.';
                }
                field("Parameter D"; Rec."Parameter D")
                {
                    ApplicationArea = All;
                    ToolTip = 'Supply slope (d) used for this run.';
                }
                field("Adjustment Factor K"; Rec."Adjustment Factor K")
                {
                    ApplicationArea = All;
                    ToolTip = 'Price adjustment speed (k) used for this run.';
                }
                field("Initial Price"; Rec."Initial Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'Starting price P(0) used for this run.';
                }
                field("Number of Periods"; Rec."Number of Periods")
                {
                    ApplicationArea = All;
                    ToolTip = 'Number of periods requested.';
                }
                field("Actual Periods"; Rec."Actual Periods")
                {
                    ApplicationArea = All;
                    ToolTip = 'Actual number of time steps simulated (may differ if converged or exploded early).';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Timestamp when the simulation was executed.';
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                    ToolTip = 'User who executed the simulation.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowEntries)
            {
                Caption = 'Show Entries';
                Image = LedgerEntries;
                ApplicationArea = All;
                ToolTip = 'Opens the simulation entries for the selected run.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    SimEntry: Record "Cycle Simulation Entry";
                begin
                    SimEntry.SetRange("Simulation No.", Rec."Simulation No.");
                    Page.Run(Page::"Cycle Simulation Entries", SimEntry);
                end;
            }

            action(OpenSetup)
            {
                Caption = 'Open Setup';
                Image = Setup;
                ApplicationArea = All;
                ToolTip = 'Opens the Cycle Simulation Setup card.';
                RunObject = page "Cycle Simulation Setup";
                Promoted = true;
                PromotedCategory = Process;
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    var
        SimEntry: Record "Cycle Simulation Entry";
    begin
        SimEntry.SetRange("Simulation No.", Rec."Simulation No.");
        SimEntry.DeleteAll();
    end;

    var
        BehaviorStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec."Behavior Type" of
            Enum::"Cycle Behavior Type"::Stable:
                BehaviorStyle := 'Favorable';
            Enum::"Cycle Behavior Type"::Exploding:
                BehaviorStyle := 'Unfavorable';
            Enum::"Cycle Behavior Type"::Oscillating:
                BehaviorStyle := 'Ambiguous';
            else
                BehaviorStyle := 'Standard';
        end;
    end;
}
