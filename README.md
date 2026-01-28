# GravityUI

Ein modernes, feature-reiches UI-Konfigurations-Addon für World of Warcraft.

## 🎮 Verwendung

### Slash Commands

- `/gui` oder `/gravityui` - Öffnet das Haupt-Einstellungsfenster
- `/rl` oder `/rlui` - Reload UI (lädt das Interface neu)
- `/wa` oder `/cdm` - Öffnet die Cooldown Settings (CDM)
- `/edit` - Öffnet den WoW Edit Mode

### Minimap Button

- **Linksklick**: Öffnet das Einstellungsfenster.
- **Drag**: Der Button kann frei um die Minimap positioniert werden.
- **Addon Compartment**: GravityUI ist in das WoW Addon-Menü (Minimap-Leiste) integriert.

## 📋 Features

### Menü-Sektionen

1.  **Main**: Willkommen, Version, Quick Settings und wichtige Links.
2.  **UI Styling**: Umfassendes Styling mit runden Designs, benutzerdefinierten Akzentfarben und Klassenfarben-Unterstützung.
3.  **Action Bars**: Konfiguration für bis zu 8 Action Bars mit Visibility-Optionen und modernem Look.
4.  **Minimap**: Detaillierte Einstellungen für den Minimap-Button und Minimap-Features.
5.  **Datatexts**: Informative Anzeigen für FPS/MS, Gold, Haltbarkeit, Spec/Loot und mehr.
6.  **Quality of Life**: Automatisierung (Reparieren, Verkaufen), Quick Salvage, Auto-Hide für UI-Elemente und Installer.
7.  **Screen Indicators**: Vignette-Effekte und visuelle Indikatoren für Spielereignisse.
8.  **Profiles**: Vollständige Profilverwaltung (Erstellen, Löschen, Kopieren, Umschalten) basierend auf AceDB.

### Spezielle Highlights

-   **Intelligente Suche**: Eine dedizierte Suchseite mit Breadcrumbs hilft dabei, jede Einstellung sofort zu finden.
-   **Zentraler Installer**: Ein-Klick-Profile für Top-Addons wie **Details**, **Plater**, **BigWigs**, **BCDM** und mehr.
-   **Einheitliches Branding**: Konsistentes Look-and-Feel inklusive GravityUI-Logo im Fenster und auf der Minimap.

### Zusätzliche Module

-   **Skyriding**: Angepasste UI-Elemente für das Drachenreiten/Himmelsreiten.
-   **Chat & Tooltip**: Verbesserte Darstellung und Funktionalität für Chat und Tooltips.
-   **Loot & Objectives**: Optimierten Fenster für Beute und Questziele.

## 📁 Struktur

```
GravityUI/
├── GravityUI.toc       # Addon-Metadaten & Ladeliste
├── core/
│   ├── init.lua        # Hauptinitialisierung & Slash Commands
│   ├── constants.lua   # Farben, Pfade & globale Konstanten
│   ├── defaults.lua    # Standard-Einstellungen (AceDB)
│   ├── framework.lua   # Eigene Widget-Bibliothek für das GUI
│   ├── window.lua      # Hauptfenster-Logik
│   ├── styling.lua     # Globales UI-Styling
│   ├── datatexts.lua   # Datatext-System
│   └── installer.lua   # Multi-Addon Profile Installer
├── pages/
│   ├── main.lua        # Einstellungsseite: Hauptmenü
│   ├── search.lua      # Dedizierte Suchergebnis-Seite (Neu!)
│   ├── styling.lua     # Einstellungsseite: UI Styling
│   ├── profiles.lua    # Profilverwaltung & Import/Export
│   └── ...             # Weitere Konfigurationsseiten
├── Libs/               # Konsolidierte Bibliotheken via libs.xml
└── assets/             # GravityUI Logo, Fonts & Texturen
```

## 🚀 Erste Schritte

1.  Logge dich in World of Warcraft ein.
2.  Öffne das Interface mit `/gui`.
3.  Nutze den **Express Installer** unter "Profiles > Installers" für eine schnelle Einrichtung.
4.  Nutze die **Suchleiste** oben rechts, um bestimmte Optionen schnell zu finden.

## 🎨 Design-Philosophie

GravityUI setzt auf ein **modernes, dunkles Design** ("Blue Condition Theme") mit:
- Fokus auf Visual Excellence und Performance.
- Hochwertige Mikro-Animationen und Hover-Effekte.
- Maximale Anpassbarkeit durch das integrierte Styling-System.

## 📝 Credits & Support

-   **Author**: Gravity
-   **Website**: [Gravity-Guild.eu](https://Gravity-Guild.eu)
-   **Lizenz**: GPLv3

### Support

1.  Melde Probleme über die Website oder den Discord.
2.  Stelle sicher, dass alle Abhängigkeiten im `Libs`-Ordner vorhanden sind.

---

**Viel Spaß beim Spielen! 🎮**

