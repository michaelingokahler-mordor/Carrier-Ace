# Carrier Ace: erster Prototyp

Version 0.1.0, 11.10.2026. Arbeitstitel, fiktive Flugzeuge und Schauplatz. Einzelspieler, Deutsch, ein Level. Bildschirm 960×540, 16:9 mit schwarzen Rändern bei anderen Seitenverhältnissen. Ziel 60 Bilder pro Sekunde. Startbildschirm: Starten, Steuerung, Ton & Musik und unter Windows Beenden.

## Flugzeug A-02 Albatros

| Wert | Verhalten |
|---|---|
| Panzerung | 100; Projektil 10, Kollision 25 Schaden |
| Leben | Drei einschließlich erstem Flugzeug |
| Durchschlagskraft | 2 Schaden und bis zu zwei unterschiedliche Ziele pro Geschoss |
| Geschwindigkeit | 260 logische Pixel/s; normalisierte diagonale Bewegung |
| Waffen | Einzel-, Doppel- und Trippelschuss; 0,145 s Salvenintervall |
| Rolle | Drei pro Versuch, jeweils 1 s Schutz; keine vierte Rolle |
| Trefferschutz | 0,6 s; weitere Treffer in dieser Zeit verursachen keinen Schaden |
| Speed-Upgrade | +15%, zwei Stufen bis 338 Pixel/s |

Keine Durchschlagskraft-Pickups im ersten Level. `AircraftProfile` kapselt den Flugzeugtyp. `EnemyProfile`, `WeaponProfile` und `WaveProfile` kapseln Gegner, Schussmuster und Wellen. Waffenschaden und Zahl durchschlagener Ziele folgen derzeit demselben Durchschlagskraftwert; zusätzliche Flugzeugtypen können andere Werte erhalten.

## Mission

Titel → automatischer Trägerstart (8 s) → Wellen (180 s) → Bomber → Rückkehr (14 s) → Anflug → automatisches Aufsetzen (2,8 s) → Ergebnis. Beim Testpiloten beträgt der erfolgreiche Durchlauf 235,42 s, also 3:55 Minuten. Ein langsamer Bosskampf bzw. ein wiederholter Anflug verlängert ihn.

| Welle | Muster | Versorgung |
|---|---|---|
| 1: Erster Kontakt | Gerade leichte Jäger | Doppelschuss |
| 2: Über den Inseln | Bogenflüge, Jäger und Abfangjäger | Reparatur |
| 3: Kreuzfeuer | Kreuzende Jäger und Abfangjäger | Speed |
| 4: Schwere Eskorte | Gerade Jäger und gepanzerte Angreifer | Zweite Chance auf Doppelschuss |
| 5: Sturmfront | Gemischte Bogenflüge, gezielte Schüsse | Trippelschuss |
| 6: Letzte Verteidigung | Dichteste Kreuzformation, schwere Gegner | Reparatur |

Jede Welle dauert 30 s. Formationen erscheinen zeitlich festgelegt: erster Angriff 0,6 s, Versorgungsformation 7 s, weitere Angriffe 15 und 23 s. Die Zahl regulärer Gegner steigt von drei bis fünf je Angriff. Kurven und Schüsse verwenden feste Regeln; keine zufällige Pickup-Zuweisung.

| Gegner | Panzerung | Basistempo | Punkte |
|---|---:|---:|---:|
| Leichter Jäger | 2 | 93 Pixel/s | 100 |
| Abfangjäger | 6 | 115 Pixel/s | 100 |
| Gepanzerter Angreifer | 12 | 72 Pixel/s | 300 |
| Behemoth | 300 | Seitliche Bewegung | 3.000 |

Der Bomber kündigt Schussfächer optisch an. Bei 200 und 100 verbleibender Panzerung wendet er außerhalb des sichtbaren Spielfelds und kehrt zurück. Diese zwei zwölfsekündigen Wendemanöver strukturieren den Kampf in drei Anflüge; dabei bleibt sein tatsächlicher, bewegter Trefferbereich maßgeblich. Landung: 1.000 Punkte. Ergebnis zeigt Punkte, Highscore, Abschüsse, Quote und Flugzeit.

## Versorgung und Neustart

Eine markierte Formation hat vier Mitglieder. Jede Auflösung wird anhand einer Gegner-ID höchstens einmal gezählt. Nur vier Abschüsse erzeugen genau einen Drop; jedes entkommene Flugzeug sperrt ihn. Drops driften nach unten, werden automatisch berührt und verfallen nach zwölf Sekunden. Reparatur +30 bis Maximum; Waffenstufen können durch Pickups nur steigen. Speed maximal 130%.

Ein tödlicher Treffer verbraucht ein Leben. Nach einer kurzen Verlustanzeige startet die gesamte Mission wieder auf dem Träger: Panzerung 100, Einzelwaffe, Grundtempo, drei Rollen, null Punkte und Missionszeit. Gegner, Geschosse, Formationen, Drops und Effekte werden gelöscht. Dritter Verlust führt zu Game Over. Eine bewusst neue Mission setzt drei Leben zurück.

## Landung, Unterbrechung und Audio

Nach dem Boss werden alle Kampfelemente entfernt. Der grün markierte Bereich ist 84×82 Pixel groß; 0,75 s kontinuierlicher Aufenthalt lösen die automatische Landung aus. Verlassen setzt nur den Haltefortschritt zurück. Ein Fehlanflug kostet kein Leben, Zeitlimit besteht keines.

Esc/Start, Fokusverlust oder Gamepad-Trennung pausieren. Fortsetzen verlangt eine bewusste Eingabe. Die Musik, der Motor und laufende Effekte pausieren ebenfalls. Menüs sind fokussierbare Godot-Controls. Lokaler Highscore und Toneinstellungen werden gespeichert; ein Speicherfehler verhindert den Flug nicht. Audio startet erst nach Eingabe, fehlende Sounddateien werden übersprungen.

Runway erzeugte die Grafikvorlagen, elf Soundeffekte einschließlich Motor sowie zwei Musikstücke. Verbrauch 138/200 Credits: Bilder 108, Effekte 18, Musik 12. 62 Credits bleiben ungenutzt. Die ersten Spieler-/Schwergegner-/Bossentwürfe wurden ersetzt; die Kosten dafür sind im Gesamtbetrag enthalten. Fertige Runtime-Assets liegen lokal in `assets/art` und `assets/audio`. Bewegte Propeller, Rollpose und Explosionseffekte zeichnet der Renderer.

## Spätere Erweiterungen

Weitere Flugzeugprofile, zusätzliche Missionen, eigenständige Werte für Projektilschaden und Piercing-Ziele, umfangreichere Flugbahnressourcen und weitere Pickup-Arten lassen sich ergänzen. Kampagne, dauerhaft gekaufte Upgrades, Cloud-Highscore, Mehrspieler und öffentliche Veröffentlichung gehören nicht zu diesem Prototyp.
