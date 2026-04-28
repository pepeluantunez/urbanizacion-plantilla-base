# Plantilla Base de Proyecto

Base reutilizable para arrancar nuevos proyectos sin copiar ruido.

## Contenido clave

- `AGENTS.md`
- `MAPA_PROYECTO.md`
- `FUENTES_MAESTRAS.md`
- `DECISIONES_PROYECTO.md`
- `ESTADO_PROYECTO.md`
- `CHECKLISTS/`
- `CONFIG/`
- `CONTROL/trazabilidad/`
- `NORMATIVA/`
- `scripts/`
- `tools/`
- `docs/bootstrap/`

## Autoridad

La autoridad global de reglas reutilizables vive en `urbanizacion-toolkit`.

En esta plantilla solo deben quedar:

- estructura de arranque
- archivos maestros iniciales de proyecto
- bootstrap y documentacion de arranque
- contrato minimo para que un proyecto nazca limpio

No deben copiarse desde aqui reglas globales duplicadas como `SYSTEM_RULES.md`, `TASK_TYPES.md`, `TRIAGE.md` o `IGNORE_DEFAULTS.md`.

## Bootstrap

El arranque no copia toda la plantilla a ciegas.

- `scripts/iniciar_proyecto_estandar.ps1` lee `CONFIG/bootstrap.copy-manifest.json`
- se copian solo rutas curadas
- los archivos maestros salen ya preparados para rellenar

## Objetivo

Que un proyecto nuevo nazca con:

- frontera clara entre proyecto, plantilla y toolkit
- triage previo a lecturas profundas
- fuentes maestras y estado operativo desde el minuto uno
- seed minima de trazabilidad y cobertura desde el minuto uno
- base normativo consultable sin depender de abrir PDFs pesados en cada revision

## Guarda minima

El proyecto nuevo debe poder ejecutar localmente:

- `.\tools\check_machine_guard.ps1`
- `.\tools\update_project_foundation.ps1`

Esta guarda valida contrato de repo y alineacion entre obra, toolkit y plantilla. El bootstrap ya la ejecuta al final salvo que se use `-SkipMachineGuard`.

## Arranque recomendado

El comando de arranque ya admite:

- modo de trabajo: `ligero` o `estricto`
- perfil inicial de trazabilidad
- repo y workspace sugeridos automaticamente si no se pasan a mano

Despues del bootstrap, `update_project_foundation.ps1` deja `CONFIG\toolkit.lock.json` sellado con los commits reales de toolkit y plantilla.



