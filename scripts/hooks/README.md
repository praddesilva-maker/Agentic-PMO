# Installing the pre-push hook

Git never tracks `.git/hooks/` directly, so the hook lives here and must be
pointed to explicitly. Not installed automatically — run one of these:

**Option A — repo-local hooksPath (recommended, keeps hook under version control):**

```sh
git config core.hooksPath scripts/hooks
```

**Option B — copy into .git/hooks (per-clone, no config change):**

```sh
cp scripts/hooks/pre-push .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

Either way, `chmod +x scripts/hooks/pre-push` must have been run at least once
(already done in this repo).
