# Razor14 Linux Monitor

Transparentes KDE-Plasma-Widget für Temperatur, Auslastung und Lüfterdrehzahlen eines Razer Blade 14. Mit Verlauf, Lüftersteuerung und wählbarer Sichtbarkeit über anderen Anwendungen.

**Eigenständiges Projekt:** Das Widget und die Lüftersteuerung benötigen weder RhiNux noch eine Windows-VM. Die Windows-GPU-Telemetrie ist eine optionale Erweiterung für GPU-Passthrough.

## Funktionen

- CPU-Temperatur und -Auslastung, AMD-iGPU- und NVIDIA-GPU-Messwerte.
- Tatsächlich gemessene Drehzahlen beider Lüfter, getrennt von den eingestellten Sollwerten.
- Zehn Minuten Verlauf für Last, Temperatur und Drehzahl; Aktualisierung etwa alle zehn Sekunden.
- Lüfterautomatik oder 5.000-RPM-Sollwert im Netzbetrieb.
- Transparente Anzeige oben rechts, kompakt oder ausgeklappt.
- **Mouseover: sichtbar** oder **Immer im Vordergrund**, auch über Vollbildanwendungen.
- Optional: Gast-Messwerte, wenn die NVIDIA-GPU an Windows durchgereicht ist.
- Optional: vorhandener experimenteller Full-save-Controller für CPU-Profil und GPU-Stromsparmodus.

## Unterstützter Stand

| Bestandteil | Referenzsystem / Voraussetzung |
| --- | --- |
| Gerät | Razer Blade 14 (2021), Ryzen 9 5900HX, RTX 3070 Laptop |
| Betriebssystem | Fedora 44, KDE Plasma 6, Wayland, systemd |
| Razer-HID | USB `1532:0270`; udev-Regel nur für dieses Modell |
| CPU-Sensor | `k10temp` in `/sys/class/hwmon` |
| AMD-iGPU | PCI `0000:04:00.0` |
| NVIDIA-GPU / Audio | PCI `0000:01:00.0` / `0000:01:00.1` |
| Stromversorgung | `/sys/class/power_supply/AC0/online` |

Diese Hardware-Adressen sind derzeit im Code festgelegt. Andere Modelle sind kein getestetes Installationsziel. Eine Installation auf einem anderen Gerät erfordert Prüfung und Anpassung der Sensoren, PCI-Adressen und HID-Regel.

## Installation auf Fedora KDE

Im Terminal der lokal angemeldeten KDE-Sitzung arbeiten. Für die Benutzerkomponenten **kein sudo** verwenden. Die Lüftersteuerung erhält HID-Zugriff über die aktive lokale Sitzung; eine reine SSH-Anmeldung ersetzt diese nicht.

### 1. Quellcode und Build-Abhängigkeiten

```bash
git clone https://github.com/h4ppysh4dow/razor14-linux-monitor.git
cd razor14-linux-monitor
sudo dnf install git rust cargo gcc pkgconf-pkg-config gtk3-devel dbus-devel systemd-devel python3
```

Die genannten Entwicklungsbibliotheken entsprechen dem vorhandenen Referenzsystem. Der normale Linux-NVIDIA-Messpfad setzt außerdem einen funktionierenden NVIDIA-Treiber mit `nvidia-smi` voraus. Die Treiberinstallation ist nicht Teil dieses Projekts.

### 2. Lüfter-Backend bauen und installieren

```bash
bash scripts/install-fan-backend.sh
```

Das Skript baut den mitgelieferten Rust-Quellcode mit `Cargo.lock`, sichert vorhandene Benutzerprogramme, installiert CLI, Daemon und Einstellungsfenster und startet `razercontrol.service` als Benutzerdienst. Es installiert außerdem die Geräte-Datenbank und eine auf `1532:0270` begrenzte udev-Regel mit sudo. Der optionale Full-save-Systemdienst wird dabei nicht aktiviert.

```bash
systemctl --user status razercontrol.service
~/.local/bin/razer-cli read actual-fan
```

Die letzte Ausgabe enthält beispielsweise `TACHOMETER_JSON:[3300,3600]`. Die Messauflösung beträgt 100 RPM. Die Zuordnung der beiden Lüfter zu CPU/GPU ist nicht gesichert; deshalb heißen sie **Fan 1 / Fan 2**.

