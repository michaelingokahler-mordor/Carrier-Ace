# Carrier Ace 0.3.0 – Flugzeugkonturen, Bordkanone und Bonus-Points

Stand: 12.10.2026. Die Spieloberfläche ist Englisch, Entwicklungsdokumentation Deutsch. Godot 4.7.2 Standard, Compatibility-Renderer, logische Welt 960×540 und hochauflösende Canvas-Skalierung bleiben erhalten.

## Ein Flug, Armor und Rollen

Die Hellcat beginnt mit Armor 3/3, Speed Rating 2, Penetration 0, Single Shot, sechs Kugelplätzen und drei Rollen. Leben und automatische Wiederholungen entfallen. Normale Gegnergeschosse und Flugzeugkontakte kosten einen Armor-Punkt, angekündigte Ki-21-Raketen zwei. Bei Armor null explodiert das Flugzeug; nach 0,8 s erscheint Game Over.

Armor 2 zeigt Einschuss- und Brandflecken, Armor 1 weitere Flecken und eine dezente Rauchfahne. Reparaturen ändern die Darstellung zurück. Trefferschutz dauert 0,6 s; eine Rolle schützt eine Sekunde und kostet eine Ladung. Rolls-Pickups füllen +1 bis maximal drei auf.

Ein ausdrücklich neuer Flug setzt Armor, Rollen, Waffe, aktive Kugeln, Kugelkapazität, Speed, Penetration-Bonus, Gegner, Gruppen, Drops, Effekte, Zeit und Flugpunkte zurück. Der gespeicherte Bonusbestand sowie Highscore und Tonwerte bleiben erhalten.

## Trefferkonturen und Bewegungsprüfung

Elf Flugzeugprofile enthalten vorbereitete Vereinigungen konvexer Polygone. Die Konturen werden offline aus den fertigen PNGs ermittelt: feste Deckkraft ab 192/255, halbpixeliges logisches Raster, ungefähr zwei Pixel Einzug und Konturvereinfachung um höchstens einen halben Pixel. Sehr schmale Rumpfpartien erhalten einen Einzug von einem Pixel, damit der feste Rumpf nicht verschwindet. Godot zerlegt die Konturen in 14–31 konvexe Teilflächen je Profil.

Rumpf, beide Flügel, Leitwerk und feste Motorgondeln zählen. Zwischenräume, transparente Ränder, gezeichneter Schatten, Propellerunschärfe und Rauch bleiben frei. Die Polygone sind relativ zur Texturmitte normalisiert und werden mit derselben Spritegröße wie die Grafik skaliert. Kurvenflug und Rolle teilen ihre Breitenfunktion mit der Kollisionsansicht.

Die Hellcat bleibt mit ihrem vollständigen Sprite innerhalb der Spielfläche unterhalb des HUD; vergrößerte Flügelkonturen können dadurch keine verdeckten Randtreffer auslösen.

Geschossköpfe sind Scheiben mit Radius 2 (Spieler) bzw. 3 (Gegner). Die kontinuierliche Prüfung gegen Polygonkanten und abgerundete Ecken verwendet die relative Bewegung von Geschoss und Ziel. Raketen besitzen einen konvexen, 20 Pixel langen Körper einschließlich Nase; Abgas und Leuchtspur zählen nicht. Raketen- und Flugzeugkontakte verwenden kontinuierliche Separating-Axis-Tests für relative Translation. Das Breitenbild des Spielers wird je Physikschritt übernommen.

Begrenzungsrechtecke reduzieren Kandidaten. Gegnerformen werden beim Laden vorbereitet, die Spielerform nur bei einer Änderung der dargestellten Breite oder des Profils. Laufzeit-Pixelmasken und kreisförmige Flugzeug-Trefferentscheidungen entfallen.

Penetration wird nach tatsächlicher erster Konturberührung abgearbeitet, nicht nach Entfernung zur Gegner-Mitte. Je Geschoss wird jede Gegner-ID höchstens einmal beschädigt; überlappende Teilflächen sind kein Mehrfachtreffer.

