#!/bin/bash
set -e

CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "❌ Bu script main branch üzerinde çalıştırılmalı."
  exit 1
fi

echo "🧹 Cleaning previous build..."
rm -rf _output
rm -f .jupyterlite.doit.db

echo "📦 Building JupyterLite..."
python -m jupyterlite build

# Build sonrası oluşan geçici db dosyası branch geçişini bozmasın
rm -f .jupyterlite.doit.db

# Cache busting için build zaman damgası üret
BUILD_TS=$(date +%s)
echo "$BUILD_TS" > .build-version
echo "🔖 Build version: $BUILD_TS"

# Eğer başka uncommitted şeyler varsa stash'le
if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  echo "📌 Uncommitted changes detected, stashing..."
  git stash push -u -m "auto-stash before publish"
  STASHED=1
else
  STASHED=0
fi

echo "🚀 Switching to gh-pages..."
git checkout gh-pages

echo "🧹 Cleaning gh-pages root..."
find . -maxdepth 1 ! -name '.' ! -name '.git' -exec rm -rf {} +

echo "📂 Copying build output from main..."
git checkout main -- _output
mv _output/* .
rm -rf _output

# İsteğe bağlı: build versiyonunu root'a koy
cp ../.build-version . 2>/dev/null || true

echo "💾 Committing..."
git add -A
git commit -m "Publish fresh JupyterLite build ($BUILD_TS)" || echo "ℹ️ Nothing to commit"

echo "🌍 Pushing..."
git push -f origin gh-pages

echo "🔙 Returning to main..."
git checkout main

# Geçici build version dosyasını temizle
rm -f .build-version

# Stash geri al
if [ "$STASHED" -eq 1 ]; then
  echo "↩️ Restoring stashed changes..."
  git stash pop || echo "⚠️ Stash pop had conflicts; stash kept."
fi

echo "✅ Done!"
echo "⚠️ Eğer tarayıcı eski içeriği gösterirse Ctrl+Shift+R ile hard refresh yap."