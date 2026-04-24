# KANBAN - {{CODIGO_PROYECTO}} {{NOMBRE_PROYECTO}}

Gestion ligera del trabajo. Sin burocracia.

## Regla minima

Cada item debe indicar:

- `owner`
- `prioridad`: `P1`, `P2` o `P3`
- `done`: prueba o control exigido para cerrarlo
- `bloqueo`: solo si existe

## Ready

- `[P1] Completar fuentes maestras del proyecto`
  owner: pendiente
  done: `FUENTES_MAESTRAS.md` deja claras las autoridades reales

- `[P1] Pasar trazabilidad de bootstrap a seed`
  owner: pendiente
  done: `CONTROL/trazabilidad/nodes.json` y `edges.json` contienen relaciones reales del proyecto

## In Progress

- vacio

## Blocked

- vacio

## Done

- `[P1] Repo nacido con contrato minimo y capa de trazabilidad bootstrap`
  owner: bootstrap
  done: el repo valida estructura y trazabilidad bootstrap sin errores
