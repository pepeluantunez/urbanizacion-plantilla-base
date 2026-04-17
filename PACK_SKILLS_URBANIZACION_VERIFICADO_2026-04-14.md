# Pack de Skills y Agentes (Verificado)

Fecha: 2026-04-14  
Proyecto: {{CODIGO_PROYECTO}} - {{NOMBRE_PROYECTO}}

## Objetivo

Definir un pack corto, profesional y mantenible para proyectos de urbanizacion,
evitando instalar skills de mas y reduciendo trabajo repetitivo.

## Pack recomendado

1. Skill local `pou-viario`.
2. Skill local `dispatching-parallel-agents`.
3. Skill local `verification-before-completion`.
4. Flujo de trazabilidad por perfiles (`tools/run_traceability_profile.ps1`).
5. Pipeline estricto de cierre (`tools/run_estandar_proyecto.ps1`).

## Skills externas que si aportan

1. `skill-creator`
2. `session-handoff`
3. `command-creator`
4. `systematic-debugging`
5. `agent-md-refactor`

## Criterio de seguridad

- Cualquier skill comunitaria puede ejecutar codigo.
- Instalar solo lo necesario y revisar contenido antes de usar en produccion documental.
- Preferir skills oficiales y skills propias del ecosistema para trabajo critico.

## Plan de adopcion recomendado

### Fase 1

- Mantener el pack local de plantilla.
- Usar `session-handoff` y `command-creator` como apoyo.

### Fase 2

- Adaptar o ampliar skills locales segun el proyecto nuevo.
- Revisar si hace falta separar skills opcionales de las obligatorias.

## Referencias

- OpenAI Skills Catalog: https://github.com/openai/skills
- OpenAI Docs (skills en Codex): https://developers.openai.com/codex/skills