Diagnose: Windows `-- --collisions`, Web `?collisions=1`. Grün zeigt die Hellcat, Rot Gegner, Gelb Geschosskörper und Bewegungsstrecken. Der Modus ist standardmäßig aus und verändert keine Regeln.

## Manuelle Bordkanone und Kugelplätze

Ein neuer Tastatur-/Gamepad-Druck erzeugt höchstens eine vollständige Salve. Halten und Tastatur-Echo schießen nicht. Der Mindestabstand beträgt weiterhin 0,145 s; während Abkühlzeit oder Platzmangel verworfene Eingaben werden nicht nachgeholt. Menüeingaben werden nicht als spätere Schüsse gespeichert.

Single Shot braucht einen, Double Shot zwei und Triple Shot drei freie Plätze. Die Hellcat startet mit sechs; Bullets erhöht um zwei bis maximal 18. Das HUD zeigt aktive Spielerkugeln / Kapazität. Gegnergeschosse zählen nicht mit. Ein Geschoss belegt genau einen Platz bis zum letzten zulässigen Treffer oder vollständigen Verlassen des Bildschirms mit seinem körperlichen Kopf bzw. Raketenkörper. Die bisherige unsichtbare 60-Pixel-Nachlaufzone entfällt; die Prüfung endet an dieser Grenze und berücksichtigt die entsprechende Teilbewegung des Ziels.

Schaden bleibt ein Punkt pro Spielerkugel. Penetration zählt zusätzliche unterschiedliche Ziele: 0 = eins, 3 = vier. Profilgrundwerte bleiben unverändert; aktive Kapazitäts- und Penetration-Boni gehören zum Flug. Bereits fliegende Kugeln behalten die beim Abschuss festgelegte Penetration.

Rating 1 = 130, Rating 2 = 195, Rating 3 = 260 Pixel/s. Jeder Speed-Pickup addiert 10 % Grundtempo bis 260. Hellcat: 195 → 214,5 → 234 → 253,5 → 260.

## Gegner und Mission

| Profil | Vorbild | Armor | Rating | Waffe | Score |
|---|---|---:|---:|---|---:|
| Biplane 1/2 | Kawasaki Ki-10 | 1 | 1 | Single Shot | 100 |
| Biplane Ace | Kawasaki Ki-10 | 2 | 1 | Double Shot | 300 |
| Fighter 1/2 | Nakajima Ki-43 | 1 | 2 | Single Shot | 100 |
| Fighter Ace | Nakajima Ki-44 | 2 | 2 | Double Shot | 300 |
| Bomber 1/2 | Mitsubishi Ki-30 | 2 | 1 | Single Shot | 300 |
| Bomber Ace | Mitsubishi Ki-21 | 3 | 1 | Rockets | 300 |
| B-99 Behemoth | Eigenes Bossmodell | 300 | 1 | Fan Fire | 3.000 |

Lackierungen, Flugmuster, Motorpositionen und Warnungen bleiben erhalten. Ki-21-Raketen kündigen den Abschuss 0,6 s an, behalten die vorher festgelegte Richtung und verfolgen ihr Ziel nicht.

Titel → Trägerstart (8 s) → sechs Wellen (180 s) → Boss → Rückkehr (14 s) → Anflug → automatisches Aufsetzen (2,8 s) → Ergebnis. Die Wellen führen Doppeldecker, Jäger und Bomber ein; die sechste kombiniert alle Familien. Der Boss wendet bei 200 und 100 Armor für jeweils zwölf Sekunden. Sein Profil bleibt separat von der regulären Ki-21.

Pro Welle reguläre Gruppen bei 0,6, 15 und 23 s; eine goldmarkierte Vierer-Versorgungsformation bei 7 s. Reguläre Gruppen enthalten drei bis fünf Mitglieder. Jede Gruppe hat eine eindeutige ID; Versorgung und Gruppenzugehörigkeit sind getrennt, damit normale Gruppen weiterhin feuern.

