# Set up GitHub repo

## Create the repo on GitHub
- Go to: https://github.com/new
- Repository name: **formaestro**
- Public

## Push the code
```bash
git init
git add .
git commit -m "chore: seed formaestro 1.0.0"
git branch -M main
git remote add origin https://github.com/MarciohsjOliveira/formaestro.git
git push -u origin main
```

## Enable CI & Releases
- CI is already configured at `.github/workflows/ci.yml`
- Release automation is at `.github/workflows/release.yml` (Conventional Commits)
- Add Topics (Settings → General → Topics): `flutter`, `dart`, `forms`, `validation`, `state-management`
