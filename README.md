# Carrier Ace 0.3.0 – Operation Blue Horizon

Ein Arcade-Flugspiel mit F6F Hellcat, sechs Gegnerwellen, neun regulären Gegnerprofilen, separatem B-99-Boss und Trägerlandung. Die Spieloberfläche ist Englisch; diese Dokumentation bleibt Deutsch. Ein erfolgreicher Prüfflug dauert rund 4:15 Minuten.

## Spielen

Windows: `CarrierAce-0.3.0-Windows-x64.zip` entpacken und `CarrierAce.exe` starten. Es ist keine Installation erforderlich.

Browser: `CarrierAce-0.3.0-Web.zip` entpacken und `Start-Browser.cmd` starten. Der mitgelieferte Server stellt das Spiel unter `http://127.0.0.1:1942/` bereit; Strg+C beendet ihn. Bei belegtem Port: `CarrierServer.exe --port=1943`. Der Server benötigt das in Windows enthaltene .NET Framework 4.x. Alternativ im Webordner `python -m http.server 1942 --bind 127.0.0.1` ausführen.

`index.html` über HTTP öffnen. Der Browser benötigt WebGL 2. Die erste Eingabe schaltet Audio frei. Alle Laufzeitdateien liegen lokal; das Spiel ruft keine externen Generierungsdienste auf.

| Aktion | Tastatur | Gamepad |
|---|---|---|
| Fliegen | WASD / Pfeile | Linker Stick / Steuerkreuz |
| Einzelne Salve feuern | Leertaste / Z, jeder Druck eine Salve | Hauptbutton / A, jeder Druck eine Salve |
| Rolle | Shift / X | Zweiter Button / B |
| Pause / Zurück | Esc / P | Start |
| Menü bedienen | Pfeile / Tab / Enter | Steuerkreuz / A |
| Vollbild | F11 | — |

Die Hellcat startet mit Armor 3/3, Penetration 0, Speed Rating 2 und Single Shot. Normale Treffer kosten einen Panzerungspunkt, angekündigte Ace-Raketen zwei. Drei Rollen geben jeweils eine Sekunde Schutz. Bei Armor null explodiert die Hellcat; nach 0,8 Sekunden erscheint Game Over. Ein neuer Flug startet nur auf ausdrückliche Eingabe.

Sechs gleichzeitig aktive Kugelplätze begrenzen die Bordkanone. Single/Double/Triple Shot brauchen jeweils 1/2/3 freie Plätze. Nur vollständige Salven sind möglich; Halten und Tastaturwiederholung feuern nicht. Bullets erhöht die Kapazität um zwei bis maximal 18. Ein Platz wird nach dem letzten zulässigen Treffer oder Verlassen des Spielfelds frei.

Goldmarkierte Viererformationen vollständig abschießen: ein garantierter Drop aus der Loot-Tabelle. Reguläre Abschüsse außerhalb dieser Formationen haben 3 % Dropchance. Neben Armor, Waffen und Speed gibt es Bullets, Rolls (+1 bis maximal drei) und Penetration (+1 zusätzliches Ziel, maximal drei). Waffen werden durch schwächere Pickups nicht herabgestuft. Speed addiert je Pickup 10% des Grundtempos; die Hellcat erreicht 195 → 214,5 → 234 → 253,5 → 260 logische Pixel/s.

Vollständig abgeschossene Anfluggruppen bringen 25 Bonus-Points je Mitglied. Ein nutzloses eingesammeltes Upgrade bringt 25. Landung schreibt die Flugpunkte dauerhaft gut; Game Over oder Abbruch verlieren nur ungesicherte Punkte. Score und Bonusbestand sind getrennt. Der Shop folgt später.

Alle Flugzeuge besitzen Konturflächen für Rumpf, Flügel und Leitwerk. Schatten und Propellerunschärfe zählen nicht. Die Prüfung berücksichtigt bewegte Ziele und Geschossbreite.

Nach dem Boss 0,75 Sekunden im grünen Einflugbereich bleiben; danach übernimmt das Spiel die Landung. Ein verfehlter Anflug kostet kein Leben. Die Flugzeugübersicht unter **Aircraft** zeigt nur Grundwerte. Sie lässt sich auch während der Pause öffnen.

