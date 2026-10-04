# Herkunft des Lüfter-Backends

`razer-laptop-control/` enthält den Quellstand von
[JosuGZ/razer-laptop-control](https://github.com/JosuGZ/razer-laptop-control)
bei Commit `2c224ef0cda712f826056450d89e12c5f7bf3d0d`, einschließlich
Cargo.lock, Geräte-Datenbank und ursprünglicher GPL-2.0-Lizenzdatei.

Übernommen wurden die auf dem Razer vorhandenen lokalen Änderungen an CLI,
IPC und Daemon sowie das Beispiel `read_tachometer.rs`. Sie ergänzen
`razer-cli read actual-fan` und die Ausgabe `TACHOMETER_JSON:[rpm1,rpm2]`.
Die Auflösung beträgt 100 RPM; fehlgeschlagene Messungen ergeben `null`.
Fan 1 und 2 sind nicht zuverlässig CPU beziehungsweise GPU zugeordnet.

Die vorhandene `LOCAL-TACHOMETER.md` ist eine historische Entwicklungsnotiz;
ihre alten Widget-IDs sind nicht die aktuelle Installationsanleitung.
Die aktuelle Anleitung steht in der README im Projektwurzelverzeichnis.

Keine kompilierten Binärdateien, Cargo-Build-Artefakte oder Benutzerprofile
werden mitgeliefert. Die ursprünglichen Autoren- und Lizenzangaben bleiben
in den Quelldateien erhalten. Die GPL-Lizenz des Backends ist in
[razer-laptop-control/LICENSE](razer-laptop-control/LICENSE) enthalten.
