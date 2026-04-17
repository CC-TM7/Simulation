# Cobweb Model Simulation (Schweinezyklus) — Business Central AL

A Business Central extension implementing the discrete-time **Cobweb Model** to simulate cyclical supply-and-demand behaviour driven by a one-period production lag.

---

## 1. Mathematical Model

| Variable | Formula | Description |
|---|---|---|
| **D(t)** | `a − b·P(t)` | Demand at time t (downward-sloping) |
| **S(t)** | `c + d·P(t−1)` | Supply at time t (reacts to *previous* price) |
| **P(t+1)** | `P(t) + k·(D(t) − S(t))` | New price driven by excess demand/supply |

**Equilibrium price:**

```
P* = (a − c) / (b + d)
```

At equilibrium `D = S`, so `ΔP = 0` and the system is at rest.

**Stability (Cobweb theorem) — ratio `d/b`:**

| Condition | Behaviour |
|---|---|
| `d/b < 1` | Supply reacts *less* than demand → oscillations **dampen** → **Stable** |
| `d/b ≈ 1` | Equal reactions → oscillations persist with constant amplitude → **Oscillating** |
| `d/b > 1` | Supply *over-reacts* → oscillations **amplify** → **Exploding** |

---

## 2. Architecture

```
src/
├── Tables/
│   ├── CycleBehaviorType.Enum.al       # Enum: Stable / Oscillating / Exploding
│   ├── CycleSimulationSetup.Table.al   # Setup table (singleton, Code = 'DEFAULT')
│   └── CycleSimulationEntry.Table.al   # Results: one record per time step
├── Codeunits/
│   └── CycleSimulationEngine.Codeunit.al  # Core simulation loop + Excel export
└── Pages/
    ├── CycleSimulationSetup.Page.al    # Card: parameter editing + actions
    └── CycleSimulationEntries.Page.al  # List: simulation results
```

### Object IDs

| Object | Type | ID |
|---|---|---|
| Cycle Behavior Type | Enum | 50100 |
| Cycle Simulation Setup | Table | 50100 |
| Cycle Simulation Entry | Table | 50101 |
| Cycle Simulation Engine | Codeunit | 50100 |
| Cycle Simulation Setup | Page | 50100 |
| Cycle Simulation Entries | Page | 50101 |

---

## 3. Setup Parameters

| Field | Default | Meaning |
|---|---|---|
| Parameter A | 100 | Demand intercept — maximum demand at price 0 |
| Parameter B | 2 | Demand slope — demand falls by B per unit price increase |
| Parameter C | 10 | Supply intercept — base supply independent of price |
| Parameter D | 3 | Supply slope — supply rises by D per unit of *last period* price |
| Adjustment Factor K | 0.5 | Price correction speed — larger = faster but less stable |
| Initial Price | 20 | P(0) — starting point; distance from P* drives initial oscillation |
| Number of Periods | 30 | Time steps to simulate (2–1000) |

---

## 4. Example Parameter Sets

### 4.1 Stable Convergence (`d/b < 1`)

```
A = 100, B = 4, C = 10, D = 2, K = 0.5
Initial Price = 5, Periods = 40
```

`d/b = 2/4 = 0.5` — oscillations dampen; price converges to `P* = (100−10)/(4+2) = 15`.

### 4.2 Classic Oscillation (`d/b ≈ 1`)

```
A = 100, B = 3, C = 10, D = 3, K = 0.5
Initial Price = 5, Periods = 40
```

`d/b = 3/3 = 1.0` — price oscillates between two fixed values indefinitely.

### 4.3 Divergence / Exploding (`d/b > 1`)

```
A = 100, B = 2, C = 10, D = 3, K = 0.5
Initial Price = 20, Periods = 30
```

`d/b = 3/2 = 1.5` — each swing is larger than the last; the system diverges.
The simulation engine will emit a warning message if the price exceeds the safety threshold (1 × 10⁹).

---

## 5. How to Use

1. Open **Cycle Simulation Setup** (search in Business Central).
2. Adjust parameters as needed.
3. Choose **Run Simulation** — results appear in the **Cycle Simulation Entries** list.
4. The last entry shows the **Behavior Type** (Stable / Oscillating / Exploding).
5. Use **Export to Excel** to download the time series for further analysis.
6. Use **Reset Simulation** to clear all entries before a fresh run.

---

## 6. Code Design Principles

- **Separation of concerns** — calculation logic lives entirely in `CycleSimulationEngine`; pages hold no business logic.
- **Reproducibility** — no randomisation; identical parameters always yield identical results.
- **Numerical safety** — an early-exit guard aborts the loop if price exceeds 1 × 10⁹.
- **Commented mathematics** — every formula has an inline comment linking code to the mathematical model.
- **Extensibility** — the enum is extensible, the setup table uses a singleton pattern, and the engine exposes separate `RunSimulation`, `ResetSimulation`, and `ExportToExcelBuffer` procedures.
