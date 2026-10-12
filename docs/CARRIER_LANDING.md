# Carrier Ace 0.7.0 – Trägerlandung als Minispiel

Nach dem Boss folgt der bisherige 14-sekündige Rückflug. Währenddessen führt das Spiel die Maschine zum Ausgangspunkt des manuellen Endanflugs. Danach bewegt sich das Flugzeug automatisch langsam vorwärts; der Spieler muss selbst auf dem Träger einfädeln.

Links/Rechts steuert gegen Seitenwind und Böen. Auf erhöht das Anflugtempo, Ab verringert es. Tastatur und Stick verwenden dieselben Regeln. MG und Rollen sind während des Anflugs deaktiviert. Der sich verjüngende türkisfarbene Korridor führt zur goldenen Fangleine. Die Anzeige nennt Wetter, Windrichtung, Windstärke und zulässiges Tempo.

## Wetter und Bewegung

Pro Rückkehr wird eines von vier Wetterbildern zufällig gewählt: Clear, Breezy, Rain oder Squalls. Der Grundwind beträgt je nach Wetter 10, 22, 28 oder 36 logische Pixel/s und weht zufällig nach links oder rechts. Überlagerte Böen verändern die Drift fortlaufend. Regen und Böen erschweren die Sicht; stärkeres Wetter bewegt das Trägerdeck leicht seitlich und vertikal. Das sind Arcade-Einflüsse, keine Flugsimulation oder historischen Geschwindigkeitswerte.

Die Seitensteuerung reagiert mit einer kurzen Verzögerung. Ohne Eingabe beträgt das Anflugtempo 34 Pixel/s; Eingaben verändern es zwischen 14 und 54. Im Gegensatz zum Luftkampf hängt das Landetempo nicht vom Speed-Ausbau ab. Damit bleibt jede freigeschaltete Maschine landbar. Pause und Fokusverlust halten auch Wind, Regen und Deckbewegung an.

## Fanghaken und Bedingungen

Der sichtbare Heckhaken liegt bei 28 % der Spritehöhe hinter der Flugzeugmitte und folgt der dargestellten Ausrichtung. Der Kontakt wird entlang der Bewegung von Haken und Fangleine geprüft. Bloßes Verweilen in einem Bereich genügt nicht mehr.

Die Fangleine greift nur bei einem Überqueren mit allen folgenden Bedingungen:

- Seitlicher Hakenfehler höchstens 22 logische Pixel.
- Seitendrift relativ zum Träger höchstens 24 Pixel/s.
- Ausrichtung höchstens 0,22 Radiant, ungefähr 12,6 Grad.
- Vorwärtstempo 20 bis 44 Pixel/s.

Nach erfolgreichem Einfädeln zeigt das Spiel WIRE CAUGHT. Die Leine spannt sich sichtbar vom Deck zum Heckhaken; die Maschine wird über 1,4 Sekunden abgebremst. Nach insgesamt 2,8 Sekunden folgen wie bisher Score, einmalige Bonusgutschrift, Ergebnis und Hangar.

Bei einem misslungenen Kontakt erscheint WAVE OFF. Ein kurzer automatischer Durchstartbogen führt zum neuen Anflug. Armor, installierte Ausbauten und Flugpunkte bleiben erhalten. Die Zahl der Versuche ist unbegrenzt; das Wetterbild bleibt erhalten, Böen laufen weiter. Dieser faire Wiederholungsmodus ersetzt die bisher ebenfalls schadensfreie Wiederholung. Absturz- oder Verletzungsregeln sind nicht hinzugefügt worden.

`CarrierLanding` hält ausschließlich Wetter und Anflugzustand. `MissionModel` steuert die Phasen; `WorldView` zeigt Korridor, Fangleine und Wetter. Der Prüfpilot benutzt dieselben Steuergrößen und gleicht die angezeigte Winddrift aus, ohne Positionskorrekturen, zusätzliche Armor oder direkte Fangfreigabe. Prüfläufe verwenden separaten Wetter-Seed 1944; echte Flüge randomisieren unabhängig vom Loot.
