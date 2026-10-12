# Carrier Ace 0.6.0 – Prüfbericht

Stand: 12.10.2026. Godot 4.7.2 Standard, Compatibility. Frühere Prüfungen bleiben in VALIDATION_0.5.md und den älteren Berichten erhalten.

Die sechs automatisierten Suiten umfassen 519 Prüfungen: Core 219, Mission04 95, UI 105, Hangar 75, Hangar-UI 11 und Briefing 14. Alle bestehen. Neue Prüfungen decken das Briefing vor dem Start, Rückkehr ohne Verbrauch reservierter Käufe, Aktivierung beim Start, Mission-1-Verlust ohne Fortschritt, Hellcat-Übergabe, Freischaltung und Speicherung von Mission 2, angepasste Wellen, kostenlosen Ersatz nach Verlust und Ende der derzeitigen Kampagne nach Mission 2 ab. Die ursprünglichen Ressourcen der ersten Mission bleiben unverändert.

Der normale Regeltestpilot schafft Mission 2 mit der unveränderten F6F-Basisausführung: 275,20 Sekunden Missionszeit, Armor 2/3, Score 24.800, 1.875 Bonus-Points. Sechs Wellen, beide Counterattacks, schwerer Bomber und Trägerlandung sind vollständig enthalten. Keine Gesundheitskorrekturen oder Sonderrechte; Loot-Seed 1943.

Native Briefing-Aufnahmen bei 1280×720 und 1920×1080 wurden auf Lesbarkeit und Überlappungen kontrolliert. Beide Briefings und die Missionsauswahl liegen lokal in output/preview06/. Das Briefing bleibt Englisch. Der Hangar erklärt die vorhandenen Maschinen- und Verlustregeln weiterhin.

Die Exportprüfungen werden in verification06-*.json festgehalten. Für Windows wurde ein separater lokaler Test-Spielstand mit bestehender Hellcat-Freischaltung verwendet; echte Spielstände bleiben unberührt. Der beschleunigte Prüfpilot verarbeitet zwölf normale Physikschritte pro Bild. FPS aus diesen Läufen sind kein Nachweis für durchgehend 60 FPS im menschlichen Spieltempo. Der normale Windows-Leistungsbeleg aus 0.5 bleibt als ältere Messung dokumentiert.

Physische Gamepad-Prüfung und menschliche Spielgefühlabnahme bleiben offen. Keine neuen Grafiken, Audiodateien oder Runway-Credits benötigt. Die Inselroute und der bisherige Boss bleiben erhalten; Mission 2 unterscheidet sich durch Gegnerzusammenstellung, Formationsmuster und Gruppengrößen.

Windows-, Web- und Quell-ZIP für 0.6.0 liegen außerhalb von Git unter builds/. SHA256SUMS.json enthält die Prüfsummen.

Die Windows- und Webexporte bestehen Mission 2 mit identischem Ergebnis: 275,20 s, Armor 2/3, Score 24.800, 1.875 gesicherte Punkte und beide abgeschlossenen Counterattacks. Beide Endberichte bestätigen gestoppte Musik, Motor und Effektstimmen sowie Master-Mute. Im Browser wurde anschließend der Hangar geöffnet und das zweite Briefing über Mission Briefing aufgerufen. Mission 1 besteht den F4F-Regelprüfflug weiterhin mit 299,13 s und Score 19.900.
