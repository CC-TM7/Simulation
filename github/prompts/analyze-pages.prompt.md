---
description: Page-Analyse auf Schwachstellen
---

Lies die Coding-Guidelines und analysiere dann alle Pages und Page Extensions auf Schwachstellen:

**Guidelines lesen:**
#file:../instructions/al-code-style.instructions.md
#file:../instructions/al-translations.instructions.md
#file:../instructions/al-performance.instructions.md

**Pages analysieren:**
- src/Pag51251.DemandChainSetup.al
- src/Pag51252.DemandChainFactBoxSH.al
- src/Pag51253.DemandChainList.al
- src/Pag51254.DemandChainList_All.al

**Page Extensions analysieren:**
- src/Pag-Ext51250.SalesOrderSubform.al
- src/Pag-Ext51251.SaleLines.al
- src/Pag-Ext51252.FirmPlannedProdOrderLines.al
- src/Pag-Ext51253.ServiceLines.al
- src/Pag-Ext51254.SalesOrderList.al
- src/Pag-Ext51255.FirmPlannedProdOrders.al
- src/Pag-Ext51256.SalesOrder.al

**Prüfe auf:**
- Fehlende ToolTips und Captions
- Fehlende ApplicationArea
- FlowFields ohne CalcFields
- Komplexe Logik in OnAfterGetRecord
- Business-Logik auf Page statt in Codeunit
- Fehlende UsageCategory bei List-Pages
- Hardcodierte Werte

**Ausgabe als Bericht:**
- 🔴 KRITISCH: Performance-Blocker, Berechtigungsprobleme
- 🟠 WARNUNG: Fehlende ToolTips, UX-Probleme
- 🟡 VERBESSERUNG: Layout, Naming
- 📊 Zusammenfassung mit Anzahl pro Kategorie

**ToDos schreiben:**
#file:./todo.prompt.md
