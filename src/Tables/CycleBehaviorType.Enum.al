/// <summary>
/// Enum "Cycle Behavior Type" classifies the dynamic behavior of a Cobweb simulation run.
///
/// The classification is based on how the absolute price deviation from equilibrium
/// evolves over the final periods of the simulation:
///
///   Stable      – |P(t) - P*| decreases   → convergent cobweb (d/b < 1)
///   Oscillating – |P(t) - P*| stays flat  → neutral cobweb    (d/b ≈ 1)
///   Exploding   – |P(t) - P*| increases   → divergent cobweb  (d/b > 1)
/// </summary>
enum 50300 "Cycle Behavior Type"
{
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; "Stable")
    {
        Caption = 'Stable';
    }
    value(2; "Oscillating")
    {
        Caption = 'Oscillating';
    }
    value(3; "Exploding")
    {
        Caption = 'Exploding';
    }
}
