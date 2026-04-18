/// <summary>
/// Table "Cycle Simulation Setup" stores the configurable parameters that govern the
/// Cobweb Model (Schweinezyklus) simulation.
///
/// Mathematical roles:
///   Parameter A  – demand intercept (a):  D(t) = a - b*P(t)
///   Parameter B  – demand slope    (b):  D(t) = a - b*P(t)
///   Parameter C  – supply intercept (c): S(t) = c + d*P(t-1)
///   Parameter D  – supply slope    (d):  S(t) = c + d*P(t-1)
///   Adjustment K – price feedback  (k):  P(t+1) = P(t) + k*(D(t)-S(t))
///   InitialPrice – starting price  P(0)
///   NumPeriods   – how many time steps to simulate
/// </summary>
table 50300 "Cycle Simulation Setup"
{
    Caption = 'Cycle Simulation Setup';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>Primary key – singleton record; always use Code = 'DEFAULT'.</summary>
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
        }

        /// <summary>
        /// Parameter A: demand intercept.
        /// Represents maximum demand when price is zero (D = a when P = 0).
        /// Must be greater than zero.
        /// </summary>
        field(10; "Parameter A"; Decimal)
        {
            Caption = 'Parameter A (Demand Intercept)';
            DataClassification = CustomerContent;
            MinValue = 0.00001;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                ValidatePositive(Rec."Parameter A", FieldCaption("Parameter A"));
            end;
        }

        /// <summary>
        /// Parameter B: demand slope (price sensitivity of demand).
        /// Higher B means demand falls more steeply as price rises.
        /// Must be greater than zero to keep the demand curve downward-sloping.
        /// </summary>
        field(11; "Parameter B"; Decimal)
        {
            Caption = 'Parameter B (Demand Slope)';
            DataClassification = CustomerContent;
            MinValue = 0.00001;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                ValidatePositive(Rec."Parameter B", FieldCaption("Parameter B"));
            end;
        }

        /// <summary>
        /// Parameter C: supply intercept.
        /// Represents base supply independent of price (can be zero or positive).
        /// </summary>
        field(12; "Parameter C"; Decimal)
        {
            Caption = 'Parameter C (Supply Intercept)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }

        /// <summary>
        /// Parameter D: supply slope (price sensitivity of supply, lagged by one period).
        /// Higher D means producers react more strongly to the previous period price.
        /// Must be greater than zero to keep the supply curve upward-sloping.
        /// </summary>
        field(13; "Parameter D"; Decimal)
        {
            Caption = 'Parameter D (Supply Slope)';
            DataClassification = CustomerContent;
            MinValue = 0.00001;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                ValidatePositive(Rec."Parameter D", FieldCaption("Parameter D"));
            end;
        }

        /// <summary>
        /// Adjustment Factor K: speed at which price corrects excess demand/supply.
        /// P(t+1) = P(t) + k*(D(t) - S(t))
        /// Must be positive; large K values cause faster but potentially unstable adjustment.
        /// </summary>
        field(14; "Adjustment Factor K"; Decimal)
        {
            Caption = 'Adjustment Factor K';
            DataClassification = CustomerContent;
            MinValue = 0.00001;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                ValidatePositive(Rec."Adjustment Factor K", FieldCaption("Adjustment Factor K"));
            end;
        }

        /// <summary>
        /// Initial Price P(0): the starting price for the simulation.
        /// The equilibrium price (P*) is (a-c)/(b+d); deviations from P* drive cycles.
        /// </summary>
        field(20; "Initial Price"; Decimal)
        {
            Caption = 'Initial Price P(0)';
            DataClassification = CustomerContent;
            MinValue = 0;
            DecimalPlaces = 0 : 5;
        }

        /// <summary>
        /// Number of Periods: total time steps T to simulate (t = 0 … T-1).
        /// Must be at least 2 to observe any dynamics.
        /// </summary>
        field(21; "Number of Periods"; Integer)
        {
            Caption = 'Number of Periods';
            DataClassification = CustomerContent;
            MinValue = 2;
            MaxValue = 1000;
        }

        /// <summary>
        /// Item No.: optional reference to a BC item whose ledger entries
        /// were used to calculate the simulation parameters.
        /// </summary>
        field(30; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
            TableRelation = Item."No.";
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Populates the singleton setup record, inserting defaults when not yet present.
    /// Callers should always use this method rather than Get() directly.
    /// </summary>
    procedure GetSetup(var Setup: Record "Cycle Simulation Setup")
    var
        IsHandled: Boolean;
    begin
        OnBeforeGetSetup(Setup, IsHandled);
        if IsHandled then
            exit;

        if not Setup.Get('DEFAULT') then begin
            Setup.Init();
            Setup.Code := 'DEFAULT';
            Setup."Parameter A" := 100;
            Setup."Parameter B" := 2;
            Setup."Parameter C" := 10;
            Setup."Parameter D" := 3;
            Setup."Adjustment Factor K" := 0.5;
            Setup."Initial Price" := 20;
            Setup."Number of Periods" := 30;
            Setup.Insert();
        end;

        OnAfterGetSetup(Setup);
    end;

    /// <summary>
    /// Raises an error when Value is less than or equal to zero.
    /// Used to enforce that slope and adjustment parameters remain meaningful.
    /// </summary>
    local procedure ValidatePositive(Value: Decimal; FieldName: Text)
    var
        FieldMustBePositiveErr: Label 'Field %1 must be greater than zero.', Comment = '%1 = field caption';
    begin
        if Value <= 0 then
            Error(FieldMustBePositiveErr, FieldName);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSetup(var Setup: Record "Cycle Simulation Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSetup(var Setup: Record "Cycle Simulation Setup")
    begin
    end;
}
