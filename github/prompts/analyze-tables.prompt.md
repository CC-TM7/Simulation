---
description: Table-Analyse auf Schwachstellen
---

Lies die Coding-Guidelines und analysiere dann alle Tables und Table Extensions auf Schwachstellen:

**Guidelines lesen:**
#file:.github/instructions/al-code-style.instructions.md
#file:.github/instructions/al-translations.instructions.md
#file:.github/instructions/al-performance.instructions.md
#file:.github/instructions/al-events.instructions.md

**Tables analysieren:**
- src/Tab51251.DemandChainEntryBuffer.al
- src/Tab51253.DemandChainSetup.al
- src/Tab51254.DemandChainEntry.al

**Table Extensions analysieren:**
- src/Tab-Ext51250.SalesLine.al
- src/Tab-Ext51251.ProdOrderLine.al
- src/Tab-Ext51252.ServiceLine.al
- src/Tab-Ext51253.SalesHeader.al
- src/Tab-Ext51254.ProductionOrder.al

**Prüfe auf:**
- Fehlende DataClassification (DSGVO!)
- Fehlende Captions mit Comment
- Fehlende/falsche TableRelations
- Komplexe Logik in Triggern
- Fehlende Integration Events
- Ineffiziente CalcFormulas
- Fehlende Keys für Performance

**Ausgabe als Bericht:**
- 🔴 KRITISCH: DSGVO-Verstöße, Datenintegritätsprobleme
- 🟠 WARNUNG: Fehlende Relations, zu viel Trigger-Logik
- 🟡 VERBESSERUNG: Naming, Dokumentation
- 📊 Zusammenfassung mit Anzahl pro Kategorie
