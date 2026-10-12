# Carrier Ace 0.6.0 – Missionsbriefings und zweite Mission

Vor jedem spielergesteuerten Start führt der Hangar über **Mission Briefing** zur Einsatzbesprechung. **Begin Sortie** startet den Flug; **Back to Hangar** und Esc kehren zur Vorbereitung zurück. Das Briefing zeigt Auftrag, ausgewähltes Flugzeug, Feindlage, Rückkehrziel und Belohnung. Es verbraucht keine reservierten Käufe und startet weder Missionszeit noch Kampfsounds.

## Mission 1: Coastal Reconnaissance

Bewaffnete Küstenaufklärung entlang der Inselroute. Der Pilot beginnt mit der F4F Wildcat, bekämpft zuerst leichte Patrouillen, später Jäger und Bomber. Nach sechs Wellen, zwei Counterattacks und dem schweren Bomber kehrt er zum Flugzeugträger zurück. Die erste erfolgreiche Landung sichert Bonus-Points, schaltet Mission 2 frei und übergibt kostenlos eine F6F Hellcat. Die neue Hellcat wird für den nächsten Einsatz ausgewählt; Ausbauten der Wildcat werden nicht übertragen oder gelöscht.

## Mission 2: Fleet Air Patrol

Die frisch übergebene F6F schützt die Anflugwege des Trägers. Das Briefing erklärt die Übergabe. Freigeschaltete Flugzeuge bleiben im Hangar wählbar.

| Welle | Flugmuster | Gegner | Gruppengröße |
|---|---|---|---:|
| Outer Patrol | Bogen | Fighter 1, Biplane 2, Fighter 2 | 4 |
| Fighter Screen | Zickzack | Fighter 1/2, Biplane Ace | 4 |
| Ace Interception | Kreuzend | Fighter Ace, Fighter 1, Bomber 1 | 4 |
| Bomber Escort | Schleife | Bomber 1/2, Fighter Ace | 5 |
| Strike Group | Zickzack | Bomber Ace, Fighter 2, Bomber 2 | 5 |
| Carrier Defense | Kreuzend | Bomber Ace, Fighter Ace, Bomber 2, Biplane Ace | 5 |

Jede Welle dauert weiterhin 30 Sekunden. Versorgungsformationen, Loot, Schadenswerte, Counterattacks nach Welle 3 und 6 sowie Boss mit 300 Armor bleiben erhalten. Das bisherige Bossverhalten wird nicht verändert. Auch Mission 2 endet mit Anflug, Landung, Ergebnis und Hangar. Nach Abschluss existiert noch keine Mission 3; beide freigeschalteten Missionen sind wiederholbar.

## Daten und Speicherung

`MissionCatalog` enthält Briefings und Missionsvarianten. Die Wellendaten werden pro Auswahl dupliziert; Mission 2 verändert keine ursprünglichen Ressourcen der ersten Mission. `MissionModel.select_mission()` lädt die passende Folge vor dem Start.

`HangarState` speichert ausgewählte Mission und höchsten Abschluss zusätzlich zum Maschinenzustand. Ein Abschuss setzt den Missionsfortschritt nicht zurück. Alte Spielstände mit freigeschalteter Hellcat erhalten Zugang zu Mission 2. Neue Spielstände beginnen ausschließlich mit Mission 1. Reparaturen, Ausbauten, reservierte Käufe und Verlustregeln aus 0.5 bleiben erhalten.

Gezielte Exportprüfung der bereits freigeschalteten Mission 2: Windows `-- --verify-mission2`, Browser `?verify=1&mission=2`. Ohne Freischaltung bleibt Mission 1 ausgewählt. Diese Parameter erteilen keine zusätzlichen Kampfwerte und speichern keine Prüfflugresultate.
