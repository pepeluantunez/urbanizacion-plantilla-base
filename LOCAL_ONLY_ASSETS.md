# Local Only Assets

List heavy, unstable or external materials that should not enter normal Git history unless explicitly promoted.

## Default declarations

| Path | State | Reason |
|---|---|---|
| `PLANOS/` | `local-only` | CAD, PDF plots and references are often too heavy or unstable for normal Git history. |
| `BASES_PRECIOS/` | `externo` | Price bases are usually donor or third-party material and need explicit provenance. |
| `NORMATIVA/00_fuentes_pdf/` | `local-only` | Normative source PDFs are source material, not usually canonical repo content. |
| `DOCS/Documentos de Trabajo/1.- Reportaje Fotografico/` | `local-only` | Photo sets are usually heavy and operational. |
| `DOCS/Documentos de Trabajo/17.- Seguridad y Salud/PLANOS/RefExt/` | `local-only` | Reference files are support dependencies, not core source authority. |
| `PRESUPUESTO/ENTREGA_PRESTO_LIMPIA/` | `local-only` | Delivery packaging is generated output. |
| `PRESUPUESTO/IMPORTAR_PRESTO_SOLO_FINAL/` | `local-only` | Import/export helper folders are operational artifacts. |
| `PRESUPUESTO/INFORMES/` | `local-only` | Generated reports should only be versioned if promoted to authority. |

## Rule

If one of these paths becomes canonical for a project, document that decision explicitly in `ACTIVE_SOURCES.md`.

`NORMATIVA/01_texto_extraido/`, `NORMATIVA/02_indices/` and `NORMATIVA/03_matrices/` are different: they are derived knowledge layers and may be versioned when they improve project operability.
