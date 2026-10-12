# Carrier Ace 0.8.0 – Küstenschiffe und Radarinseln

## Missionen

Mission 3 **Coastal Interdiction** verlangt zwei zerstörte Schiffe aus drei möglichen Zielen. Zwei Minensucher besitzen Armor 3 und bringen jeweils 500 Score. Der Hilfsminensucher besitzt Armor 2 und bringt 400 Score. Ihre eigenen Patrouillentempi betragen 14 beziehungsweise 22 logische Pixel pro Sekunde. Die Wege halten mindestens 24 Pixel Abstand zwischen vollständiger gedrehter Schiffsfläche und den konservativen Inselrechtecken.

Mission 4 **Radar Suppression** verlangt beide Radarstationen. Jede Station besitzt Armor 3 und bringt 500 Score. Die erste Station steht ungeschützt auf der kleinen Berginsel. Die zweite Station steht mit einem optionalen MG-Nest auf der großen Berginsel. Das MG-Nest besitzt Armor 3 und bringt 300 Score.

Beide Missionen behalten sechs Luftwellen und Counterattacks nach Welle 3 und 6. Der Bomberboss erscheint nur in Mission 1/2. Nach erfüllten Pflichtzielen müssen auch alle laufenden Luftgruppen und angeforderten Verstärkungen ihren Einsatz beenden. Danach folgt das vorhandene Landeminispiel. Erfolgreiche Landungen schalten Mission 3 beziehungsweise 4 nacheinander frei. F4F und F6F bleiben die einzigen nutzbaren Spielerflugzeuge.

## MG und Radar

Schiffsrümpfe drehen mit der Patrouillenrichtung. Der unabhängige Doppel-MG-Stand richtet sich auf den Spieler. Innerhalb von 260 Pixeln kündigt er seinen Angriff 0,6 Sekunden an. Danach feuert er drei parallele Geschosspaare im Abstand von 0,12 Sekunden. Nach dem Feuerstoß wartet er 2,4 Sekunden. Die beim Warnbeginn festgelegte Richtung bleibt bis zum Ende des Feuerstoßes unverändert. Jedes Geschoss verursacht einen Armor-Punkt Schaden. Das MG-Nest verwendet dieselben Regeln.

Eine Radarstation zeigt ihren Erfassungsradius von 220 Pixeln. Nach 1,5 Sekunden ununterbrochener Erfassung fordert sie einmalig drei Jäger an. Verlassen der Reichweite setzt die unvollständige Erfassung zurück. Die erste Station ruft drei normale Jäger. Die zweite ruft zwei normale Jäger und einen Fighter Ace. Eine Warnung dauert zwei Sekunden. Höchstens eine Radarformation ist gleichzeitig aktiv. Weitere Anforderungen warten auf den Abschluss der vorherigen Formation.

Zerstörung vor dem Alarm verhindert die Anforderung. Eine bereits angeforderte Formation bleibt auch nach Zerstörung der Station unterwegs. Luftformationen erhalten die bisherigen Loot- und Bonusregeln. Oberflächenziele erhalten weder Zufallsdrops noch Formationsbonus.

## Treffer und Missionsfehlschlag

Das Spieler-MG trifft Luft- und Oberflächenziele mit denselben Schadens- und Penetrationsregeln. Gemeinsame Kontaktzeiten bestimmen die Trefferreihenfolge. Derselbe Schuss trifft jedes Ziel höchstens einmal. See- und Bodenziele verursachen keine Flugzeugkollision. Ihre vorbereiteten konvexen Konturen stammen aus den festen Spriteflächen. Innenliegende transparente Deckdetails zählen als feste Oberfläche.

Ein Ziel entkommt erst, wenn die vollständige Trefferfläche unten das Bild verlässt. Zwei entkommene Schiffe führen in Mission 3 zu **Mission Failed**. Ein entkommener Radar führt in Mission 4 zu diesem Ergebnis. Die Maschine behält Rest-Armor, Ausbauten und Lackierungen. Gesicherte Bonus-Points bleiben erhalten. Flugboni und ungesicherte Punkte verfallen. Die nächste Mission bleibt gesperrt. Die Highscore-Liste unterscheidet **LANDED**, **LOST** und **FAILED**.

## Landschaft und Assets

Inseln, Brandung und Oberflächenziele verwenden denselben Scrollfortschritt: Missionszeit × 5,4 Pixel pro Sekunde. Pause hält diese Zeit an. Ein neuer Flug stellt die Route vollständig zurück. Radarstationen und MG-Nest bleiben an ihre Insel gebunden. Die Schiffsbewegung ergänzt diesen Scrollfortschritt um einen seitlichen Patrouillenweg.

Runway erzeugte zwölf Entwürfe für 156 Credits. Sechs Entwürfe wurden verworfen, sechs wurden übernommen. Der Küstenumriss nutzt eine lokal gespiegelte vorhandene Insel. Von den 160 verfügbaren Credits bleiben vier übrig. Es erfolgte kein zusätzlicher Kauf. `assets/revision08.json` enthält Modelle, Aufgaben, Prompts und Kosten. Rohbilder bleiben außerhalb von Git. Fertige PNGs, Schadensbilder und Wracks liegen lokal im Spielpaket. Drehbare Doppel-MG-Stände und die Dipolantenne sind lokale SVGs. Brandungsmasken erhalten 96 Texturpixel Rand.

`SurfaceCatalog` enthält Routen und Zielplätze. `SurfaceProfile` enthält Armor, Tempo, Trefferflächen und Bewaffnung. `SurfaceEncounter` steuert Patrouillen, MG, Radar, Verstärkungen und Pflichtziele. Oberflächenziele gehören nicht zur Luftgegnerreserve.

Historische Vorbilder: [Typ-11-Radar](https://www.combinedfleet.com/radar.htm) und [Sōkaitei-Minensucher](https://www.combinedfleet.com/Sokaitei.htm). Reichweiten, Armor und Doppel-MG sind Arcade-Regeln.

## Prüfung starten

```powershell
python tools/run_godot.py --headless --script tests/test_surface.gd
python tools/run_godot.py --headless --script tests/test_surface_ui.gd
python tools/run_godot.py --headless --script tests/test_flight.gd -- --mission=3
python tools/run_godot.py --headless --script tests/test_flight.gd -- --mission=4 --radar
python tools/run_godot.py --script tests/capture_surface.gd
```

Exportprüfung verwendet ausschließlich freigeschaltete Missionen. Windows: `-- --verify-mission=3` beziehungsweise `--verify-mission=4`. `--verify-radar-alarms` lässt den Piloten beide Alarme durch normale Eingaben auslösen. Im Browser entsprechen `?verify=1&mission=4&radar=1` diesen Parametern. Diese Prüfparameter speichern keine Flugresultate und verändern keine Kampfregeln.
