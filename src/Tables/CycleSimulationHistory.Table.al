/// <summary>
/// Table "Cycle Simulation History" stores one header record per simulation run.
///
/// Each time the engine executes, a new history record is created with a snapshot
/// of all input parameters and the resulting behavior classification.
/// Related detail records live in "Cycle Simulation Entry" linked by "Simulation No.".
/// </summary>
table 50302 "Cycle Simulation History"
{
    Caption = 'Cycle Simulation History';
    DataClassification = CustomerContent;
    LookupPageId = "Cycle Simulation History";
    DrillDownPageId = "Cycle Simulation History";

    fields
    {
        /// <summary>Auto-incrementing surrogate key identifying each simulation run.</summary>
        field(1; "Simulation No."; Integer)
        {
            Caption = 'Simulation No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }

        /// <summary>Description or label for this simulation run (optional).</summary>
        field(2; "Description"; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }

        // ── Parameter snapshot ───────────────────────────────────────────────────

        /// <summary>Snapshot of Parameter A at time of run.</summary>
        field(10; "Parameter A"; Decimal)
        {
            Caption = 'Parameter A';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        /// <summary>Snapshot of Parameter B at time of run.</summary>
        field(11; "Parameter B"; Decimal)
        {
            Caption = 'Parameter B';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        /// <summary>Snapshot of Parameter C at time of run.</summary>
        field(12; "Parameter C"; Decimal)
        {
            Caption = 'Parameter C';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        /// <summary>Snapshot of Parameter D at time of run.</summary>
        field(13; "Parameter D"; Decimal)
        {
            Caption = 'Parameter D';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        /// <summary>Snapshot of Adjustment Factor K at time of run.</summary>
        field(14; "Adjustment Factor K"; Decimal)
        {
            Caption = 'Adjustment Factor K';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        /// <summary>Snapshot of Initial Price at time of run.</summary>
        field(15; "Initial Price"; Decimal)
        {
            Caption = 'Initial Price';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        /// <summary>Snapshot of Number of Periods requested.</summary>
        field(16; "Number of Periods"; Integer)
        {
            Caption = 'Number of Periods';
            DataClassification = CustomerContent;
            Editable = false;
        }

        // ── Results ──────────────────────────────────────────────────────────────

        /// <summary>Actual number of time steps simulated (may be less if converged or exploded early).</summary>
        field(20; "Actual Periods"; Integer)
        {
            Caption = 'Actual Periods';
            DataClassification = CustomerContent;
            Editable = false;
        }

        /// <summary>Overall behavior classification of this run.</summary>
        field(21; "Behavior Type"; Enum "Cycle Behavior Type")
        {
            Caption = 'Behavior Type';
            DataClassification = CustomerContent;
            Editable = false;
        }

        /// <summary>Equilibrium price P* = (A − C) / (B + D).</summary>
        field(22; "Equilibrium Price"; Decimal)
        {
            Caption = 'Equilibrium Price P*';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 5;
            Editable = false;
        }

        // ── Audit ────────────────────────────────────────────────────────────────

        /// <summary>Timestamp when the simulation was executed.</summary>
        field(30; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }

        /// <summary>User who executed the simulation.</summary>
        field(31; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }

        /// <summary>Item used as data source (blank if manual parameters).</summary>
        field(40; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
            TableRelation = Item."No.";
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Simulation No.")
        {
            Clustered = true;
        }
    }
}
