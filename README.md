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

## 5. Benutzer-Ablauf (User Workflow)

### Schritt 1 — Setup öffnen

In Business Central die Suchleiste (🔍) öffnen und nach **Cycle Simulation Setup** suchen.  
Es öffnet sich eine **Card-Page** mit folgendem Aufbau:

| Bereich | Was der User sieht | Was er tun kann |
|---|---|---|
| **General** | Feld `Code` = `DEFAULT` (nicht editierbar) | Nur lesen — identifiziert den einzigen Setup-Datensatz |
| **Demand Function D(t) = A − B·P(t)** | Felder `Parameter A` und `Parameter B` | Nachfrage-Parameter anpassen (A = Achsenabschnitt, B = Steigung) |
| **Supply Function S(t) = C + D·P(t−1)** | Felder `Parameter C` und `Parameter D` | Angebots-Parameter anpassen (C = Basis-Angebot, D = Preis-Reaktion) |
| **Price Adjustment P(t+1) = P(t) + K·(D−S)** | Feld `Adjustment Factor K` | Geschwindigkeit der Preisanpassung einstellen |
| **Simulation Control** | Felder `Initial Price` und `Number of Periods` | Startpreis P(0) und Anzahl Zeitschritte (2–1000) festlegen |
| **Stability Indicator (d/b)** | Berechnete Anzeige: *Supply/Demand Slope Ratio* und *Equilibrium Price P\** | Nur lesen — zeigt sofort, ob das System stabil, oszillierend oder explodierend ist |

> **Tipp:** Der Stabilitäts-Indikator aktualisiert sich live beim Ändern der Parameter, sodass man vor dem Start der Simulation das erwartete Verhalten ablesen kann.

---

### Schritt 2 — Simulation starten

Im Aktionsmenü der Setup-Seite auf **Run Simulation** klicken.

**Was passiert im Hintergrund:**
1. Die aktuellen Parameter werden gespeichert.
2. Alle bisherigen Simulationsergebnisse werden gelöscht.
3. Die Engine berechnet für jeden Zeitschritt t = 0 … N−1 die Werte Preis, Nachfrage, Angebot und Delta.
4. Nach Abschluss erscheint die Meldung: *„Simulation completed. Open the Simulation Entries page to review results."*

> **Sicherheitshinweis:** Wenn der Preis den Schwellenwert von 1 × 10⁹ überschreitet (explodierende Simulation), bricht die Berechnung vorzeitig ab und zeigt eine Warnmeldung.

---

### Schritt 3 — Ergebnisse ansehen

Auf der Setup-Seite **Show Entries** klicken (oder in der Suche **Cycle Simulation Entries** eingeben).  
Es öffnet sich eine **List-Page** (schreibgeschützt) mit folgenden Spalten:

| Spalte | Beschreibung |
|---|---|
| **Entry No.** | Eindeutige laufende Nummer |
| **Time Step** | Zeitschritt t (0-basiert) — jede Zeile = eine Produktionsperiode |
| **Price P(t)** | Marktpreis zum Zeitpunkt t |
| **Demand D(t)** | Berechnete Nachfrage: A − B·P(t) |
| **Supply S(t)** | Berechnetes Angebot: C + D·P(t−1) — reagiert auf den Preis der *Vorperiode* |
| **Delta D(t)−S(t)** | Überschuss-Nachfrage (grün/positiv) oder Überschuss-Angebot (rot/negativ) |
| **Behavior Type** | Nur in der letzten Zeile ausgefüllt: **Stable**, **Oscillating** oder **Exploding** |
| **Created At** | Zeitstempel der Berechnung |

**Farbcodierung der Delta-Spalte:**
- 🟢 **Grün (Favorable):** Nachfrage > Angebot → Preis steigt in der nächsten Periode
- 🔴 **Rot (Unfavorable):** Angebot > Nachfrage → Preis fällt in der nächsten Periode
- ⚪ **Neutral (Standard):** Markt ist ausgeglichen (Delta = 0)

---

### Schritt 4 — Ergebnisse exportieren

Auf **Export to Excel** klicken (verfügbar sowohl auf der Setup-Seite als auch in der Entries-Liste).  
Es wird eine Excel-Datei `CobwebSimulation.xlsx` mit dem Arbeitsblatt *Results* generiert und automatisch zum Download angeboten.

Die Excel-Datei enthält die Spalten: `Time Step | Price P(t) | Demand D(t) | Supply S(t) | Delta D-S | Behavior Type`

---

### Schritt 5 — Simulation zurücksetzen

Auf **Reset Simulation** klicken → Bestätigungsdialog *„Delete all simulation entries?"* bestätigen.  
Alle bisherigen Einträge werden gelöscht, damit eine neue Simulation mit geänderten Parametern sauber starten kann.

---

### Zusammenfassung: Typischer Ablauf

```
┌─────────────────────────┐
│  Cycle Simulation Setup │
│  (Card-Page)            │
│                         │
│  Parameter anpassen     │
│  ↓                      │
│  [Run Simulation]       │──→  Engine berechnet alle Zeitschritte
│  ↓                      │
│  [Show Entries]         │──→  Ergebnisliste anzeigen
│  ↓                      │
│  [Export to Excel]      │──→  Excel-Download
│  ↓                      │
│  [Reset Simulation]     │──→  Daten löschen, neu starten
└─────────────────────────┘
```

---

## 6. Code Design Principles

- **Separation of concerns** — calculation logic lives entirely in `CycleSimulationEngine`; pages hold no business logic.
- **Reproducibility** — no randomisation; identical parameters always yield identical results.
- **Numerical safety** — an early-exit guard aborts the loop if price exceeds 1 × 10⁹.
- **Commented mathematics** — every formula has an inline comment linking code to the mathematical model.
- **Extensibility** — the enum is extensible, the setup table uses a singleton pattern, and the engine exposes separate `RunSimulation`, `ResetSimulation`, and `ExportToExcelBuffer` procedures.
