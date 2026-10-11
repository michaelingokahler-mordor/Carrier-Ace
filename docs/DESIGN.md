# Carrier Ace 0.2.0 – Operation Blue Horizon

Stand: 11.10.2026. Einzelspieler, ein Level, englische Oberfläche. Schauplatz und Einsatz sind fiktiv; reale Flugzeugnamen dienen der gestalterischen Orientierung. Armor, Speed Rating, Waffen und Raketen sind Arcade-Regeln.

## Hellcat und Kampf

| Wert | Grundwert / Verhalten |
|---|---|
| Flugzeug | Grumman F6F Hellcat; ein zentraler Frontpropeller |
| Armor | 3; HUD zeigt aktuelle / maximale Panzerung |
| Leben | Drei einschließlich des ersten Flugzeugs |
| Projektilschaden | 1 |
| Penetration | 0; zählt zusätzliche unterschiedliche Ziele, zulässig 0–3 |
| Speed Rating | 2; 195 logische Pixel/s |
| Waffe | Single Shot; 0,145 s Salvenintervall |
| Rolle | Drei je Versuch; jeweils 1 s Schutz |
| Trefferschutz | 0,6 s nach Schaden |

Rating 1 = 130, Rating 2 = 195, Rating 3 = 260 Pixel/s. Die Grundstufe bleibt unverändert. Jeder Bonus addiert 10% des Grundtempos; Maximum 260. Hellcat: 195 → 214,5 → 234 → 253,5 → 260. Weitere Pickups verändern die gedeckelte Geschwindigkeit nicht. `add_speed_upgrade()` ist von der Pickup-Quelle unabhängig und kann später auch von einem Shop verwendet werden.

Ein Geschoss trifft bei Penetration 0 genau ein Ziel, bei 3 höchstens vier unterschiedliche Ziele. Eine ID-Liste verhindert Mehrfachschaden am selben Gegner; segmentbasierte Treffer verhindern das Überspringen schneller Ziele. Projektilschaden und Penetration sind getrennte Profilwerte.

Normale gegnerische Geschosse und Flugzeugkontakte kosten einen Armor-Punkt. Ki-21-Raketen kosten zwei, kündigen ihren Abschuss 0,6 s an und behalten danach die festgelegte Richtung. Reparaturen geben einen Punkt bis zum Profilmaximum.

## Flugzeugkatalog

| Profil | Vorbild | Armor | Rating | Waffe | Punkte |
|---|---|---:|---:|---|---:|
| Biplane 1 | Kawasaki Ki-10 | 1 | 1 | Single Shot | 100 |
| Biplane 2 | Kawasaki Ki-10 | 1 | 1 | Single Shot | 100 |
| Biplane Ace | Kawasaki Ki-10 | 2 | 1 | Double Shot | 300 |
| Fighter 1 | Nakajima Ki-43 | 1 | 2 | Single Shot | 100 |
| Fighter 2 | Nakajima Ki-43 | 1 | 2 | Single Shot | 100 |
| Fighter Ace | Nakajima Ki-44 | 2 | 2 | Double Shot | 300 |
| Bomber 1 | Mitsubishi Ki-30 | 2 | 1 | Single Shot | 300 |
| Bomber 2 | Mitsubishi Ki-30 | 2 | 1 | Single Shot | 300 |
| Bomber Ace | Mitsubishi Ki-21 | 3 | 1 | Rockets | 300 |
| B-99 Behemoth | Eigenes Bossmodell | 300 | 1 | Fan Fire | 3.000 |

Varianten 1 und 2 haben verschiedene Lackierungen und Flugmuster. Aces tragen deutliche Farbmarkierungen. Biplane 2 und Bomber 2 fliegen Bögen; Fighter 2 und Biplane Ace kreuzen, Fighter Ace fliegt Bögen. Andere reguläre Profile folgen dem Wellenmuster. Ki-21 und B-99 besitzen zwei Motoren; die Propelleranimation verwendet individuelle Montagepunkte.

`AircraftCatalog` lädt zehn Gegner-/Bossressourcen. Mit der Hellcat ergibt das elf Einträge in **Aircraft**. Titel- und Pausenmenü öffnen dieselbe reine Übersicht: Modell, Rolle, Bild, Armor, Rating, Penetration, Schaden und Waffe. Aktive Spielerboni stehen im HUD. Das Öffnen aus der Pause setzt die Mission nicht fort.

## Mission

Titel → Trägerstart (8 s) → sechs Wellen (180 s) → B-99 → Rückkehr (14 s) → Anflug → automatisches Aufsetzen (2,8 s) → Ergebnis. Der Testpilot benötigt 247,25 s. Ein langsamer Bosskampf oder wiederholter Anflug verlängert die Mission.

