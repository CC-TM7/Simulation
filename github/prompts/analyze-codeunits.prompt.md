---
agent: ask
description: Analysiert AL Codeunits auf Schwachstellen, Performance-Probleme und Coding-Standard-Verstöße
---

# AL Codeunit Schwachstellen-Analyse

Analysiere alle Codeunits (Cod*.al) im Workspace auf potenzielle Schwachstellen und Verbesserungsmöglichkeiten.

## Prüfkategorien

### 1. Error Handling & Robustheit
- [ ] **TryFunction-Missbrauch**: Werden TryFunctions für Datenbankoperationen verwendet? (KRITISCH - kein Rollback!)
- [ ] **Fehlende Fehlerbehandlung**: Gibt es ungeschützte externe API-/Webservice-Aufrufe?
- [ ] **GetLastErrorText()**: Wird der Fehlertext korrekt ausgewertet nach Codeunit.Run()?
- [ ] **Error() vs. Message()**: Werden Fehler korrekt als Error() geworfen statt nur als Message()?
- [ ] **Leere Catch-Blöcke**: Werden Fehler verschluckt ohne Logging/Behandlung?

### 2. Performance-Probleme
- [ ] **Fehlende SetLoadFields()**: Werden Records geladen ohne SetLoadFields() vor Find/Get?
- [ ] **Späte Filterung**: Wird erst nach FindSet() gefiltert statt vorher mit SetRange/SetFilter?
- [ ] **FindFirst() in Schleifen**: Werden Get/FindFirst Aufrufe innerhalb von Schleifen gemacht?
- [ ] **Count() statt IsEmpty()**: Wird Count() > 0 verwendet statt not IsEmpty()?
- [ ] **CalcFields in Schleifen**: Werden FlowFields wiederholt in Schleifen berechnet?
- [ ] **Fehlende Commit()**: Fehlen Commits vor langlaufenden Operationen?

### 3. Transaktionssicherheit
- [ ] **Modify ohne true-Parameter**: Wird Modify() ohne Trigger-Ausführung verwendet wo nötig?
- [ ] **Fehlende LockTable()**: Fehlt LockTable() bei kritischen Update-Operationen?
- [ ] **Partial Commits**: Können Transaktionen teilweise committed werden (Dateninkonsistenz)?

### 4. Code-Qualität & Wartbarkeit
- [ ] **Hardcodierte Werte**: Gibt es Magic Numbers oder hardcodierte Strings statt Labels/Constants?
- [ ] **Fehlende XML-Dokumentation**: Haben globale Prozeduren XML-Dokumentation?
- [ ] **Zu lange Prozeduren**: Gibt es Prozeduren mit mehr als 50 Zeilen?
- [ ] **Tiefe Verschachtelung**: Gibt es mehr als 3 Ebenen verschachtelte IF/CASE?
- [ ] **Duplizierter Code**: Gibt es Copy-Paste-Code der refactored werden sollte?

### 5. Sicherheit
- [ ] **SQL-Injection**: Werden Filter-Strings ohne Escaping zusammengebaut?
- [ ] **Sensible Daten**: Werden Passwörter/API-Keys im Code gespeichert?
- [ ] **Fehlende Berechtigungsprüfung**: Fehlen Berechtigungsprüfungen vor sensitiven Operationen?

### 6. COSMO CONSULT Standards
- [ ] **Naming Conventions**: Entsprechen Namen den CCO/CCS-Konventionen?
- [ ] **Namespace-Verwendung**: Sind korrekte Namespaces definiert?
- [ ] **ID-Bereiche**: Liegen Object-IDs im korrekten Bereich (50000-99999 für CCO)?

## Ausgabeformat

Erstelle einen strukturierten Bericht mit folgenden Abschnitten:

### 🔴 KRITISCH (Sofort beheben)
Schwerwiegende Fehler die zu Datenverlust, Inkonsistenz oder Sicherheitsproblemen führen können.

### 🟠 WARNUNG (Zeitnah beheben)
Performance-Probleme oder potenzielle Fehlerquellen die die Stabilität beeinträchtigen.

### 🟡 VERBESSERUNG (Bei Gelegenheit)
Code-Qualität und Wartbarkeits-Verbesserungen.

### 📊 Zusammenfassung
- Anzahl analysierter Codeunits
- Gefundene Probleme pro Kategorie
- Priorisierte Maßnahmenliste

---

## Zu analysierende Dateien

Analysiere diese Codeunits im Workspace:
- src/Cod51251.DemandChainAIManagement.al
- src/Cod51252.DemandChainMgmt.al
- src/Cod51253.Install.al
- src/Cod51254.DemandChainTask.al

Beziehe die Coding-Guidelines aus `.github/instructions/` ein:
- #file:../instructions/al-error-handling.instructions.md
- #file:../instructions/al-performance.instructions.md
- #file:../instructions/al-code-style.instructions.md
- #file:../instructions/al-naming-conventions.instructions.md

**ToDos schreiben:**
#file:./todo.prompt.md
