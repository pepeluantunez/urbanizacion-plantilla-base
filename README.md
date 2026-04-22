# Plantilla Base de Proyecto

Base reutilizable para arrancar nuevos proyectos sin copiar ruido.

## Contenido clave

- `AGENTS.md`
- `SYSTEM_RULES.md`
- `TASK_TYPES.md`
- `IGNORE_DEFAULTS.md`
- `MAPA_PROYECTO.md`
- `FUENTES_MAESTRAS.md`
- `DECISIONES_PROYECTO.md`
- `ESTADO_PROYECTO.md`
- `TRIAGE.md`
- `CHECKLISTS/`
- `CONFIG/`
- `scripts/`
- `tools/`

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