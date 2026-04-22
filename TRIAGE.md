# TRIAGE - {{CODIGO_PROYECTO}} {{NOMBRE_PROYECTO}}

> Selector minimo obligatorio antes de abrir demasiado proyecto.

## Plantilla minima

```text
Tipo de tarea:
Objetivo exacto:
Archivos a leer:
Archivos a ignorar:
Dependencias minimas:
Modo de trabajo:
Salida esperada:
```

## Modos

- `triage`: solo estructura y archivos maestros.
- `focalizado`: solo archivos implicados.
- `global`: solo si la tarea es auditoria o cierre transversal.

## Reglas de corte

- Si vas a leer mas de 5 rutas, explica por que.
- Si la tarea mezcla proyecto, plantilla y toolkit, separa por capa.
- Si no puedes definir una salida esperada concreta, no empieces aun.