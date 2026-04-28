# Sync Policy

## Purpose

This file defines what belongs to toolkit, what belongs to the template, and what must stay local to each project repo.

## Toolkit-owned

These items should be treated as reusable ecosystem authority and refreshed from `urbanizacion-toolkit` when needed:

- generic scripts and checks
- catalogs and schemas
- reusable automation wrappers
- ecosystem-wide policies

## Template-owned

These items are part of the bootstrap surface and should be curated here:

- initial repo structure
- default `.gitignore`
- starter checklists
- seed docs such as `ACTIVE_SOURCES.md` and `LOCAL_ONLY_ASSETS.md`
- project contract defaults copied into new repos

## Project-owned

These items must stay inside each project repo and are never authority for toolkit or template:

- live deliverables
- BC3 maestro of a specific expediente
- working annexes and active office files
- project-specific reports, audits and exports
- normative corpus outputs such as `NORMATIVA/01_texto_extraido/`, `NORMATIVA/02_indices/` and `NORMATIVA/03_matrices/`

## Hard rule

If a rule saves time in two or more projects without knowing project names, it should move to toolkit.

If a file is needed in every new repo before any project-specific editing starts, it belongs to the template.

If a file mentions a specific project code, route, annex or deliverable, it stays in the project repo.

If the file is a reusable extractor, search tool or policy for normativa, it belongs to toolkit; if it is the extracted corpus for one expediente, it belongs to the project.