Die Landung verlangt 0,75 s kontinuierlich im 84×82-Pixel-Korridor und vergibt 1.000 Score-Punkte. Ein verfehlter Anflug kostet keine Armor. Der Testpilot nutzt normale Bewegung, einzelne Schussimpulse, Konturprognosen und dieselben Kampfregeln; keine Sonderrechte.

## Loot und Bonus-Points

Ein regulärer Abschuss außerhalb einer Versorgungsformation hat 3 % Dropchance, unabhängig von früheren Drops und ohne zusätzliche Garantie. Der Boss hat keinen Zufalls-Drop. Eine vollständig abgeschossene goldmarkierte Formation erzeugt genau einen garantierten Drop. Ein entkommenes Mitglied verhindert den Gruppenbonus und den garantierten Drop. Gleiche Gegner-IDs und doppelte Auflösungen werden ignoriert.

Beide Quellen verwenden die Loot-Ressource der Welle. Die Standardtabelle bleibt auch bei erreichten Grenzen unverändert:

| Upgrade | Gewicht | Wirkung |
|---|---:|---|
| Bullets | 25 % | +2 Plätze, maximal 18 |
| Speed | 15 % | +10 % Grundtempo, maximal 260 |
| 2-Guns | 15 % | Mindestens Double Shot |
| Rolls | 10 % | +1, maximal drei |
| 3-Guns | 10 % | Triple Shot |
| Armor | 20 % | +1 bis zum Profilmaximum |
| Penetration | 5 % | +1 zusätzliches Ziel, maximal drei |
| Rockets | 0 % | Späteres Feature |

Ein beim Einsammeln nutzloses Upgrade gibt 25 Bonus-Points; Waffen werden nicht herabgestuft. Drops driften mit 38 Pixel/s und verfallen nach zwölf Sekunden.

Jede vollständige reguläre Anfluggruppe verdient 25 Bonus-Points je Mitglied, einschließlich Versorgungsgruppen. Diese Punkte sind vom normalen Score getrennt. Erfolgreiche Landung überträgt ungesicherte Flugpunkte einmalig in den lokal gespeicherten Bonusbestand. Game Over, Abbruch oder ein neuer Flug verwerfen nur ungesicherte Punkte. Der Ergebnisbildschirm zeigt gutgeschriebene bzw. verlorene Punkte und den Bankbestand.

Alte Einstellungen erhalten Bonusbestand null; Highscore, Tonwerte und unbekannte Konfigurationsschlüssel bleiben erhalten. Ein Shop ist noch nicht vorhanden.

## Meer, Oberfläche und Erweiterungen

Die drei festen Inselmotive scrollen mit 5,4 Pixel/s und denselben Anfangspositionen wie in 0.2. Phasenwechsel erzeugen keine Einblendungen oder Sprünge. Wasser, Brandung und Route verwenden die pausierbare Missionszeit.

Die Brandungsmasken haben 96 Texturpixel Rand je Seite, insgesamt 1216×960 statt 1024×768. Ihr Texturpixelmaßstab und Mittelpunkt stimmen mit dem Land überein. Culling berücksichtigt die gesamte Brandung. Alle Maskenaußenränder sind null; gerade abgeschnittene Schaumflächen entfallen.

Das HUD zeigt Armor, Bullets, Rolls, Weapon, Speed, Penetration, Mission, Score und ungesicherte Bonus-Points. Tastenbelegung steht im Controls-Menü. Aircraft enthält elf Profile und zeigt nur Grundwerte, einschließlich Spieler-Kugelkapazität. Öffnen aus der Pause setzt den Flug nicht fort.

Fokusverlust und Gamepad-Trennung pausieren; Fortsetzung ist bewusst. Audio aus 0.1 und Grafik aus 0.2 bleiben erhalten. Konturen, Brandungsrand und Schadensdarstellung wurden lokal aus bestehenden Daten ergänzt; 0.3 benötigt keine neuen Generierungscredits. Kampagne, weiterer Flugzeugausbau, Shop und Spieler-Raketen folgen später.
