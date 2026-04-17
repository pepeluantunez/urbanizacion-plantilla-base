# Guia de Funcionamiento: Skills y Agentes

Fecha: 2026-04-14  
Proyecto: {{CODIGO_PROYECTO}} - {{NOMBRE_PROYECTO}}

## Que esta instalado

### Skills globales

- `command-creator`
- `session-handoff`
- `agent-md-refactor`
- `systematic-debugging`

Ubicacion: `C:\Users\USUARIO\.codex\skills\`

### Skills locales de plantilla

- `pou-viario`
- `dispatching-parallel-agents`
- `verification-before-completion`

Ubicacion: `.claude\skills\`

## Como funciona el sistema

1. `AGENTS.md` enruta la tarea por carril.
2. Se activa la skill local de plantilla si aplica.
3. Si la tarea encaja, se usan skills globales de soporte.
4. Se ejecutan scripts de control (`tools\...`) para cierre estricto.

## Tu forma de pedirlo

- "Pasa trazabilidad estricta."
- "Maqueta este anejo en estandar profesional."
- "Revisa tablas DOCX y coherencia con presupuesto."
- "Crea handoff de esta sesion."
- "Crea comando nuevo para [tarea repetitiva]."

## Nota

La plantilla debe adaptarse al proyecto nuevo antes de uso intensivo:

- revisar `AGENTS.md`
- revisar `CONFIG/trazabilidad_profiles.json`
- revisar `.claude/skills/`
- completar datos en `CONFIG/proyecto.template.json`
