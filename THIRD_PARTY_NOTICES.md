# Drittanbieter und Assets

Carrier Ace ist ein eigenständiger Prototyp unter einem Arbeitstitel. Es enthält keine übernommenen 1942-/Galaga-Sprites, ROMs oder Musikdateien. Quellen und Anhänge dienen der Recherche bzw. der gestalterischen Orientierung. Marken und historische Spieltitel gehören ihren jeweiligen Inhabern. Für den eigenen Quellcode wurde noch keine allgemeine Weiterverbreitungslizenz festgelegt.

Grafikvorlagen, Soundeffekte und Musik wurden für dieses Projekt über den verbundenen Runway-Account erzeugt. Aufgaben, Prompts, Kosten und die verwendeten Entwürfe stehen in `assets/manifest.json` (0.1) und `assets/revision02.json` (0.2). Die neue Grafik verwendet hochauflösende Illustrationen, lokale Freistellung und Größenanpassung ohne Pixelraster oder Farbquantisierung. Audioaufbereitung umfasst OGG-Konvertierung, Pegel und Schleifen. Generierte Musikdateien sind Audioaufnahmen mit einer Tracker-Anmutung, keine editierbaren MOD-/XM-Kompositionen. Animierte Propeller, Rollen, Explosionen, Heckwelle und Pickup-Symbole entstehen lokal im Renderer. Wasser und Küstenbrandung verwenden eigene Godot-Shader. Historische Flugzeugnamen sind Vorbilder für die Illustration; Werte und Bewaffnung sind fiktive Arcade-Regeln.

## Godot Engine

Dieses Paket nutzt Godot 4.7.2. Godot und seine Exportvorlagen stehen unter der MIT-Lizenz. Die Engine enthält zusätzliche Bibliotheken; deren vollständige Hinweise sind über [Godots Lizenzseite](https://godotengine.org/license/) und [COPYRIGHT.txt der verwendeten Version](https://github.com/godotengine/godot/blob/4.7.2-stable/COPYRIGHT.txt) zugänglich.

Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md).
Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.

## Lokal ergänzte Grafik (0.5)

Die F4F Wildcat (`assets/art/wildcat.svg`) ist eine eigene Vektorillustration für Carrier Ace. Lackierungen werden durch einen lokalen Shader erzeugt. Hierfür wurden keine neuen Runway-Credits verbraucht. Die vorhandenen Runway-Grafiken und Audio-Dateien bleiben unverändert.
