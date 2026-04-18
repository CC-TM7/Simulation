# TODO – Cobweb Model Simulation

> Automatisch generiert am 2026-04-17 durch Codeunit-Analyse gemäß `analyze-codeunits.prompt.md`

---

## 🔴 KRITISCH

- [x] **Hardcodierte Error-Strings** – `ValidateSetup()` in `CycleSimulationEngine.Codeunit.al`: Alle `Error()`-Aufrufe auf `Label`-Variablen + `ErrorInfo` mit Navigation umgestellt.
- [x] **Hardcodierte Message-Strings** – `RunSimulation()` und `ResetSimulation()`: `Message()`-Aufrufe auf Labels umgestellt.
- [x] **Hardcodierte Excel-Header** – `ExportToExcelBuffer()`: Spaltenüberschriften auf Labels umgestellt.

---

## 🟠 WARNUNG

- [x] **Fehlende SetLoadFields()** – `ExportToExcelBuffer()`: `SetLoadFields()` vor `FindSet()` ergänzt.
- [x] **Fehlende SetLoadFields()** – `StampBehaviorType()`: `SetLoadFields("Behavior Type")` vor `FindLast()` ergänzt.
- [ ] **Modify() ohne true** – `StampBehaviorType()`: `SimEntry.Modify()` bewusst ohne `true` – Tabelle hat keine relevanten OnModify-Trigger.
- [x] **Fehlende LockTable()** – `RunSimulation()`: `LockTable()` vor `DeleteAll()` ergänzt.
- [x] **Kein ErrorInfo mit Navigation** – `ValidateSetup()`: Auf `ErrorInfo` mit `PageNo` und `FieldNo` umgestellt.

---

## 🟡 VERBESSERUNG

- [ ] **Fehlender CCO-Prefix** – Alle Objekte (Codeunit 50300, Table 50300/50301, Enum 50300) tragen keinen `CCO`-Prefix. Laut Naming Conventions Rule 1 erforderlich für ID-Range 50000–99999.
- [ ] **Fehlende Namespace-Deklaration** – Keine Objekte verwenden `namespace`. Laut Namespace-Guideline sollte ein passender Namespace definiert werden.
- [ ] **Ordnerstruktur object-type-basiert** – Aktuelle Struktur `src/Codeunits/`, `src/Tables/`, `src/Pages/` statt Feature-basiert (`src/Simulation/`). Verstößt gegen Code Style Rule 2.
- [ ] **RunSimulation() zu lang** – Prozedur umfasst ~70 Zeilen, empfohlen sind max. 50. Setup-Loading, Loop und Classify könnten in separate lokale Prozeduren extrahiert werden.
- [ ] **XML-Doku unvollständig** – Öffentliche Prozeduren `RunSimulation()`, `ResetSimulation()`, `ExportToExcelBuffer()` könnten `<param>` und `<returns>`-Tags ergänzen.
- [ ] **Kein Telemetry-Logging** – Bei Simulationsdurchläufen wird kein `Session.LogMessage()` verwendet. Für Nachvollziehbarkeit im produktiven Betrieb empfehlenswert.

---

> Ergänzt am 2026-04-17 durch Table-Analyse gemäß `analyze-tables.prompt.md`

## 🔴 KRITISCH (Tables)

- [x] **Hardcodierter Error-String in Table** – `CycleSimulationSetup.Table.al`: `ValidatePositive()` verwendet bereits `Label`-Variable (bereits behoben).
- [ ] **Fehlende `Locked = true` auf Enum-Value `" "`** – `CycleBehaviorType.Enum.al` Zeile 15–18: `Caption = ' '` enthält keine alphabetischen Zeichen → muss `Locked = true` erhalten (Translation Rule 3).
- [ ] **Falsche `DataClassification` auf systemgenerierten Feldern** – `CycleSimulationEntry.Table.al`: `"Entry No."` (AutoIncrement) und `"Created At"` sind als `CustomerContent` klassifiziert. Korrekt: `SystemMetadata`.

## 🟠 WARNUNG (Tables)