| Welle | Gegner / Flugmuster | Versorgung |
|---|---|---|
| First Contact | Biplane 1/2, gerade | Double Shot |
| Island Patrol | Biplane 1/2/Ace, Bögen | Repair |
| Crossfire | Fighter 1/2, Kreuzungen | Speed |
| Heavy Escort | Fighter 1/Ace, Bomber 1 | Double Shot |
| Storm Front | Bomber 1/2, Fighter Ace, Bögen | Triple Shot |
| Final Defense | Bomber Ace/2, Fighter Ace/2, Biplane Ace | Repair |

Angriffe bei 0,6, 15 und 23 s, Versorgungsformation bei 7 s. Reguläre Gruppen steigen von drei bis fünf Flugzeugen. Die Versorgung besteht immer aus vier eindeutig zugeordneten Mitgliedern. Vier Abschüsse erzeugen genau einen festgelegten Drop; ein entkommenes Mitglied verhindert ihn. Auch gleichzeitige und wiederholte Auflösungen erzeugen keine doppelten Drops.

Drops driften nach unten und verfallen nach zwölf Sekunden. Doppel-/Trippelschuss bleiben bis zum Flugzeugverlust; schwächere Pickups senken die Stufe nicht. Der Trippelschuss hat ein gerades mittleres und zwei leicht aufgefächerte Geschosse.

Der Boss wendet bei 200 und 100 Armor für jeweils zwölf Sekunden außerhalb des sichtbaren Bereichs und kehrt zurück. Sein Schussfächer wird angekündigt. Die reguläre Ki-21 ersetzt den Endboss nicht.

Ein Abschuss verbraucht ein Leben. Nach 2,3 s beginnt derselbe Versuch mit voller Grundpanzerung, Grundwaffe, Grundtempo, drei Rollen, null Punkten und derselben Route von vorn. Gegner, Geschosse, Formationen, Drops, Effekte und Missionsfortschritt werden zurückgesetzt. Der dritte Verlust führt zu Game Over.

Nach dem Boss werden Kampfelemente entfernt. Der 84×82-Pixel-Einflugbereich verlangt 0,75 s durchgehenden Aufenthalt. Verlassen setzt die Haltezeit zurück; wiederholter Anflug kostet kein Leben. Landung: 1.000 Punkte. Ergebnis: Punkte, Highscore, Abschüsse, Quote und Flugzeit.

## Meer, Route und Auflösung

Detaillierte Illustrationen ersetzen Pixelraster und Farbquantisierung. Titel 1920×1080; normale Flugzeuge 512×512, große Bomber 768×768, Inseln 1024×768, Träger 512×1200. Die logische Welt bleibt 960×540. Lineare Filterung und `canvas_items` erhalten scharfe Details bei 1280×720 und 1920×1080.

Der Wassershader kombiniert nahtloses deterministisches Rauschen, Blautöne, wandernde Wellen, feine Reflexe und dezente Schaumkronen. Drei Küstenmasken erzeugen flaches türkisfarbenes Wasser und unregelmäßige animierte Brandung. Eine weiche Heckwelle folgt dem Träger.

Alle Hintergrundanimationen verwenden die pausierbare Missionszeit. Die drei festen Inselmotive beginnen bei y = −160, −630 und −1040 und verschieben sich mit 5,4 Pixel/s nach unten. Bei 247,25 s ergibt das 1.335 Pixel bzw. 2,47 Bildschirmhöhen. Die Inseln liegen an wechselnden Seiten, damit die zentrale Kampffläche frei bleibt. Phasenwechsel verändern weder Route noch Position. Sichtbarkeits-Culling erfolgt erst außerhalb der vollständigen Sprite-Grenzen; es gibt keine Ein-/Ausblendungen.

## Unterbrechung und Audio

Esc/Start, Fokusverlust und Gamepad-Trennung pausieren. Fortsetzen verlangt eine bewusste Eingabe. Audio, Wasser, Brandung, Inselbewegung und Kampf bleiben angehalten. Highscore und Toneinstellungen werden lokal gespeichert. Audio wird durch die erste Eingabe freigeschaltet; fehlende Audiodateien werden übersprungen.

Die elf Soundeffekte und zwei instrumentalen Musikstücke aus 0.1 werden weiterverwendet. Die neue Grafik kostet 340 von höchstens 500 zusätzlichen Credits: fünfzehn 2K-Bilder zu 20 und ein 4K-Titelbild zu 40. Anfangs wurden 100 Credits für Korrekturen reserviert; insgesamt bleiben 160 ungenutzt. Aufgaben und Kosten stehen in `assets/revision02.json`; der ursprüngliche Verbrauch von 138 Credits steht separat in `assets/manifest.json`.

## Erweiterungspunkte

Weitere Flugzeugprofile können andere Armor-, Schadens-, Penetration- und Geschwindigkeitswerte erhalten. Ein Shop kann dieselbe Bonusberechnung nutzen. Kampagne, dauerhaft gekaufte Upgrades, zusätzliche Level, Cloud-Highscore und Mehrspieler gehören nicht zu 0.2.
