# Razer-Monitor: Windows-Messwerte und Vordergrundmodus

Die Erweiterung ergänzt das Plasma-Widget `local.razor14.history` um Gast-Messwerte. Die vollständige Linux-Installation einschließlich Lüfter-Backend steht in der [README](../README.md); der optionale Energiespardienst ist [separat dokumentiert](power-service.md).

## Einrichtung

Im Windows-Gast als Administrator:

```powershell
cd '\\host.lan\Data\razor14-linux-monitor\windows'
.\install-gpu-telemetry.ps1
```

Die Aufgabe **RhiNux GPU telemetry** startet nach der Benutzeranmeldung und läuft mit normalen Benutzerrechten. Sie fragt ausschließlich NVIDIA-Temperatur und -Auslastung ab und schreibt alle fünf Sekunden eine kleine JSON-Datei nach `\\host.lan\Data\rhinux-telemetry\gpu.json`. Keine Zugangsdaten werden gespeichert, und es gibt keinen Port oder Befehlsempfänger. Die beiden Windows-Skripte vorher gemeinsam nach `shared/razor14-linux-monitor/windows` auf der SSD kopieren; sie werden unabhängig vom VM-Setup installiert.

Auf dem Razer als Desktop-Benutzer, ohne sudo:

```bash
python3 host/install-monitor.py --ssd-root /mnt/external
```

Das sichert die vorhandenen Dateien unter `~/.local/state/rhinux/monitor-backup-*`, aktualisiert Widget und Helfer, aktiviert das gezielte KWin-Platzierungsskript und startet nur die Plasma-Shell neu. Geöffnete Anwendungen bleiben erhalten.

## Bedienung

Die Anzeige sitzt fest oben rechts. Ein Klick auf die Messwerte klappt Beschriftungen, Verlauf und Lüfterbedienung auf bzw. zu. **Nur in dieser ausgeklappten Ansicht** sind die beiden Sichtbarkeitsoptionen verfügbar:

- **Mouseover: sichtbar** (Standard): Die Anzeige erscheint, sobald der Zeiger den Bereich oben rechts berührt. Beim Verlassen verschwindet sie wieder. Der Bereich zum erneuten Einblenden entspricht der kompakten Anzeige; der aufgeklappte Zustand bleibt erhalten.
- **Immer im Vordergrund**: Die Anzeige bleibt auch ohne Maus darüber sichtbar, einschließlich über Looking Glass im Vollbild.

Es gibt kein Entkoppeln oder separates Anheften mehr. Die gewählte Sichtbarkeitsoption wird gespeichert. Bei eingefangener Looking-Glass-Eingabe zuerst die rechte Strg-Taste drücken, um den Linux-Monitor bedienen zu können.

Das KWin-Skript betrifft nur das Fenster mit Titel `Razer 14 Monitor` und hält es auch beim Auf- und Zuklappen oben rechts. Die Vordergrundebene liefert KDEs `OnScreenDisplay`-Rolle; eine normale „Immer oben“-Fensterregel allein lag unter aktivem Vollbild.

## Datenquelle und Gültigkeit

Der Linux-Helfer prüft den tatsächlichen PCI-Treiber. Unter `vfio-pci` verwendet er ausschließlich die Gastdatei und zeigt **Windows** an; beim NVIDIA-Hosttreiber verwendet er wieder die bisherige Linux-Abfrage. Das Widget aktualisiert sich alle zehn Sekunden.

Messwerte werden nur übernommen, wenn die Datei höchstens 20 Sekunden alt ist, nach der aktuellen GPU-Zuordnung erstellt wurde und gültige Zahlen enthält. Fehlende, veraltete oder ungültige Werte erscheinen als `—`, ergänzt um „Windows · wartet“ bzw. „Windows · veraltet“. Damit werden Werte aus dem vorherigen VM-Lauf nicht als aktuelle Werte gezeigt. Auch die Verlaufsdiagramme erhalten in diesem Fall keine erfundenen Nullwerte.

Geprüft: tatsächliche Windows-Telemetrie, automatischer Taskstart nach Docker-Stopp/Start, Rückwechsel auf Linux-Werte, Ablehnung alter Werte beim Neustart, Anzeige über Looking-Glass-Vollbild, Mouseover-Ein-/Ausblenden und Umschalten des dauerhaft sichtbaren Modus und Laden der endgültigen QML-Dateien ohne Widget-Ladefehler. Zusätzliche Tests decken fehlende, übergroße, ungültige, zukünftige und zur vorherigen VM gehörende Samples ab.

## Entfernen

In Windows die Aufgabe `RhiNux GPU telemetry` stoppen und entfernen, anschließend `C:\ProgramData\RhiNux\gpu-telemetry.ps1` entfernen. Unter Linux das Widget und den Helfer aus der Sicherung wiederherstellen und das KWin-Skript in Systemeinstellungen → Fensterverwaltung → KWin-Skripte deaktivieren. Die JSON-Messdatei auf der SSD kann gelöscht werden; sie enthält nur Messwerte und einen Zeitstempel.