### 3. Plasma-Widget installieren

```bash
python3 host/install-monitor.py
```

Der Installer kopiert Messwerthelfer, Plasma-Widget und KWin-Platzierungsskript, aktiviert das KWin-Skript und startet die Plasma-Shell neu. Anwendungen bleiben geöffnet. Vorhandene Dateien werden unter `~/.local/state/rhinux/monitor-backup-*` gesichert; der historische Pfad ist aus Kompatibilitätsgründen erhalten.

Bei einer Erstinstallation anschließend über **Arbeitsfläche bearbeiten → Miniprogramme hinzufügen** das Widget **Blade Temperatur und Lüfter** einmal hinzufügen. Auf dem bereits eingerichteten Razer wird die vorhandene Instanz aktualisiert. Der Installer legt keine zweite Widget-Instanz an.

## Bedienung

Mit der Maus oben rechts über den Bereich der kompakten Anzeige fahren. Ein Klick auf die Messwerte klappt das Widget auf oder zu.

**Nur ausgeklappt** sind die beiden Sichtbarkeitsoptionen verfügbar:

- **Mouseover: sichtbar:** Anzeige beim Überfahren einblenden, beim Verlassen ausblenden. Der aufgeklappte Zustand bleibt erhalten; zum erneuten Einblenden den kompakten Bereich oben rechts berühren.
- **Immer im Vordergrund:** Anzeige unabhängig vom Mauszeiger sichtbar halten, auch über Vollbildfenstern.

Die Auswahl wird gespeichert. Es gibt keine Entkoppeln-/Anheften-Funktion und keine Hintergrundfläche.

Die untere **auto / max**-Auswahl steuert die Lüfter: `auto` nutzt die Geräteautomatik, `max` setzt 5.000 RPM als Sollwert. Diese Bedienung ist nur im Netzbetrieb verfügbar. Die tatsächliche Drehzahl wird separat gemessen und kann vom Sollwert abweichen.

Die obere **auto / save**-Auswahl gehört zum optionalen Full-save-Dienst. Ohne laufenden Dienst ist sie deaktiviert. `save` ist zudem bei Netzbetrieb oder aktiver Windows-GPU-Zuordnung gesperrt.

Bei eingefangener Looking-Glass-Eingabe zuerst **rechte Strg-Taste** drücken, damit der Linux-Zeiger das Widget erreichen kann.

## Optionale Windows-GPU-Telemetrie

Bei PCI-Passthrough gehört die NVIDIA-GPU dem Gast. Dann kann Linux sie nicht mit seinem NVIDIA-Treiber abfragen. Die mitgelieferten PowerShell-Skripte lesen im Windows-Gast Temperatur und Last mit `nvidia-smi` aus und veröffentlichen ausschließlich Messwerte in einer gemeinsam zugänglichen Datei.

[Einrichtung, Datenformat und Gültigkeitsprüfung](docs/monitor.md)

Die vorhandene Integration erwartet standardmäßig `/mnt/external/shared/rhinux-telemetry/gpu.json` und die Zuordnungsdatei `/run/rhinux-gpu-owner`. Für einen anderen SSD-Mountpunkt:

```bash
python3 host/install-monitor.py --ssd-root /anderer/mountpunkt
```

Bei einer anderen VM-Verwaltung muss auch die Zuordnungsdatei angepasst beziehungsweise bei jeder GPU-Übergabe erneuert werden. Ohne sie werden Gastwerte nicht übernommen. Die alten `rhinux`-Datei-, Task- und Plugin-Namen sind Kompatibilitätskennungen, keine Projektabhängigkeit für den normalen Linux-Betrieb.

## Optionaler Full-save-Dienst

[Einrichtung und bekannte Grenzen](docs/power-service.md)

Der vollständige Python-Controller und die systemd-Unit sind enthalten. **Auf dem zuletzt geprüften Razer ist der Dienst inaktiv.** Der normale Monitor und die Lüftersteuerung funktionieren unabhängig davon. Der Controller wird nicht automatisch installiert oder gestartet, weil er über Cardwire die GPU-Verfügbarkeit und das CPU-Energieprofil verändert.

## Projektaufbau

