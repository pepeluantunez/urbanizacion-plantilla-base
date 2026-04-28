# New Project Checklist

1. Crear repo GitHub privado del expediente.
2. Clonar la plantilla base.
3. Rellenar `CONFIG/proyecto.template.json`.
4. Ejecutar `scripts/iniciar_proyecto_estandar.ps1`.
5. Si aplica, pasar `-ToolkitRepoPath` para instalar el toolkit reusable durante el bootstrap.
6. Revisar `AGENTS.md`, `SYNC_POLICY.md`, `ACTIVE_SOURCES.md` y `LOCAL_ONLY_ASSETS.md`.
7. Si hay lote normativo local, poblar `NORMATIVA/00_fuentes_pdf/` y ejecutar `tools/build_normativa_corpus.ps1`.
8. Si el toolkit se instalo, revisar `catalog/asset_policies.json` y usar `scripts/check_ecosystem_health.ps1` como gate estructural.
9. Confirmar `MANIFEST_VIGENCIA.md` inicial en `DOCS/` y `PRESUPUESTO/`.
10. Ejecutar `tools/check_repo_contract.ps1`.
11. Hacer primer commit de bootstrap.
