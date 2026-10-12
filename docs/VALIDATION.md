# Carrier Ace 0.8.0 – Prüfbericht

Stand: 12.10.2026. Godot 4.7.2 Standard, Compatibility, Windows x64 und Web ohne Threads. Der Bericht zu 0.7 bleibt unter VALIDATION_0.7.md erhalten.

## Automatisierte Regeln

Neun Suiten mit insgesamt 651 Prüfungen bestehen. Aufteilung: Core 219, Mission04 95, UI 105, Hangar 75, Hangar-UI 11, Briefing 14, Landing 59, Surface 55 und Surface-UI 18. Der ältere Name Mission04 bezeichnet die Counterattack-Suite aus Version 0.4, nicht das vierte Kampagnenlevel.

Surface prüft Schiffsprofile, eigene Tempi, Pflichtziele, Score ohne Loot, vollständiges Herausscrollen, Küstenabstand und freien Überflug. Weitere Prüfungen betreffen Radarerfassung, Zurücksetzen, Alarmwarnung, bereits angeforderte Verstärkung und ihre Warteschlange. MG-Warnzeit, sechs Geschosse pro Feuerstoß und feste Schussrichtung bestehen. Gemeinsame Kontaktzeiten ordnen Treffer gegen Luft- und Oberflächenziele. Pause, Neustart und Inselbindung bestehen.

Surface-UI prüft Missionsfreischaltung, Missionsfehlschlag, Rest-Armor, Ausbau, Lackierung, verlorene Flugvorbereitung und gesicherte Punkte. Die Speicherung erhält diese Daten und den getrennten Highscore-Ausgang FAILED. Der Fehlschlag stoppt Musik und Motor und schaltet den Master-Bus stumm. Bestehende Tests prüfen weiterhin Eingaben, Gamepad-Ereignisse, Fokusverlust und Audiofreigabe. Die Prüfung verwendet getrennte lokale Testspeicher. Sie verändert keinen tatsächlichen Spielstand.

## Vollständige Flüge

Modellflüge aller vier Missionen bestehen bis zur Fangleine. Mission 1/2 behalten ihren Boss. Mission 3/4 wechseln nach erfüllten Pflichtzielen und abgeschlossenen Luftgruppen zum Anflug. Der zusätzliche Modellflug löst beide Radaralarme durch normale Steuerung aus und landet erfolgreich.

| Export | Mission | Flugzeit | Armor | Score | Ergebnis |
|---|---:|---:|---:|---:|---|
| Windows, normale Geschwindigkeit | 3 | 230,75 s | 2/3 | 15.200 | Drei Schiffe, zwei Counterattacks, Fangleine |
| Windows, normale Geschwindigkeit | 4 | 245,30 s | 1/3 | 15.300 | Beide Radare, zwei Alarme, Fangleine |
| Windows, zwölfmal beschleunigt | 4 | 245,30 s | 1/3 | 15.300 | Beide Radare, zwei Alarme, Fangleine |
| Web, zwölfmal beschleunigt | 1 | 304,30 s | 2/2 | 19.900 | F4F, Boss, Fangleine |
| Web, zwölfmal beschleunigt | 2 | 286,37 s | 2/3 | 24.300 | F6F, Boss, Fangleine |
| Web, zwölfmal beschleunigt | 3 | 230,35 s | 3/3 | 15.300 | Drei Schiffe, Fangleine |
| Web, zwölfmal beschleunigt | 4 | 228,30 s | 3/3 | 16.600 | Beide Radare, zwei Alarme, Fangleine |

Der Webtest spielte die Kampagne vom neuen F4F-Spielstand über die regulären Freischaltungen durch. Eine Reparatur vor Mission 3 kostete 150 Bonus-Points. Keine versteckte Freischaltung oder veränderte Kampfregel war erforderlich. Loot und Wetter laufen nach dem ersten Flug mit ihrer Zufallsfolge weiter. Deshalb unterscheiden sich spätere Kampagnenflüge von einzeln gestarteten Modell- und Windowsprüfungen.

Die Endberichte stehen in verification08-*.json. Alle bestätigen gestoppte Musik, Motor und Effektstimmen sowie einen stummen Master-Bus. Der Pilot verwendet normale Eingaben und 60-Hz-Physikschritte. Er erhält keine Unverwundbarkeit, kostenlosen Käufe oder erzwungenen Treffer.

## Grafik, Leistung und Grenzen

Schiffe, Radar, Alarm, große Berginsel, MG-Nest, Brandung und HUD wurden bei 1280×720 und 1920×1080 visuell geprüft. Zusätzliche Aufnahmen zeigen den Missionsfehlschlag und die Trägerergebnisse. Lokale Belege liegen in output/preview08/ und output/windows08/. Verkleinerte Übersichten stehen unter docs/images/. Der magentafarbene Freistellungsrand der großen Insel wurde lokal korrigiert. Die finalen Trefferflächen blieben dabei unverändert.

Der Windows-Flug in normaler Geschwindigkeit bei 1920×1080 erreichte nach zwei Startproben einen Median von 60 FPS. Das Minimum der sekündlichen Proben betrug 47 FPS. Während Teilen dieses Flugs liefen zusätzliche beschleunigte Tests. Beschleunigte Exportflüge sind keine Messung stabiler Mindest-FPS. Ein weiterer normaler Windows-Flug durch Mission 4 bestätigt beide Alarme und die Landung. Sein Median beträgt ebenfalls 60 FPS, das Minimum 27 FPS. Diese Prüfflüge enthalten den Prüfpiloten und PNG-Aufnahmen während der Mission. Eine durchgehend stabile Mindestbildrate wurde damit nicht nachgewiesen. Die Zielrate beträgt weiterhin 60 FPS.

Physischer Gamepad-Test und menschliche Abstimmung der Schwierigkeit bleiben offen. Die automatisierten Flüge ersetzen diese Spielgefühlprüfung nicht.

## Assets und Lieferung

Zwölf Runway-Entwürfe kosteten 156 der verfügbaren 160 Credits. Sechs Entwürfe wurden übernommen. Die Küsteninsel verwendet eine lokal angepasste vorhandene Vorlage. Es erfolgte kein zusätzlicher Kauf. Originale PNGs wurden übernommen, keine verkleinerten Vorschaukopien. Lokale Aufbereitung erzeugt Freistellung, Schäden, Wracks, Brandung und Konturen. Aufgaben und Prompts stehen in assets/revision08.json.

Die Lieferung enthält CarrierAce-0.8.0-Windows-x64.zip, CarrierAce-0.8.0-Web.zip und CarrierAce-0.8.0-Source.zip. Die Pakete liegen außerhalb von Git unter builds/. SHA256SUMS.json enthält ihre Prüfsummen. Engine, Rohentwürfe und Importcache bleiben außerhalb des Repositorys. Importkonfigurationen und fertige Runtime-Assets gehören zum Quellprojekt.
