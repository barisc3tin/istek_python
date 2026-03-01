#!/bin/bash
set -e

echo "📦 Building JupyterLite..."
python -m jupyterlite build

# Build sonrası oluşan geçici db dosyası branch geçişini bozmasın:
rm -f .jupyterlite.doit.db

# Eğer başka uncommitted şeyler varsa (yanlışlıkla), stash'le:
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

echo "💾 Committing..."
git add -A
git commit -m "Publish fresh JupyterLite build" || echo "ℹ️ Nothing to commit"

echo "🌍 Pushing..."
git push -f origin gh-pages

echo "🔙 Returning to main..."
git checkout main

# Stash geri al (varsa)
if [ "$STASHED" -eq 1 ]; then
  echo "↩️ Restoring stashed changes..."
  git stash pop || echo "⚠️ Stash pop had conflicts; stash kept."
fi

echo "✅ Done!"