#!/usr/bin/env bash
set -euo pipefail
git init
git add .
git commit -m "chore: seed formaestro 1.0.0"
git branch -M main
git remote add origin https://github.com/MarciohsjOliveira/formaestro.git
git push -u origin main