Highscore, Bonusbestand und Toneinstellungen werden lokal gespeichert: Windows unter `%APPDATA%\Godot\app_userdata\Carrier Ace\carrier_ace.cfg`, im Browser in dessen lokalem Speicher. Privates Browsen kann dauerhafte Speicherung verhindern.

## Projekt und Builds

Festgeschrieben: **Godot 4.7.2 Standard**, GDScript, Compatibility-Renderer und Webexport ohne Threads. Die logischen Koordinaten bleiben 960×540; `canvas_items`, lineare Filter und hochauflösende Texturen ermöglichen die Darstellung bei 1920×1080. Andere Seitenverhältnisse erhalten freie Randbereiche.

`project.godot` im Editor öffnen. Engine und Vorlagen sind nicht versioniert. Der Build erwartet `.tools/godot/Godot_v4.7.2-stable_win64_console.exe` und die vier in `export_presets.cfg` angegebenen Vorlagen unter `.tools/templates/`. [Offizieller Download](https://godotengine.org/download/windows/4.7.2/). `tools/fetch_templates.py` lädt die benötigten Teile des offiziellen Vorlagenarchivs.

```powershell
python tools/build.py
python tools/run_godot.py --headless --script tests/test_core.gd
python tools/run_godot.py --headless --script tests/test_ui.gd
python tools/run_godot.py --headless --script tests/test_flight.gd
python tools/verify_windows.py
```

`build.py` prüft die Engine-Version, importiert, exportiert Windows und Web und erstellt drei ZIPs einschließlich Quellprojekt und Dokumentation. SHA-256-Prüfsummen stehen in `builds/SHA256SUMS.json`. Einen laufenden `CarrierServer.exe` vor einem neuen Build schließen. `--package-only` aktualisiert ZIPs vorhandener Exporte.

Der Export-Testpilot nutzt die normalen Kampfregeln. `CarrierAce.exe -- --verify --report=report.json` beschleunigt die Simulation zwölfmal; `--verify-real-time` arbeitet in normaler Missionsgeschwindigkeit. Im Web entsprechend `?verify=1` bzw. `?verify=1&realtime=1`. Die Parameter entfernen, um selbst zu spielen. Diagnosekonturen: Windows `-- --collisions`, Web `?collisions=1`.

Die Konturvorbereitung ist reproduzierbar aus den fertigen PNGs: `python tools/prepare_collision_contours.py`, danach `python tools/run_godot.py --headless --script tools/decompose_collision_contours.gd` und `python tools/create_profiles.py`. Dafür werden Pillow und NumPy benötigt. Laufzeit und Export verwenden nur die fertigen Ressourcen. Der normale Prüfflug benutzt Loot-Seed 1943; echte Flüge verwenden zufällige Loot-Werte.

`resources/` enthält Profil- und Wellendaten. `AircraftCatalog` versorgt Mission und Übersicht mit denselben Ressourcen. `mission_model.gd` hält die Regeln; `ocean_background.gd` und `shaders/` steuern Meer, Brandung und Inselroute. `main.gd` verbindet Eingabe, Menüs, Speicher und Audio.

Fertige PNG- und OGG-Dateien sind versioniert. Die hochauflösende Grafikaufbereitung erfolgt mit `tools/prepare_revision_art.py`; sie benötigt Pillow und NumPy sowie lokal vorhandene Rohentwürfe. Diese liegen unter `assets/source/` und sind kein Bestandteil des Quellarchivs. Für das Spielen und Exportieren reichen die fertigen Assets. Audio aus 0.1 bleibt erhalten.

## Dokumentation

- `docs/RESEARCH_1942.md`: Recherche mit Versionsabgrenzung und Quellen.
- `docs/DESIGN.md`: Regeln, Profile und Grafikablauf von 0.2.
- `docs/VALIDATION.md`: tatsächliche Prüfungen, Belege und offene menschliche Abnahme.
- `assets/manifest.json`: ursprüngliche Generierungen.
- `assets/revision02.json`: neue Bilder, Aufgaben, Prompts und Budget.
- `THIRD_PARTY_NOTICES.md`: Engine- und Asset-Hinweise.

[GitHub-Repository](https://github.com/michaelingokahler-mordor/Carrier-Ace), Hauptbranch `main`. Engine, Builds, Importcache und private Rohentwürfe bleiben außerhalb des Repositorys.
