# Optionaler Full-save-Controller

Der normale Monitor und die Lüftersteuerung benötigen diesen Dienst nicht. Der mitgelieferte Controller stammt vom Referenzgerät und ist dort derzeit inaktiv. Er ist ein experimenteller, gerätespezifischer Zusatz und wurde für diese Veröffentlichung nicht erneut im Energiesparbetrieb getestet.

## Verhalten und Grenzen

- `save` ist nur im Akkubetrieb vorgesehen. Der Controller stellt das CPU-Profil auf `power-saver` und fordert über Cardwire `integrated` an.
- Der Status gilt erst als aktiv, wenn CPU-Einstellungen passen, die RTX blockiert ist, GPU und Audio in D3cold sind und der NVIDIA-Treiber den Videospeicher als abgeschaltet meldet.
- Bei Netzanschluss oder Änderung des CPU-Profils kehrt er zu `auto` zurück.
- Beim Start fordert der Dienst `hybrid` an. `auto`, Recovery und Stop stellen ebenfalls `hybrid` sowie das vorherige CPU-Profil wieder her.
- Die Cardwire-Konfigurationswerte `experimental-nvidia-block`, `battery-auto-switch` und `external-display-auto-switch` werden verändert, aber nicht auf ihre vorherigen Werte zurückgesetzt. Vor Erprobung deren Werte notieren und bei Bedarf manuell wiederherstellen.
- Die GPU-Adressen sind für den Blade 14 festgelegt. Der Dienst darf nicht gleichzeitig mit einer anderen GPU-Umschaltung oder PCI-Passthrough-Erprobung aktiviert werden. Das Widget sperrt `save` für die Windows-Quelle; das ist keine vollständige gegenseitige Sperre der Systemdienste.

## Voraussetzungen

Ein funktionierendes `/usr/bin/cardwire`, `cardwired.service`, `tuned-ppd.service` und Python-GObject (`python3-gobject` auf Fedora). Cardwire wird nicht in diesem Repository mitgeliefert. Erst die vorhandene Installation prüfen:

```bash
command -v cardwire
systemctl status cardwired.service tuned-ppd.service
cardwire list --json
```

## Bewusste, separate Einrichtung

Aus dem Projektverzeichnis als normaler Desktop-Benutzer ausführen. Der Benutzername wird ausdrücklich für den Socket-Zugang hinterlegt; es gibt keinen fest eingebauten persönlichen Account.

```bash
sudo install -D -m 755 host/razor14-power /usr/local/libexec/razor14-power
sudo install -m 644 host/systemd/razor14-power.service /etc/systemd/system/razor14-power.service
sudo install -d -m 755 /etc/razor14-monitor
printf 'RAZOR14_USER=%s\n' "$(id -un)" | sudo tee /etc/razor14-monitor/power.env >/dev/null
sudo chmod 644 /etc/razor14-monitor/power.env
sudo systemctl daemon-reload
```

Erst nach Prüfung der oben genannten Voraussetzungen und ohne laufende GPU-Passthrough-VM testweise starten:

```bash
sudo systemctl start razor14-power.service
~/.local/bin/razor14-power-client status
journalctl -u razor14-power.service -b
```

Dies aktiviert keinen automatischen Start beim Booten. Erst nach eigener erfolgreicher Prüfung wäre `sudo systemctl enable razor14-power.service` der zusätzliche Schritt für Autostart.

Der Dienst läuft als root, akzeptiert über einen lokalen Unix-Socket ausschließlich `status`, `save` und `auto` vom konfigurierten Benutzer beziehungsweise root. Das Widget selbst braucht kein sudo. Fehlermeldungen erscheinen im Status-JSON und im Widget.

## Zurücksetzen und Entfernen

```bash
~/.local/bin/razor14-power-client auto
sudo systemctl disable --now razor14-power.service
```

Der Stop-Hook versucht die Wiederherstellung. Bei Fehlern `journalctl -u razor14-power.service -b` prüfen und `/var/lib/razor14-power/previous.json` bis zur erfolgreichen Wiederherstellung behalten. Anschließend können die installierte Unit, `/usr/local/libexec/razor14-power` und `/etc/razor14-monitor/power.env` entfernt und `sudo systemctl daemon-reload` ausgeführt werden. Die oben genannten Cardwire-Konfigurationswerte separat wiederherstellen.