| Pfad | Inhalt |
| --- | --- |
| `host/widget/` | Plasma-QML, Verlaufsgrafiken und Einstellungen |
| `host/monitor-placement/` | KWin-Skript für die feste Position |
| `host/razor14-thermal-status` | Linux-Messwerte, Verlauf und Lüfterbefehle |
| `host/razor14-power-client` | Unprivilegierter Client für den optionalen Systemdienst |
| `host/razor14-power` | Optionaler Full-save-Controller |
| `host/systemd/`, `host/udev/` | Dienstdefinitionen und Gerätezugriff |
| `vendor/razer-laptop-control/` | Rust-Backend inklusive lokaler Tachometer-Erweiterung |
| `scripts/install-fan-backend.sh` | Build und Installation des Lüfter-Backends |
| `host/install-monitor.py` | Benutzerinstallation des Widgets |
| `windows/` | Optionaler GPU-Telemetrie-Publisher |
| `tests/` | Automatisierte Prüfungen |

## Prüfung und Fehlersuche

```bash
python3 -m unittest discover -s tests -v
bash -n scripts/install-fan-backend.sh
cargo check --locked --manifest-path vendor/razer-laptop-control/Cargo.toml -p service --bins
```

Auf dem Gerät:

```bash
~/.local/bin/razor14-thermal-status
~/.local/bin/razer-cli read actual-fan
systemctl --user status razercontrol.service
journalctl --user -u razercontrol.service -b
journalctl --user -u plasma-plasmashell.service -b
```

- **Keine Lüfterwerte:** lokale KDE-Anmeldung, HID-Regel, Daemon und Geräte-Datenbank prüfen. CLI und Daemon gemeinsam aus derselben Quellversion bauen.
- **Full-save-Dienst nicht erreichbar:** betrifft nur die optionale Energiesparfunktion; siehe separate Anleitung.
- **Windows · wartet / veraltet:** Gastanmeldung, geplante Aufgabe, Freigabe und Zuordnungsdatei prüfen. Ungültige Werte erscheinen als `—`, nicht als erfundene Nullwerte.
- **NVIDIA schläft:** Der Helfer vermeidet eine NVIDIA-Abfrage bei suspendierter GPU. Andere Sensorprogramme können die GPU trotzdem wachhalten.
- **Widget fehlt:** Widget einmal hinzufügen und das KWin-Skript in den Systemeinstellungen prüfen. Es positioniert ausschließlich das Fenster `Razer 14 Monitor`.

Am Referenzsystem wurden Messwerte, Tachometer, Mouseover, dauerhafte Sichtbarkeit, Auf-/Zuklappen, Positionierung und Anzeige über Looking Glass geprüft. Die Gast-Telemetrie wurde außerdem über VM-Stopp/Start geprüft. Eine vollständige Neuinstallation auf einem zweiten Rechner und der optionale Full-save-Dienst wurden für diese Veröffentlichung nicht erneut getestet.

## Entfernen / Wiederherstellen

Widget vom Desktop entfernen und das KWin-Skript in **Systemeinstellungen → Fensterverwaltung → KWin-Skripte** deaktivieren. Bei einem Update die Dateien aus der vom jeweiligen Installer ausgegebenen Sicherung wiederherstellen.

Wenn das Lüfter-Backend vollständig entfernt werden soll, zunächst wieder Lüfterautomatik einstellen, dann `systemctl --user disable --now razercontrol.service` ausführen. Nur die von diesem Projekt installierten Programme, die Dienstdatei und die spezifische udev-Regel entfernen. Eine anderweitig genutzte Razer-Geräte-Datenbank nicht löschen. Die Entfernung des optionalen Systemdienstes und der Windows-Aufgabe ist in den jeweiligen Anleitungen beschrieben.

## Herkunft und Lizenzen

Der enthaltene Fork von [Razer Laptop Control](https://github.com/JosuGZ/razer-laptop-control) basiert auf Commit `2c224ef0cda712f826056450d89e12c5f7bf3d0d`. Seine ursprüngliche GPL-2.0-Lizenz und Autorenangaben bleiben erhalten. Änderungen und Herkunft sind unter [vendor/README.md](vendor/README.md) dokumentiert.

Für die übrigen projektinternen Dateien wurde noch keine einheitliche Weiterverwendungslizenz festgelegt; vorhandene Einzelangaben bleiben erhalten. Dieses Repository enthält keine Windows-/Rhino-Installation, Lizenzdaten, Zugangsdaten, Laufzeitprofile oder vorkompilierten Lüfterprogramme.
