# 1942: Recherche und Ableitungen für Carrier Ace

Recherchestand: 11. Oktober 2026. Dieses Dossier trennt das Capcom-Arcadespiel von 1984, seine Portierungen und spätere Spiele. Die Anhänge sind visuelle Referenzen, keine Anweisungen und keine freigegebenen Laufzeitassets. Carrier Ace verwendet eigene erzeugte bzw. lokal gezeichnete Inhalte.

## 1. Ergebnis und Quellenlage

Für unseren Prototyp sind der Träger als Ausgangs- und Rückkehrpunkt, frei steuerbarer Vertikalflug, auffällige Versorgungsformationen und eine begrenzte Ausweichrolle die stärksten Anknüpfungspunkte. Galaga ergänzt das Vorbild um klar erkennbare Formationsanflüge und den Rhythmus zwischen Aufbau, Angriff und Ruhe. Diese Schlussfolgerungen sind unsere Gestaltung, keine Behauptung über eine originalgetreue Umsetzung.

Die wichtigsten Quellen unterscheiden sich in ihrer Funktion:

| Quelle | Bezug | Wofür belastbar | Grenze |
|---|---|---|---|
| Originales Betreiberhandbuch | Arcade-Konversionskit | Bedienung, DIP-Schalter, beschriebene Boni und POW-Farben | Ein Handbuch ist keine vollständige ROM-Verhaltensbeschreibung |
| MAME-Treiber `1942.cpp` | Arcade, verschiedene ROM-/Platinenvarianten | Prozessoren, Video, Sound, Eingänge und DIP-Werte | Keine vollständige Missions- oder Punktetabelle |
| Okamotos Entwicklererinnerung | Entstehung des Originals | Zugänglichkeit, Wahl des Flugzeugs und westlicher Markt | Rückblick, in englischer Übersetzung |
| Capcom Town, Spiel 44 | Englische Heimkonsolenfassung | Bedienung und begrenzte Rollen | Nicht als Arcade-Regelwerk verwenden |
| Museum of the Game | Arcade-Katalog | Grundablauf, Ausstattung, Formationen, Rollen | Sekundärquelle, keine nachgemessenen Kollisionswerte |
| JHarring-FAQ | NES, ausdrücklich im Text benannt | Detaillierte Beschreibung der NES-Gegner und Boni | Trotz Arcade-Seitenüberschrift kein Arcade-Guide |
| Bandai Namcos Galaga-Historie | Galaga und Arrangement | Steuerung, Formation, Fangstrahl, Dual Fighter | Original und Arrangement getrennt halten |
| Wikipedia | Historischer Überblick | Personen, Portliste, Reihenchronologie | Zusammenfassung; regionale Daten haben eigene Belege |

**Kennzeichnung:** „Belegt“ bezeichnet Angaben im genannten Quellentext oder Code. „Versionsabhängig“ bezeichnet Abweichungen zwischen Fassungen bzw. Betreiber-Einstellungen. „Ableitung“ bezeichnet unsere Designentscheidung. „Offen“ bezeichnet Details, für die keine passende Originalmessung oder Primärquelle vorliegt.

## 2. Entstehung und Veröffentlichung

