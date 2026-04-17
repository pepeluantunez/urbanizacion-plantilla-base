# Validacion Demo del Bootstrap

Fecha de validacion: 2026-04-17

## Escenario probado

Arranque de proyecto demo desde la plantilla base:

- codigo: `999.0.1`
- nombre: `Proyecto Demo Bootstrap`
- cliente: `Demo Cliente`
- destino: `.codex_tmp/bootstrap-demo`

## Resultado

El bootstrap crea correctamente un proyecto nuevo y sustituye:

- `{{CODIGO_PROYECTO}}`
- `{{NOMBRE_PROYECTO}}`
- `{{CLIENTE}}`
- `{{FECHA_INICIO}}`
- `{{NOMBRE_CARPETA_PROYECTO}}`
- `{{REPO_PROYECTO}}`
- `{{WORKSPACE_CODEX}}`

## Controles aplicados

- ausencia de `*.pkt`
- ausencia de referencias residuales a `00_PLANTILLA_BASE`
- ausencia de referencias residuales a `535.2.2` y `Guadalmar`
- control rapido anti-mojibake sobre `.md`, `.json` y `.ps1`

## Ajustes realizados durante la validacion

- el bootstrap ahora usa como fuente el propio repo de plantilla
- el copiado se apoya en `CONFIG/bootstrap.copy-manifest.json`
- se corrigio la sobrescritura de directorios en `.claude/skills`
- se generalizaron guias, comandos rapidos, perfiles y skills que seguian demasiado ligadas al proyecto origen