- [x] **Kein Integration Event in `GetSetup()`** – `CycleSimulationSetup.Table.al` Zeile 127–145: Erstellt Default-Werte und inserted ohne Events. `OnBeforeGetSetup`/`OnAfterGetSetup` fehlen für Erweiterbarkeit (Events Rule 2).
- [x] **`GetSetup()` gibt Record als Rückgabewert zurück** – `CycleSimulationSetup.Table.al`: In AL ist ein `var`-Parameter üblicher. Record-Return verhindert, dass Subscriber den Rückgabewert per `var` beeinflussen können.
- [x] **`MinValue = 0` vs. `ValidatePositive` (> 0) – Inkonsistenz** – `CycleSimulationSetup.Table.al`: Felder "Parameter A/B/D", "Adjustment Factor K" haben `MinValue = 0`, aber `ValidatePositive` fordert `> 0`. Wert `0` wird von der Platform akzeptiert, aber vom Trigger abgelehnt.

## 🟡 VERBESSERUNG (Tables)

- [ ] **Keine `supportedLocales` in app.json** – Aktuell sind keine Sprachen definiert. Sobald Sprachen ergänzt werden, müssen alle Captions `Comment`-Attribute erhalten.
- [ ] **Fehlende ToolTips auf Table-Feldern** – Beide Tables haben keine `ToolTip`-Properties auf Feld-Ebene.
- [x] **Enum `Extensible = true` prüfen** – `CycleBehaviorType.Enum.al`: Die drei Verhaltenstypen sind mathematisch abschließend. `Extensible = false` verhindert unerwartete Werte durch Fremd-Extensions.

---

> Ergänzt am 2026-04-17 durch Page-Analyse gemäß `analyze-pages.prompt.md`

## 🟠 WARNUNG (Pages)

- [x] **Hardcodierte Strings in Page-Actions** – `CycleSimulationEntries.Page.al`: `Confirm(...)` und `CycleSimulationSetup.Page.al`: `Message(...)` / `Confirm(...)` → Label-Variablen eingeführt.
- [x] **Hardcodierte Display-Texte in Helper-Prozeduren** – `CycleSimulationSetup.Page.al`: `GetStabilityRatioText()` / `GetEquilibriumPriceText()` → Label-Variablen im Codeunit.
- [x] **Magic Numbers in Stabilitäts-Anzeige** – Schwellwerte `0.95`/`1.05` → konsolidiert mit `StabilityTolerance` in `GetStabilityRatioText()` im Codeunit (identische Toleranz wie `ClassifyBehavior()`).
- [x] **Business-Logik auf Page statt in Codeunit** – `GetStabilityRatioText()` / `GetEquilibriumPriceText()` → nach `Codeunit "Cycle Simulation Engine"` verschoben. Pages delegieren nur noch.
- [x] **Redundante Setup-Initialisierung in OnOpenPage** – `CycleSimulationSetup.Page.al`: Vereinfacht auf `Rec.GetSetup(Rec)`.

## 🟡 VERBESSERUNG (Pages)

- [x] **Duplizierter Confirm-Text** – Beide Pages verwenden nun jeweils eine eigene `Label`-Variable `ConfirmDeleteQst` (identischer Text, aber jeweils lokal deklariert – akzeptabel für Pages).
- [x] **Redundante OnOpenPage-Logik entfernt** – Vereinfacht: kein separater Get/Insert-Check mehr, vollständig an `GetSetup()` delegiert.
- [ ] **Indentation 4 Spaces statt 2** – Alle Pages verwenden 4-Space-Einrückung. Gemäß `al-code-style` Rule 1 werden 2 Spaces bevorzugt.

---

## 📊 Gesamtzusammenfassung

| Kategorie | Codeunits | Tables | Pages | Gesamt | Davon erledigt |
|---|---|---|---|---|---|
| 🔴 KRITISCH | 3 | 3 | 0 | **6** | 1 |
| 🟠 WARNUNG | 5 | 3 | 5 | **13** | 8 |
| 🟡 VERBESSERUNG | 6 | 3 | 3 | **12** | 4 |
| **Gesamt** | 14 | 9 | 8 | **31** | **13** |