1942 erschien 1984 bei Capcom: Design Yoshiki Okamoto, Programmierung Tamio Nakazato, Musik Ayako Mori. [Historischer Überblick](https://en.wikipedia.org/wiki/1942_(video_game))

Japanische Veröffentlichung Ende 1984 und westliche Verbreitung 1985 erklären unterschiedliche Datumsangaben. Romstar und Williams erscheinen als Vertriebs-/Lizenzpartner. Ein einziges weltweites Tagesdatum wäre irreführend. [Regionale Arcade-Veröffentlichungen](https://www.mobygames.com/game/7949/1942/releases/arcade/), [Arcade-ROM-Varianten im MAME-Treiber](https://github.com/mamedev/mame/blob/master/src/mame/capcom/1942.cpp)

Okamoto beschreibt ein bewusst zugängliches Shoot ’em up. Die Weltkriegsdarstellung sollte verständlich sein; erstmals wurde der westliche Markt gezielt berücksichtigt. Die amerikanische P-38 war eine entsprechende Wahl. Die oft zitierte 1942-Passage steht auf der Interviewseite in einer späteren Rückblicksammlung; die Seite enthält daneben ein CPS-1-Interview von 1989. Diese Zeitkontexte dürfen nicht gleichgesetzt werden. [Entwicklerinterviews und Rückblicke](https://shmuplations.com/cps1/)

Das historische Szenario ist eine Arcade-Fantasie des Pazifikkriegs. Das Flugzeug „Super Ace“ und große japanische Gegnerflugzeuge dienen der schnellen visuellen Verständlichkeit. Trägereinsatz und Flugabläufe sind keine verlässliche historische Flugsimulation. Für Carrier Ace übernehmen wir den Ablauf als Fiktion mit eigenen Flugzeugnamen.

## 3. Arcade-Hardware und audiovisuelle Gestaltung

Für die Originalkonfiguration zeigt MAME zwei Z80 mit jeweils 3 MHz, einen 12-MHz-Mastertakt und zwei AY-3-8910 mit 1,5 MHz. Ton wird mono ausgegeben. Der sichtbare Rasterbereich ist vor Rotation 256×224; die um 270 Grad gedrehte Anzeige ergibt 224×256 im Hochformat. Aus dem eingetragenen Rastertakt ergibt sich ungefähr 59,64 Hz. Zeichen sind 8×8 mit 2 Bit pro Pixel, Hintergrundkacheln 16×16 mit 3 Bit und Sprites 16×16 mit 4 Bit. Die Palette besitzt 256 tatsächliche Farbeinträge und zusätzliche Zuordnungstabellen. Andere Platinenvarianten im selben Treiber haben abweichende Takte. [MAME-Konfiguration](https://github.com/mamedev/mame/blob/master/src/mame/capcom/1942.cpp)

**Ableitung aus Technik und Referenzbildern:** Ein scrollender Kachelhintergrund vermittelt Geschwindigkeit, während überschaubare Silhouetten und helle Geschosse die Aktion tragen. Kleine Flugzeuge müssen nicht fotorealistisch sein, um ihre Rolle zu zeigen. Meer, Inseln und Träger bilden eine kontinuierliche Welt; die obere Punkteanzeige bleibt davon getrennt.

Carrier Ace wählt 960×540 im Querformat. Das ist eine bewusste Änderung gegenüber dem Hochkantautomaten. Seitliche Flugwege brauchen deshalb mehr Aufmerksamkeit, während die sichtbare Anflugstrecke kürzer wird. Zwei bis drei deutlich unterscheidbare Formen, helle Spielerprojektile, warme Gegnerprojektile und gedämpftes Wasser halten die Kampfinformation lesbar. Palette und Pixelraster vermitteln eine spätere Arcade-/Amiga-Anmutung, ohne die technischen Beschränkungen eines Amiga 500 zu simulieren.

Die Musik des Originals darf nicht mit der C64-Fassung verwechselt werden. Deren bekannte Bearbeitung durch Mark Cooksey greift Musik aus *633 Squadron* auf. Für Carrier Ace wurden eigene instrumentale Audioaufnahmen erzeugt. Sie haben eine Tracker-Anmutung; sie sind keine MOD-Dateien und übernehmen keine Melodie aus 1942. [Port- und Musikübersicht](https://en.wikipedia.org/wiki/1942_(video_game))

## 4. Bedienung, Risiko und Fortschritt im Arcade-Original

Der Automat verwendet einen Achtwege-Joystick und zwei Aktionsknöpfe für Schuss und Loop. Ein oder zwei Spieler spielen abwechselnd. Das Spiel führt durch 32 Abschnitte über See- und Landhintergründe. Die Prozentanzeige bewertet Abschüsse zusätzlich zum Punktestand. Rote bzw. farblich hervorgehobene Formationen sind eine Gelegenheit für POW-Belohnungen. Drei Rollen pro Abschnitt bieten eine begrenzte Rettung. [Museum of the Game](https://www.arcade-museum.com/Videogame/1942--capcom)

Freie Bewegung in beiden Achsen und tödliche Treffer unterscheiden das Original von unserem Panzerungsmodell. Historische Gegnermodelle heißen Ki-61, A6M, Ki-48 und G10N. [1942-Spielübersicht](https://en.wikipedia.org/wiki/1942_(video_game))

Die Lebenszahl ist nicht unveränderlich: MAME dokumentiert 1, 2, 3 oder 5, mit drei als Default. Bonusleben beginnen je DIP-Wahl bei 20.000 oder 30.000 Punkten, weitere Schwellen folgen ebenfalls der Einstellung. Vier Schwierigkeitsstufen sind vorgesehen. „1942 hat immer drei Leben“ ist deshalb als Aussage über alle Automaten ungenau. [DIP-Einstellungen im Treiber](https://github.com/mamedev/mame/blob/master/src/mame/capcom/1942.cpp)

**Ableitung:** Eine begrenzte Rolle macht Gefahr vorhersehbar und gibt eine taktische Reserve. Eine zusätzliche prozentuale Abschusswertung lädt dazu ein, bekannte Formationen sauberer zu spielen. Carrier Ace übernimmt die Quote im Ergebnis, verwendet aber 100 Panzerung und klar definierte Schadenswerte statt sofortigem Verlust durch jeden Treffer. Die drei Leben und der vollständige Missionsneustart sind feste Prototypregeln.

## 5. POWs, Punkte und Träger laut Betreiberhandbuch

Die Spielanleitung auf gedruckter Seite 6, PDF-Seite 8, beschreibt eine Belohnung nach vollständigem Abschuss einer farbgleichen Formation. Das POW muss berührt werden. Die Tabelle nennt:

| Farbe laut Handbuch | Beschriebener Effekt |
|---|---|
| Grün | Vierfachschuss |
| Gelb | Zusätzlicher Loop |
| Orange | Gegner schießen 15 Sekunden lang nicht |
| Weiß | Alle Gegnerflugzeuge werden zerstört |
| Grau | Schild für das Spielerflugzeug |
| Schwarz | Zusätzliche Maschine für die Staffel |
| Rot | Punkte |

Die Rückkehr zum Träger verknüpft Abschussquote und verbleibende Loops mit Boni; als Beispiele werden 90% mit 10.000 Punkten und ein Loop mit 1.000 Punkten genannt. Ein schwerer Bomber beendet seine Welle nach dem Abschuss. Das Handbuch beschreibt außerdem einen bezahlten Continue und erhöhte Herausforderung nach Fortsetzung. [Originalhandbuch, Abschnitt „Game Operation“](https://files.stardustarcade.com/PDF_Arcade_Manuals_and_Schematics/1942%20%28Capcom%29.pdf)

**Versionsgrenze:** Diese Betreiberbeschreibung und vereinfachte Port-FAQs sind nicht identisch. Die genaue Reihenfolge von POWs, seltene Bedingungen und Übersetzung von „shield“ bzw. „squadron“ erfordern einen zur Platinenrevision passenden Spieltest. Die Tabelle wird deshalb als Handbuchaussage festgehalten. Eine universelle Drop-Tabelle für alle Ports wird daraus nicht abgeleitet.

Eine interaktive Anflugprüfung mit 0,75 Sekunden Haltezeit ist unsere Erweiterung. Die historischen Trägersequenzen strukturieren Abschnitte und Abrechnung; sie belegen keinen identischen Landemechanismus. Im Prototyp ist die Landung ein ruhiger Abschluss mit sichtbarem Korridor und ohne Verluststrafe.

## 6. NES-Regeln getrennt betrachten

Capcom Town nennt seine Fassung ausdrücklich „Home Console“ und bezieht die Beschreibung auf die englische Version. Dort sind Pfeile zur Bewegung, Z zum Schießen, X für die Rolle und Enter für Start/Pause dokumentiert. Begrenzte Loops und Punkte für ungenutzte Einsätze werden hervorgehoben. Ein dortiger Spielstand wird beim Verlassen der Seite zurückgesetzt. [Capcom Town](https://captown.capcom.com/en/classic_games/44)

JHarrings FAQ trägt trotz einer Arcade-URL ausdrücklich den Zusatz NES. Es beschreibt kleine graue Angreifer, kreisende grüne Maschinen, rote Versorgungsformationen sowie mittlere und große Flugzeuge aus dem unteren Bildschirmrand. Vierfachschuss, zerstörbare Begleitflugzeuge, Bildschirmräumung und Punkte erscheinen als POW-Effekte. Beim Loop kann man sich bewegen, aber nicht schießen. Ein Verlust setzt auf einen Abschnittscheckpoint zurück. Der Guide nennt Bossbegegnungen bei 7, 15, 23 und 31 in seiner Zählweise, ungefähr 30 Treffer und 20.000 Punkte. Dies sind NES-Guide-Angaben, keine nachgewiesenen Arcade-Konstanten. [FAQ, ausdrücklich NES](https://gamefaqs.gamespot.com/arcade/563933-1942/faqs/8496)

**Ableitung:** Wir verwenden einfache, gut erkennbare Waffenstufen und einen vollständigen Versuch als Fortschrittseinheit. Waffen verlieren ihre Stufe beim Abschuss. Drei Rollen gelten pro Versuch; ungenutzte Rollen geben derzeit keinen zusätzlichen Bonus. Der erste Bomber besitzt 300 Panzerung und drei Anflüge. Die Zahl historischer Boss-Treffer wird nicht direkt übernommen, weil unsere Salvenrate, Durchschlagskraft und Waffenstufen anders sind.

## 7. Portierungen, Sammlungen und Remakes

| Fassung / Veröffentlichung | Einordnung für die Recherche |
|---|---|
| Arcade, 1984 | Hauptreferenz für Spielfluss und Trägerrahmen |
| Famicom/NES, 1985 Japan / 1986 Nordamerika | Micronics-Port; eigene Grafik, Audio und Regeln getrennt betrachten |
| PlayChoice-10 | NES-basierte Automatenpräsentation; kein Ersatz für das originale Arcadeboard |
| C64, ZX Spectrum, Amstrad CPC, Elite Systems | Heimcomputer-Umsetzungen mit anderen technischen Bedingungen |
| MSX, PC-8801, FM-7, Sharp X1 | Weitere japanische Computerfassungen |
| Game Boy Color, 2000/2001 regional | Spätere Handheld-Portierung |
| Capcom Generations 1 | Sammlung mit dem Klassiker |
| Capcom Classics Collection / Reloaded | Spätere Wiederveröffentlichungen |
| 1942: Joint Strike, 2008 | Eigenständiges Remake; Regeln nicht rückwirkend dem Original zuschreiben |
| 1942: First Strike, 2010 | Spätere Mobilinterpretation |

Portliste: [MobyGames, Plattformübersicht](https://www.mobygames.com/game/7949/1942/); Sammlungen und Remakes: [Wikipedia mit Einzelbelegen](https://en.wikipedia.org/wiki/1942_(video_game)). MobyGames war im Suchindex lesbar, beim direkten Abruf gesperrt; es dient hier nur als zusätzlicher Portnachweis. Seine frühe GBC-Jahresangabe weicht von den regionalen Angaben im Überblick ab, weshalb die Tabelle die ausdrücklich belegten regionalen Daten nennt. Die Jahresangaben der frühen Heimcomputerports sind regional nicht vollständig gegengeprüft. Ein bestätigter offizieller Amiga-500-Port wurde in den ausgewerteten Quellen nicht gefunden; „Amiga-Stil“ ist hier ein Gestaltungsziel.

**Technische Einordnung, keine gemessene Portbewertung:** Ein NES-Port muss mit anderen Sprite-/Audiofähigkeiten auskommen als das Arcadeboard. Beim Spectrum beeinflussen Farbattribute die Darstellung; beim C64 ist SID-Musik ein eigener klanglicher Bezug. Daher sind Erinnerungen an Musik, Gegnerfarben oder Waffen häufig fassungsbezogen. Dieses Dossier bewertet keine der alten Fassungen anhand eines selbst durchgeführten Vergleichstests.

Sammlungen, Emulation und Remakes erfüllen unterschiedliche Zwecke. Eine emulierte Arcadefassung eignet sich zur Prüfung originaler Formationstakte; ein neu gestaltetes Remake liefert eher Ideen für Effekte, Koop oder moderne Bedienung. Für Carrier Ace sind Screenshots Perspektivreferenzen, keine Vorlage zum Extrahieren fremder Sprites.

## 8. Weitere 194X-Reihe

Die Reihenchronologie nennt 1943: The Battle of Midway (1987), 1943 Kai (1988), 1941: Counter Attack (1990), 19XX: The War Against Destiny (1996) und 1944: The Loop Master (2000). Die Zahlen sind Titel, keine Reihenfolge der Veröffentlichung. Joint Strike und First Strike folgten später. [Reihenüberblick](https://en.wikipedia.org/wiki/1942_(video_game))

| Spiel | Wesentliche Unterschiede | Eigene Schlussfolgerung |
|---|---|---|
| 1943: The Battle of Midway | Gleichzeitiges Spiel zu zweit; Flugzeug- und Schiffsabschnitte, Energie statt einzelner Trefferleben, Spezialangriffe verbrauchen Energie. Zwei Flugzeuge können Energie austauschen. [Museum](https://www.arcade-museum.com/Videogame/1943-the-battle-of-midway) | Energie und Spezialaktion müssen als gemeinsames System abgestimmt werden. Unser Schild bleibt dagegen einfach und reparierbar. |
| 1943 Kai | Für Japan überarbeitete Fassung von 1943. Die Katalogjahre 1987/1988 widersprechen sich; ohne regionalen Originalbeleg bleibt die Abweichung offen. [Museum](https://www.arcade-museum.com/Videogame/1943-kai-midway-kaisen) | Eine Revision getrennt untersuchen, statt alle Regeln dem Ausgangsspiel zuzuschreiben. |
| 1941: Counter Attack | Zwei Spieler gleichzeitig, Stereo; Flugzeuge, Boote und Bodenziele, teils enge Stadt- und Hafenwege. [Museum](https://www.arcade-museum.com/Videogame/1941-counter-attack) | Landschaft kann die Bewegungsaufgabe prägen. Im ersten Level genügt ein offenes Meer. |
| 19XX: The War Against Destiny | Drei auswählbare Flugzeuge mit unterschiedlichen Geschwindigkeits- und Waffenwerten; aufgeladener Schuss markiert ein Ziel für gelenkte Zusatzangriffe. [Museum](https://www.arcade-museum.com/Videogame/19xx-the-war-against-destiny) | Flugzeugprofile lohnen sich bereits jetzt. Zielmarkierung wäre ein eigenes späteres Waffensystem. |
| 1944: The Loop Master | 8ing/Raizing entwickelte das von Capcom veröffentlichte Spiel; vertikales Flugspiel auf horizontalem Monitor, zwei Spieler gleichzeitig. [Museum](https://www.arcade-museum.com/Videogame/1944-the-loop-master) | Querformat und vertikaler Spielfluss passen zusammen; das Vorbild bestimmt nicht das Seitenverhältnis. |

Auch für 19XX sind 1995 und 1996 im Umlauf. Der Museumskatalog nennt 1995, der oben genannte Überblick 1996. Das ist als Quellenabweichung festgehalten. Die Museumseinleitung bezeichnet 19XX außerdem als letztes Reihenspiel, obwohl ihr eigenes Reihenverzeichnis 1944 aufführt; diese Einleitung wird nicht übernommen. Die Tabelle fasst belegte Katalogbeschreibungen zusammen und ersetzt keinen ROM-Spieltest.

Der Entwickler-Rückblick zu 1943 erwähnt den „megacrash“, also eine weiterentwickelte Bildschirm-/Geschossräumaktion. Die Aussage stammt aus dem Kontext von 1943, nicht aus 1942. [Entwickler-Rückblick](https://shmuplations.com/cps1/)

Für künftige Erweiterungen sollte jedes Vorbild ein eigenes Regelblatt erhalten: Ressourcenverbrauch einer Spezialaktion, Energie/Panzerung, Waffenwahl, Anzahl Spieler, Punktesystem und Bossstruktur. Der vorliegende Prototyp ist kein Sammelsurium aller 194X-Regeln. Seine Rollen, Panzerung und Drops sind bereits vollständig in `DESIGN.md` festgelegt. Detaillierte Regeln sämtlicher Nachfolger sind hier noch nicht durch Originalhandbücher abgesichert und werden nicht als geprüft ausgegeben.

## 9. Galaga als Formationsvorbild

Bandai Namco datiert Galaga auf 1981. Der Fighter bewegt sich horizontal und feuert; höchstens zwei Schüsse können zugleich auf dem Bildschirm sein. Gegner fliegen zunächst in eine Formation mit ungefähr 40 Einheiten ein und greifen später in variierenden Mustern an. Drei Rollen heißen Boss, Guard und Grunt. Der Boss kann das Spielerflugzeug per Fangstrahl gefangen nehmen. Eine Rettung ergibt den Dual Fighter mit doppelter Feuerkraft und doppelter Breite. Challenging Stages ergänzen das Spiel. [Offizielle Galaga-Dokumentation](https://galaga.com/en/history/galaga.php)

Galaga Arrangement erschien 1995 in Namco Classic Collection Vol. 1. Es variiert den Dual-Fighter-Angriff nach dem fangenden Gegnertyp, gliedert seine Abschnitte in Zonen und besitzt in Abschnitt 30 den Boss King Galaspark. Koop wird dort ausdrücklich erwähnt. Diese Merkmale gehören zum Arrangement. [Offizielle Arrangement-Dokumentation](https://galaga.com/en/history/galagaArrange.php)

| Gestaltungsfrage | 1942 als Ausgangspunkt | Galaga als Ergänzung | Umsetzung in Carrier Ace |
|---|---|---|---|
| Raum | Freie Bewegung über scrollender Welt | Begrenztes horizontales Ausweichen | Beide Achsen, 16:9 |
| Rhythmus | Reise und Trägerabschnitte | Formation aufbauen und angreifen | Sechs benannte 30-s-Wellen |
| Gegnerlernen | Flugbahnen und größere Ziele | Wiederkehrende Gruppenmuster | Gerade, Bogen und Kreuzung |
| Belohnung | POW nach vollständiger Gruppe | Rettung und Dual Fighter | Markierte Vierergruppe, genau ein Drop |
| Ausweichentscheidung | Begrenzter Loop | Position und Timing | Drei Schutzrollen |
| Abschluss | Träger und Abrechnung | Nächste Formation / Challenge | Bomber, Landekorridor, Ergebnis |

**Eigene Schlussfolgerung:** Ein Spieler sollte eine Versorgung erkennen, ihre Bewegung vorhersagen und bewusst entscheiden können, ob er dafür seine Position riskiert. Der Vierer-Verband und feste Belohnungen sind leicht zu lernen. Der fehlende Drop bei einer entkommenen Maschine macht das Ziel klar. Galagas Fangmechanik wird nicht eingebaut, weil sie einen zusätzlichen Lebens-/Rettungszustand und andere Silhouetten erfordern würde.

## 10. Konkrete Umsetzung und Grenzen

Das Level lehrt zuerst gerade Anflüge, dann Seitenbögen, Kreuzungen, gepanzerte Ziele und zuletzt Kombinationen. Reparatur belohnt den vollständigen Verband, ohne die Rundenstruktur zu ändern. Doppelschuss vergrößert den erfassten Bereich; Trippelschuss deckt die Mitte plus zwei leichte Winkel ab. Durchschlagen trifft höchstens zwei verschiedene Ziele; ein überlappender Gegner wird nicht mehrfach vom selben Projektil getroffen. Diese Regeln sind eigene, getestete Verträge.

Panzerung puffert Fehler; Trefferschutz verhindert eine sofortige Schadenskette. Ein vollständiger Missionsneustart mit noch vorhandenen Leben macht einen Versuch überschaubar. Ein ruhiger Rückflug trennt Bossstress und Abschluss. Das Ergebnis zeigt die Abschussquote als Anreiz für einen besseren nächsten Versuch.

Die eigenen Grafiken verwenden eine gedämpfte Meerespalette, metallische Spielerfarbe und drei erkennbare Gegnersilhouetten. Nationalität oder historische korrekte Flugzeugdaten bestimmen keine Mechanik. Audio dient der Rückmeldung: verschiedene Schüsse, Treffer, Pickup, Rolle und Landung. Die technische Loop-Aufbereitung verhindert abrupte Datensprünge; subjektive Lautheit und musikalische Passung bleiben Gegenstand des eigenen Hörtests.

### Offen bzw. nicht behauptet

- Keine ROM-Disassemblierung sämtlicher 32 Arcade-Abschnitte, keine vollständige Tabelle aller Flugbahnen und seltenen POW-Bedingungen.
- Keine selbst gemessenen historischen Hitboxen, Bullet-Speeds, Bosstreffer oder Score-Exploits.
- Keine vereinheitlichte Boss-Abschnittsnummerierung zwischen Countdown-Anzeige, vorwärts gezähltem Guide und Ports.
- Keine pauschale Übertragung der NES-Regeln auf Arcade, C64 oder andere Computerfassungen.
- Keine vollständige Einzelanalyse jedes Nachfolgers; deren Chronologie und Abgrenzung sind erfasst.
- Keine Aussage über aktuelle Verfügbarkeit/Preise in allen digitalen Stores.

## 11. Technische Quellen für unser Projekt

Godot 4.7.2 Standard und passende Vorlagen wurden von den offiziellen Veröffentlichungen bezogen. Die lokal ausgeführte Engine meldet `4.7.2.stable.official.ed1daf0bf`. [Godot-Download](https://godotengine.org/download/windows/4.7.2/)

Der Webexport verwendet Compatibility/WebGL 2 und keine Threads. Lokaler HTTP-Start umgeht die Einschränkungen beim direkten Öffnen einer HTML-Datei. Audio benötigt Nutzerinteraktion; Gamepads und dauerhafte Speicherung unterliegen Browserbedingungen. Private Modi können Speicherung einschränken. Diese Bedingungen sind in der Startanleitung berücksichtigt. [Godot-Webexport](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)

Die Budgetkontrolle folgt dem genehmigten Limit und dem tatsächlich gemeldeten Accountsaldo. Es wurden 138 Credits verbraucht; alle fertigen Assets sind lokal. Prompts, Aufgaben-IDs und die verworfenen Entwürfe stehen in `assets/manifest.json`. Keine signierten Download-URLs werden versioniert. [Runway-Bildkosten](https://help.runwayml.com/hc/en-us/articles/37053594806419-Creating-with-Gen-4-Image), [Runway-Preise](https://docs.dev.runwayml.com/guides/pricing/)

## 12. Quellenverzeichnis

Alle Quellen am 11.10.2026 geprüft, soweit oben nicht als offen gekennzeichnet. Originalhandbuch lokal gerendert und relevante Spielseite vollständig visuell gelesen; die lokal gespeicherte Kopie ist ein Recherchezwischenprodukt, kein Teil des Spielpakets.

1. [1942, Wikipedia](https://en.wikipedia.org/wiki/1942_(video_game)): historische Übersicht, Personen, Portierungen und Reihe.
2. [Capcom/Romstar-Betreiberhandbuch](https://files.stardustarcade.com/PDF_Arcade_Manuals_and_Schematics/1942%20%28Capcom%29.pdf): Konversionskit, „Game Operation“, gedruckte Seite 6/PDF-Seite 8.
3. [MAME, `src/mame/capcom/1942.cpp`](https://github.com/mamedev/mame/blob/master/src/mame/capcom/1942.cpp): Quellcode, Originalkonfiguration und getrennte Varianten; `master` ist veränderlich, Abrufstand beachten.
4. [Capcom Town, 1942 Englisch](https://captown.capcom.com/en/classic_games/44): offiziell als Heimkonsolenfassung bezeichnet.
5. [Shmuplations, Capcom and the CPS-1](https://shmuplations.com/cps1/): übersetzte Entwicklerinterviews und spätere Rückblicke; 1942 steht im Rückblickteil.
6. [Museum of the Game, 1942](https://www.arcade-museum.com/Videogame/1942--capcom): Arcade-Ausstattung und zusammengefasster Ablauf.
7. [JHarring, FAQ, 8.8.2000](https://gamefaqs.gamespot.com/arcade/563933-1942/faqs/8496): Inhalt ausdrücklich NES, URL-Kategorie abweichend.
8. [Bandai Namco, Galaga](https://galaga.com/en/history/galaga.php): offizieller Systemüberblick.
9. [Bandai Namco, Galaga Arrangement](https://galaga.com/en/history/galagaArrange.php): offizielle Beschreibung der Fassung von 1995.
10. [Godot, Webexport](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html): technische Bedingungen für unseren Browserbuild.
11. [Godot 4.7.2 Download](https://godotengine.org/download/windows/4.7.2/): festgeschriebene Engine.
12. [Runway, Gen-4 Image](https://help.runwayml.com/hc/en-us/articles/37053594806419-Creating-with-Gen-4-Image) und [Preise](https://docs.dev.runwayml.com/guides/pricing/): Generation und Budgetgrundlage.
13. [MobyGames, 1942](https://www.mobygames.com/game/7949/1942/) und [Arcade-Releases](https://www.mobygames.com/game/7949/1942/releases/arcade/): im Suchindex geprüfte Plattform- und Regionalübersicht; direkter Abruf mit 403 gesperrt.
14. Museum of the Game: [1943](https://www.arcade-museum.com/Videogame/1943-the-battle-of-midway), [1943 Kai](https://www.arcade-museum.com/Videogame/1943-kai-midway-kaisen), [1941](https://www.arcade-museum.com/Videogame/1941-counter-attack), [19XX](https://www.arcade-museum.com/Videogame/19xx-the-war-against-destiny), [1944](https://www.arcade-museum.com/Videogame/1944-the-loop-master); sekundäre Katalogbeschreibungen, Datumsabweichungen ausdrücklich dokumentiert.

StrategyWiki sowie eine vermutete Arcade-Stadium-Detailseite ließen sich in diesem Recherchelauf nicht zuverlässig öffnen. Sie sind deshalb keine tragenden Quellen dieses Dossiers. Die Forschung ist für die Spielentwicklung breit angelegt, aber nicht als lückenlose Archivierung jeder regionalen Fassung zu verstehen.
