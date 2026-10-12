# Carrier Ace 0.7.0 – Prüfbericht

Stand: 12.10.2026. Godot 4.7.2, Compatibility, Windows x64 und Web ohne Threads. Frühere Berichte bleiben unter VALIDATION_0.6.md und älteren Versionen erhalten.

Sieben Suiten mit insgesamt 578 Prüfungen bestehen: Core 219, Mission04 95, UI 105, Hangar 75, Hangar-UI 11, Briefing 14 und Landing 59. Die neue Landung wird auf korrekten Heckhakenkontakt, Fehlschuss außerhalb des Korridors, zu hohes/zu niedriges Tempo, Seitendrift, falsche Ausrichtung, automatisches Durchstarten, Wettervielfalt und Pause geprüft. Dreißig kontrollierte Wetter-Seeds wurden mit normaler Pilotensteuerung erfolgreich gelandet. Keine direkten Positionskorrekturen oder erzwungene Fangfreigaben durch den Prüfpiloten.

Der bisherige Haltebereich wurde entfernt. Der aktualisierte Core-Test prüft Kontakt und weiterhin einmalige Gutschrift. Hangar-, Missionsfortschritts-, Audio-Endschutz- und Briefingtests bleiben bestanden. Bei Durchstarten bleiben Armor und Flugpunkte erhalten.

Visuelle Prüfung in 1280×720 und 1920×1080: Korridor, goldene Fangleine, Heckhaken, Regen, Wettereinblendung und Flugzeug auf dem Deck. Aufnahmen liegen lokal in output/preview07/. Die Steuerungshinweise im Landeminispiel erklären Gegensteuern und Tempo; der normale Kampf bleibt unverändert.

Vollständige Exportflüge und Endzustände werden in verification07-*.json festgehalten. Der Pilot nutzt normale Physikschritte mit Loot-Seed 1943 und separatem Wetter-Seed 1944. Beschleunigte Flüge sind keine Messung menschlichen Spielgefühls oder stabiler Mindest-FPS. Physischer Gamepad-Test und menschliche Abstimmung der Landeschwierigkeit bleiben offen. Keine neuen Runway-Generierungen oder Credits erforderlich.

Pakete: CarrierAce-0.7.0-Windows-x64.zip, CarrierAce-0.7.0-Web.zip und CarrierAce-0.7.0-Source.zip außerhalb von Git unter builds/. SHA256SUMS.json enthält die Prüfsummen.

Mission 1 mit F4F besteht einschließlich Minispiel: 304,30 s, Armor 2/2, Score 19.900. Windows- und Webexporte bestehen Mission 2 mit identischem Ergebnis: 280,43 s, Armor 2/3, Score 24.800, 1.875 gesicherte Punkte, Wetter Clear, ein Anflug und bestätigter Fangleinenkontakt. Beide Endberichte bestätigen Master-Mute sowie gestoppte Musik, Motor und Effektstimmen. Alle vier Wetterbilder werden durch die zusätzlichen Landetests abgedeckt.
