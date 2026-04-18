/// <summary>
/// Table "Cycle Simulation Entry" stores one record per simulated time step.
///
/// For each period t the engine writes:
///   Price    = P(t)
///   Demand   = D(t) = a - b*P(t)
///   Supply   = S(t) = c + d*P(t-1)   [lagged price]
///   Delta    = D(t) - S(t)            [excess demand; negative = excess supply]
///   BehaviorType – overall system classification (filled only on the last entry)
/// </summary>
table 50301 "Cycle Simulation Entry"
{
    Caption = 'Cycle Simulation Entry';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>Auto-incrementing surrogate key.</summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }

        /// <summary>Discrete time index t (0-based).</summary>
        field(2; "Time Step"; Integer)
        {
            Caption = 'Time Step';
            DataClassification = CustomerContent;
        }

        /// <summary>Links this entry to the parent simulation run in "Cycle Simulation History".</summary>
        field(3; "Simulation No."; Integer)
        {
            Caption = 'Simulation No.';
            DataClassification = CustomerContent;
            TableRelation = "Cycle Simulation History"."Simulation No.";
        }

        /// <summary>
        /// Price P(t).
        /// Evolves according to P(t+1) = P(t) + k*(D(t) - S(t)).
        /// </summary>
        field(10; "Price"; Decimal)
        {
            Caption = 'Price P(t)';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 5;
        }

        /// <summary>
        /// Demand D(t) = a - b*P(t).
        /// Reflects current willingness-to-buy at the current price.
        /// </summary>
        field(11; "Demand"; Decimal)
        {
            Caption = 'Demand D(t)';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 5;
        }

        /// <summary>
        /// Supply S(t) = c + d*P(t-1).
        /// Producers base their output on last period's price (production lag).
        /// At t = 0, the initial price is used as the lagged price.
        /// </summary>
        field(12; "Supply"; Decimal)
        {
            Caption = 'Supply S(t)';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 5;
        }

        /// <summary>
        /// Delta = D(t) - S(t).
        /// Positive value: excess demand → price will rise.
        /// Negative value: excess supply → price will fall.
        /// </summary>
        field(13; "Delta"; Decimal)
        {
            Caption = 'Delta D(t)–S(t)';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 5;
        }

        /// <summary>
        /// Behavior Type: system-level classification computed after the full run.
        /// Options:
        ///   " "         – not yet classified
        ///   Stable      – oscillations dampen; price converges to equilibrium
        ///   Oscillating – oscillations persist with roughly constant amplitude
        ///   Exploding   – oscillations amplify; system diverges
        /// </summary>
        field(20; "Behavior Type"; Enum "Cycle Behavior Type")
        {
            Caption = 'Behavior Type';
            DataClassification = CustomerContent;
        }

        /// <summary>Timestamp when this entry was created.</summary>
        field(30; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(TimeStep; "Time Step")
        {
        }
        key(SimulationTimeStep; "Simulation No.", "Time Step")
        {
        }
    }
}
