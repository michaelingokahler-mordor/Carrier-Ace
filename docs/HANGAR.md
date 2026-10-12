# Carrier Ace 0.8.0 – Hangar und Maschinenzustand

Stand: 12.10.2026. Oberfläche Englisch. Die vier weiteren Modelle sind gesperrte Vorschauen; Spezialmunition folgt später. Vier Missionen sind verfügbar und werden nacheinander durch erfolgreiche Landungen freigeschaltet.

## Ablauf

Start Mission öffnet den Hangar. Die F4F Wildcat ist von Anfang an kostenlos verfügbar. Eine erfolgreiche Landung sichert Flugpunkte genau einmal und schaltet die F6F Hellcat frei. Der Ergebnisbildschirm behält die Highscore-Eingabe; Continue to Hangar führt zur Vorbereitung des nächsten Flugs.

Der Hangar zeigt sechs Karten, die gewählte Maschine, ihren Zustand, installierte Werte und reservierte Flugboni. Repair repariert, Paint kauft oder wählt Lackierungen, Upgrade bietet Flugvorbereitungen und installierte Ausbauten. Gesperrte Karten erklären Rolle, Ausbaugrenzen und spätere Spezialmunition im Tooltip.

## Profile und Obergrenzen

| Modell | Rolle | Armor | Speed | Bullets | Penetration | Spätere Zuladung |
|---|---|---:|---:|---:|---:|---|
| F4F Wildcat | Anfängerjäger | 2→3 | 1→2,50 | 5→9 | 0→1 | — |
| F6F Hellcat | Standardjäger | 3→5 | 3→4 | 6→12 | 0→1 | — |
| F4U Corsair | Schneller Jäger/Jagdbomber | 3→4 | 4→5 | 8→14 | 1→2 | 2 Raketen, 1 Bombe |
| SBD Dauntless | Präzisions-Sturzkampfbomber | 3→4 | 1→2,50 | 4→8 | 0→1 | 3 Bomben |
| TBF Avenger | Torpedobomber | 4→5 | 1→2,50 | 4→8 | 0→1 | 2 Torpedos |
| SB2C Helldiver | Schwerer Sturzkampfbomber | 4→5 | 2→3,50 | 4→10 | 1→2 | 5 Bomben |

Links stehen Grundwerte, rechts installierte Maxima. Flugboni dürfen darüber hinausgehen: Speed höchstens 5, Bullets höchstens 18, Penetration höchstens 3. Ganze +2-Käufe dürfen die Kugelgrenze nicht überschreiten; bei ungerader Grundkapazität kann daher 17 das erreichbare Maximum sein. MG-Schaden bleibt 1. Vor jedem Flug werden Rollen kostenlos auf drei aufgefüllt; kein Rollenangebot im Shop.

Die Wildcat besitzt ein eigenes SVG und fünf konvexe Trefferflächen für Rumpf, Flügel und Leitwerk. Die geringere Silhouette und das niedrigere Tempo unterscheiden sie von der Hellcat. Die übrigen vier Flugzeuge besitzen noch keine spielbaren Sprites oder Spezialwaffen.

## Speed

Rating 1/2/3/4/5 entspricht 130/162,5/195/227,5/260 logischen Pixeln pro Sekunde. Das sind keine km/h. Zwischenwerte werden linear berechnet: `130 + (Rating − 1) × 32,5`.

Grundwert, installierte Speed-Stufen und Flugboni werden als ganze Viertelschritte kombiniert. Ein Speed-Kauf oder Drop erhöht um 0,25. Die Reihe lautet 2,00→2,25→2,50→2,75→3,00. Die Hellcat beginnt nun auf 3 und behält 195 Pixel/s. Alte Gegnerstufen 1/2/3 werden auf 1/3/5 übertragen; ihre tatsächlichen Geschwindigkeiten bleiben gleich.

## Preise und Lebensdauer

| Flugvorbereitung | Preis | Wirkung |
|---|---:|---|
| Repair +1 | 150 | Einen fehlenden Armor-Punkt reparieren |
| Repair all | Fehlende Armor × 150 | Vollständige Reparatur |
| Bullets | 150 | +2 Plätze |
| Speed | 200 | +0,25 Rating |
| 2-Guns | 250 | Doppelschuss |
| 3-Guns | 450 | Trippelschuss |
| Penetration | 350 | +1 zusätzliches Ziel |

Reparaturen verändern sofort den gespeicherten Rumpfzustand. Die übrigen Käufe werden für den nächsten Flug reserviert. Sie bleiben vor dem Start gespeichert, werden beim Start aus der Reservierung entfernt und gelten nur für diesen Flug. Landung, Game Over und Abbruch verbrauchen sie. Während des Flugs eingesammelte Boni werden ebenfalls nicht installiert.

| Installierter Ausbau | Preis |
|---|---:|
| Armor +1 | 4.000, danach 8.000 |
| Speed +0,25 | 1.500 + 500 je bisheriger Speed-Stufe |
| Bullets +2 | 2.500 + 1.000 je bisheriger Bullets-Stufe |
| Penetration +1 | 6.000 |

Eine Armor-Erweiterung erhöht nur das Maximum. Der zusätzliche Punkt muss repariert werden. Käufe ohne ausreichendes Guthaben oder oberhalb einer Grenze sind deaktiviert. Standardlackierung ist kostenlos; Weiß kostet 500, Rot 750, Tarnfarben 1.000. Bereits gekaufte Lackierungen können kostenlos wieder angewendet werden. Der Shader verändert die Farbe, nicht Kontur oder Werte.

Installierte Ausbauten und gekaufte Lackierungen bleiben maschinengebunden über Missionen und Spielstarts erhalten. Nur ein tatsächlicher Abschuss löscht sie ohne Erstattung. Das freigeschaltete Basismodell wird kostenlos und vollständig repariert ersetzt. Andere Maschinen, Freischaltungen, Highscores und gesicherte Punkte bleiben bestehen. Ein Abbruch erhält Ausbauten, Farben und verbliebene Armor; Flugboni und ungesicherte Punkte verfallen.

## Speicherung

`HangarState` trennt Grundprofile, Maschinen und reservierte Käufe. Für den Flug wird ein effektives Profil dupliziert; Basisressourcen werden nicht verändert. `main.gd` speichert Wallet, Highscores, Audio und Hangarzustand gemeinsam in `user://carrier_ace.cfg`.

Alte gültige Konfigurationen ohne Hangar-Sektion erhalten F4F und F6F, ausgewählt bleibt die Hellcat. Bonusbestand, Highscores, Tonwerte und unbekannte Schlüssel bleiben erhalten. Neue Konfigurationen beginnen mit F4F. Ein während des Flugs beendeter Prozess gilt beim nächsten Start als Abbruch. Ein gespeicherter Rumpf mit null Armor wird als Verlust behandelt und durch das kostenlose Basismodell ersetzt.

HUD-Flächen verwenden 55 % Deckkraft; Texte und Symbole bleiben deckend. Der HUD-Speedwert zeigt das effektive Rating mit zwei Nachkommastellen.
