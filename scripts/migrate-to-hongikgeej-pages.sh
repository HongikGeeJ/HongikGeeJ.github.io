#!/bin/zsh
# After you create org HongikGeeJ in the browser, run this to get:
#   https://hongikgeej.github.io/
# (user/org root site via repo HongikGeeJ.github.io)
#
# Prerequisites:
#   - Logged in: gh auth status  (needs repo, workflow; admin:org helpful for org repos)
#   - Org exists: https://github.com/HongikGeeJ
# Run outside sandbox if keyring/auth fails: Terminal.app
set -euo pipefail
cd "$(dirname "$0")/.."

ORG="HongikGeeJ"
ROOT_REPO="HongikGeeJ.github.io"
TARGET="https://github.com/${ORG}/${ROOT_REPO}.git"
LIVE="https://hongikgeej.github.io/TeacherLogin/"

export PATH="${HOME}/.local/bin:${PATH}"

echo "==> Checking auth…"
gh auth status
LOGIN="$(gh api user --jq .login)"
echo "    as ${LOGIN}"

echo "==> Checking org ${ORG}…"
if ! gh api "orgs/${ORG}" --jq .login >/dev/null 2>&1; then
  echo ""
  echo "Org ${ORG} does not exist yet (or you lack access)."
  echo "Create it in the browser (API cannot create orgs on github.com):"
  echo "  1. Open https://github.com/account/organizations/new?plan=free"
  echo "  2. Organization name: HongikGeeJ"
  echo "  3. Contact email: yours"
  echo "  4. Choose Free → Create organization"
  echo "  5. Re-run this script"
  exit 1
fi
echo "    org OK"

echo "==> Ensuring repo ${ORG}/${ROOT_REPO}…"
if gh repo view "${ORG}/${ROOT_REPO}" >/dev/null 2>&1; then
  echo "    repo already exists"
else
  gh repo create "${ORG}/${ROOT_REPO}" --public --description "HongikGeeJ teacher portal (GitHub Pages root site)"
  echo "    created"
fi

echo "==> Pointing git remote 'github' at ${TARGET}"
if git remote get-url github >/dev/null 2>&1; then
  git remote set-url github "${TARGET}"
else
  git remote add github "${TARGET}"
fi
git remote -v | grep '^github'

echo "==> Pushing main → ${ORG}/${ROOT_REPO}"
git push -u github main

echo "==> Enabling GitHub Pages (Actions source)…"
# Prefer Actions-based Pages (matches .github/workflows/deploy-pages.yml)
gh api -X PUT "repos/${ORG}/${ROOT_REPO}/pages" \
  -H "Accept: application/vnd.github+json" \
  --input - <<<'{"build_type":"workflow"}' >/dev/null 2>&1 \
  || gh api -X POST "repos/${ORG}/${ROOT_REPO}/pages" \
    -H "Accept: application/vnd.github+json" \
    --input - <<<'{"build_type":"workflow"}' >/dev/null 2>&1 \
  || echo "    (If this failed: Settings → Pages → Source: GitHub Actions)"
gh api "repos/${ORG}/${ROOT_REPO}/pages" --jq '    build_type=\(.build_type) status=\(.status) url=\(.html_url)' 2>/dev/null || true

echo "==> Triggering deploy workflow…"
gh workflow run deploy-pages.yml -R "${ORG}/${ROOT_REPO}" || true

echo ""
echo "Done. Target LIVE URL (after Actions finishes ~1–2 min):"
echo "  ${LIVE}"
echo "  (root https://hongikgeej.github.io/ redirects to /TeacherLogin/)"
echo ""
echo "Optional: keep old chattarins/HongikGeeJLogin as archive, or transfer it:"
echo "  gh repo transfer chattarins/HongikGeeJLogin ${ORG}"
echo "Old path URL would then be: https://hongikgeej.github.io/HongikGeeJLogin/"
