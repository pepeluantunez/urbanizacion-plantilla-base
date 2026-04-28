# 04 POST BOOTSTRAP

1. Confirm `CONFIG/project_identity.json` is filled with the real project identity.
2. Confirm `CONFIG/toolkit.lock.json` points to the canonical sibling repos.
3. Review `CONFIG/repo_contract.json` and keep the default hard boundaries.
4. Replace placeholders in `ACTIVE_SOURCES.md`.
5. Review `LOCAL_ONLY_ASSETS.md` and keep or adjust only the project-relevant rows.
6. Confirm `.gitignore` already excludes `scratch/`, `_archive/` and local recovery material.
7. Run `tools/check_repo_contract.ps1`.
8. If toolkit has been synced, run the ecosystem health check from toolkit.
9. Make the first bootstrap commit only after the repo boundary is clean.
10. Do not copy toolkit or plantilla inside the project tree.
