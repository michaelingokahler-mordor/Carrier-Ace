# Carrier Ace 0.1.0

Eine eigene Arcade-Flugmission mit fiktiven Propellerflugzeugen: vom Träger starten, sechs Gegnerwellen überstehen, den Bomber Behemoth abschießen und wieder an Bord landen. Deutsche Oberfläche, Tastatur und Gamepad, ein Flugzeug und ein Level. Erfolgreiche Flüge dauern ungefähr vier bis fünf Minuten.

## Spielen

**Windows:** `CarrierAce-0.1.0-Windows-x64.zip` vollständig entpacken und `CarrierAce.exe` starten. Keine Installation und keine zusätzliche Engine erforderlich. Windows x64 mit einem aktuellen OpenGL-3.3-fähigen Grafiktreiber.

**Browser unter Windows:** `CarrierAce-0.1.0-Web.zip` vollständig entpacken und `Start-Browser.cmd` starten. Das Konsolenfenster während des Spiels offen lassen. `CarrierServer.exe` stellt ausschließlich unter `http://127.0.0.1:1942/` einen lokalen HTTP-Server bereit. Beenden mit Strg+C. Keine Python-Installation erforderlich; der kleine Server nutzt das in Windows enthaltene .NET Framework 4.x. Bei belegtem Port: `CarrierServer.exe --port=1943`. Alternativ liegt ein PowerShell-Server bei; das Paket ändert keine Systemrichtlinien.

Alternativ mit Python 3 im Webordner: `python -m http.server 1942 --bind 127.0.0.1`, danach `http://127.0.0.1:1942/` öffnen. `index.html` nicht direkt per Doppelklick öffnen. Aktueller Desktop-Browser mit WebGL 2 nötig. Der erste Tastendruck bzw. Klick schaltet Audio frei. Alle Grafik- und Audiodateien sind im Paket enthalten; während des Spiels werden keine externen Dienste aufgerufen.

| Aktion | Tastatur | Gamepad |
|---|---|---|
| Fliegen | WASD / Pfeile | Linker Stick / Steuerkreuz |
| Feuern, gedrückt halten | Leertaste / Z | Hauptbutton / A |
| Rolle | Shift / X | Zweiter Button / B |
| Pause | Esc / P | Start |
| Menü bedienen | Pfeile / Tab / Enter | Steuerkreuz / A |
| Vollbild | F11 | — |

Goldmarkierte Viererformationen vollständig abschießen, um das festgelegte Upgrade zu erhalten. Reparatur: +30 Panzerung bis 100. Doppelschuss und Trippelschuss bleiben bis zum Flugzeugverlust; schwächere Pickups setzen die Stufe nicht herab. Speed: +15%, höchstens 130%. Drei Rollen geben jeweils eine Sekunde Unverwundbarkeit. Nach einem Abschuss beginnt die komplette Mission mit dem nächsten der drei Flugzeuge von vorn. Nach dem dritten Abschuss ist Game Over.

Nach dem Boss erscheint der Träger. Kurz im grün markierten Einflugbereich bleiben: Nach 0,75 Sekunden übernimmt das Flugzeug die Landung. Ein verfehlter Anflug kostet kein Leben. Punkte gelten pro Versuch; der höchste Versuch wird gespeichert. Windows speichert Toneinstellungen und Highscore unter `%APPDATA%\Godot\app_userdata\Carrier Ace\carrier_ace.cfg`; der Browser nutzt lokalen Speicher. Privates Browsen bzw. blockierter Speicher kann dauerhafte Speicherung verhindern.

## Projekt und Builds

Festgeschrieben: **Godot 4.7.2 Standard**, GDScript und Compatibility-Renderer; 960×540 mit seitenverhältnistreuer Skalierung. Web ohne Threads. Die offiziellen Engine- und Exportdateien liegen lokal unter `.tools/` und sind nicht versioniert. Engine und Vorlagen müssen dieselbe Version haben. Das Projekt lässt sich über `project.godot` im Editor öffnen.

```
python tools/build.py
```

Der Build erwartet `.tools/godot/Godot_v4.7.2-stable_win64_console.exe` sowie die vier in `export_presets.cfg` genannten Vorlagen unter `.tools/templates/`. Download: [offizielle Godot-Version](https://godotengine.org/download/windows/4.7.2/). `tools/fetch_templates.py` lädt nur die benötigten Teile des offiziellen Vorlagenarchivs. `build.py` prüft die Engine-Version, importiert, exportiert beide Plattformen und erstellt ZIPs mit Dokumentation sowie SHA-256-Prüfsummen unter `builds/`. Einen laufenden `CarrierServer.exe` vorher schließen. `python tools/build.py --package-only` aktualisiert nur die ZIPs vorhandener Exporte, etwa nach einer Dokumentationsänderung.

Regeltests:

```
.tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/test_core.gd
.tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/test_ui.gd
```

Für isolierte lokale Tests gegebenenfalls `APPDATA` nur im aktuellen Prozess auf `.tools/runtime-profile` setzen. Der Build tut dies bereits. Native Prüfung mit unverändertem Spielmodell und automatischem Testpiloten:

```
CarrierAce.exe -- --verify --silent --report=report.json --capture-dir=captures
```

Der Testpilot verwendet Bewegung, Schüsse und Rollen; er überspringt keine Missionszustände und setzt keine Trefferpunkte. Der Prüflauf beschleunigt die Simulationszeit um Faktor 12. Im Browser aktiviert `?verify=1` denselben Testpiloten und zeigt den Zustand als Diagnosefeld. Diese Option ist für Entwickler; normales Spielen erfolgt ohne Parameter.

`resources/` enthält Flugzeug-, Gegner-, Waffen- und Wellenprofile. `scripts/mission_model.gd` hält die Regeln unabhängig von Grafik und Audio. `scripts/world_view.gd` zeichnet die Welt; `main.gd` verbindet Eingabe, Menüs, Speicher und Audio. Grafikvorlagen und bezahlte Aufgaben sind in `assets/manifest.json` dokumentiert. Fertige PNG-/OGG-Assets sind versioniert. Unbearbeitete Entwürfe in `assets/source/` gehören nicht zum Laufzeitpaket. Die einmalige Asset-Aufbereitung benötigt Pillow, NumPy und FFmpeg; zum Spielen und normalen Exportieren sind sie nicht nötig.

## Dokumentation

- `docs/RESEARCH_1942.md`: deutsche Recherche, Quellen und Ableitungen.
- `docs/DESIGN.md`: umgesetzte Werte, Wellen und Erweiterungspunkte.
- `docs/VALIDATION.md`: tatsächliche Tests und verbleibende Grenzen.
- `THIRD_PARTY_NOTICES.md`: Godot- und Asset-Hinweise.

Das Projekt hat ein lokales Git-Repository auf `main`. Kein Remote, keine öffentliche Veröffentlichung. Builds, Engine, Importcache und private Ausgangsentwürfe werden ignoriert.
