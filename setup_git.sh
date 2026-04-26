#!/bin/bash
# Ejecuta este script UNA VEZ desde la raíz del proyecto para conectar con GitHub
set -e

echo "🔧 Inicializando repositorio Git..."
git init
git branch -M main

echo "🔗 Conectando con GitHub..."
git remote add origin https://github.com/KanjoLOOP/Myndex.git

echo "📦 Preparando commit inicial..."
git add .
git commit -m "feat: initial project structure

- Clean Architecture + MVVM scaffold
- Drift (SQLite) local database
- Riverpod state management
- go_router navigation
- Material 3 UI
- Full CRUD for content items
- Export / Import JSON
- TMDB datasource integration
- GitHub Actions CI workflow"

echo "🚀 Subiendo a GitHub..."
git push -u origin main

echo "✅ ¡Listo! Repositorio en https://github.com/KanjoLOOP/Myndex"
