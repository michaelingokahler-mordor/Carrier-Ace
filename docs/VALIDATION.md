# Carrier Ace 0.5.0 – Prüfbericht

Stand: 12.10.2026. Godot 4.7.2 Standard, Compatibility, Windows x64 und Web ohne Threads. Frühere Abnahmen stehen in VALIDATION_0.3.md und VALIDATION_0.4.md.

## Regeln und Integration

Die fünf Suiten umfassen 505 Prüfungen: Core 219, Mission04 95, UI 105, Hangar 75 und Hangar-UI 11. Sie prüfen die bisherigen Konturen, Geschosse, Loot, Gruppen, Counterattacks, Boss und Audio sowie die neue Maschinenverwaltung.

Zusätzliche Prüfungen: Viertelschritte bis Rating 5; installierte individuelle Grenzen; temporäre globale Grenzen; ausreichendes Guthaben; Preissteigerungen; leere Armor-Erweiterungen und Reparatur pro fehlendem Punkt; keine Waffenherabstufung; reservierte Käufe nach Speichern/Laden; Verbrauch beim Start; Rollenauffüllung; Verlust von Ausbauten und Farben; Erhalt anderer Maschinen und Freischaltungen; kostenloser Ersatz; Abbruch mit gespeichertem Restzustand; Quit während einer tödlichen Explosion; Migration auf F4F und F6F; einmalige Landegutschrift; Ergebnis und Rückkehr zum Hangar.

Die Wildcat wird zusätzlich auf Treffer in Rumpf, beiden Flügeln und Leitwerk sowie freie Zwischenräume getestet. Lackierung verändert die Geometrie nicht. Ganze +2-Käufe enden bei ungerader Grundkapazität bei 17 statt 18; die globale Grenze wird nicht überschritten.

## Vollständige Flüge

Der deterministische Pilot verwendet dieselben Bewegungs-, Waffen- und Kollisionsregeln wie Spieler. Loot-Seed 1943, keine Gesundheitskorrekturen oder Sonderrechte. Alle Prüfflüge sind stumm.

| Quellprojekt, normale Simulationsschritte | Ergebnis | Flugzeit | Armor | Score | Gesicherte Flugpunkte |
|---|---|---:|---:|---:|---:|
| F4F Wildcat | Landung | 299,13 s | 2/2 | 19.900 | 1.375 |
| F6F Hellcat | Landung | 289,05 s | 2/3 | 20.000 | 1.800 |

Beide Flüge enthalten sechs Wellen, zwei abgeschlossene Counterattacks, alle neun Gegnerprofile, Boss und Landung. Die erste Mission war mit den neuen F4F-Grundwerten ohne zusätzliche Gegnerabschwächung durchspielbar. Das Bossverhalten bleibt unverändert.

Exportbelege und Leistungsmessung werden in `verification05-*.json` festgehalten. Beschleunigte Exporte verarbeiten zwölf normale Physikschritte pro dargestelltem Frame. Ihre FPS sind kein Beleg für durchgehend 60 FPS im normalen Spieltempo.

Der Windows-Export bestand außerdem den F4F-Flug in normalem Tempo mit 299,13 s Missionszeit, Armor 2/2 und 1.375 gesicherten Punkten. Nach den ersten zwei Messwerten lagen die einsekündigen FPS-Stichproben im Mittel bei 59,89, mindestens 27 und höchstens 62. Eine durchgehend stabile Mindestleistung von 60 FPS ist damit nicht bestätigt. Nach dieser Messung wurde die Darstellungsreihenfolge korrigiert, damit Flugzeug, Schäden und Diagnosekontur oberhalb des Trägerdecks liegen; die Kampfregeln blieben gleich. Die finalen Exporte werden erneut vollständig beschleunigt geprüft.

## Visuelle und Menüprüfung

Native Aufnahmen bei 1280×720 und 1920×1080: Repair, Paint und Upgrade, Wildcat-Kontur, weiße/rote/Tarnlackierung, HUD mit 55 % Deckkraft. Die anfänglich überlappende Shop-Beschriftung wurde korrigiert; Karten erhalten kleine Bilder für F4F/F6F. Quellaufnahmen liegen lokal in `output/preview05/`.

Web-Prüfung über den mitgelieferten HTTP-Server: vollständige Landung, Ergebnis mit Highscore-Eingabe, Continue to Hangar, Rest-Armor, freigeschaltete Hellcat, Reparatur −150 Punkte, deaktivierte Reparatur bei voller Armor. Der Web-Endbericht bestätigt Master-Mute, keine laufende Musik, keinen laufenden Motor und null aktive Effektstimmen.

Die finalen Windows- und Webexporte bestehen den F4F-Prüfflug mit identischem Ergebnis: 299,13 s, Armor 2/2, Score 19.900, 1.375 Bonus-Points und zwei abgeschlossene Counterattacks. Im finalen Web-Hangar wurde zusätzlich ein Speed-Flugbonus gekauft: −200 Punkte, Reservierung +0,25, unveränderter installierter Grundwert 1,00. Die vier gesperrten Vorschauen bleiben gesperrt; Hellcat ist nach der Landung auswählbar.

Bestehende automatisierte UI-Prüfungen decken einzelne Feuerimpulse, Menüeingaben, Pause, Fokusverlust, Gamepad-Trennung, Options, Highscores und Audio-Endschutz weiterhin ab. Speicherung wird mit gesicherter Originalkonfiguration geprüft und anschließend zurückgesetzt; Prüfkäufe verändern keine echten Spielstände.

## Grenzen der Abnahme

Eine physische Gamepad-Prüfung und längere menschliche Spielgefühlabnahme wurden nicht durchgeführt. Die vier Spezialflugzeuge bleiben Vorschauen; Raketen, Bomben, Torpedos und passende Missionen sind noch nicht spielbar. Die neue F4F ist eine lokale Vektorillustration, keine neue Runway-Generierung. Keine zusätzlichen Credits verbraucht.

Windows-, Web- und Quell-ZIP liegen außerhalb von Git unter `builds/`; SHA256SUMS.json enthält ihre Prüfsummen. Engine, Importcache und Builds bleiben ausgeschlossen.
