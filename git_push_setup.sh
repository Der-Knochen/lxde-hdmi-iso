#!/bin/bash
# Git-Initialisierungsskript für dein ISO-Build-Projekt

# Git-Projekt initialisieren
git init

# Remote-Repo verknüpfen (ersetze durch deinen echten Benutzernamen)
git remote add origin https://github.com/Der-Knochen/lxde-hdmi-iso.git

# Alle Dateien hinzufügen und committen
git add .
git commit -m "Initial commit – Live ISO Build Script"

# Branch auf main setzen
git branch -M main

# Hochladen auf GitHub
git push -u origin main
