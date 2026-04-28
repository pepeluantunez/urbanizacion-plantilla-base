# CLAUDE.md — Plantilla base de obra civil (urbanizacion-plantilla-base)

> Este archivo es la autoridad de comportamiento de Claude Code para cualquier proyecto nacido de esta plantilla.
> Los proyectos concretos extienden estas reglas en su propio CLAUDE.md local.
> Las reglas globales del ecosistema viven en urbanizacion-toolkit. Este archivo no las repite: las aplica.

---

## Al arrancar cualquier sesion de trabajo

**1. Leer lecciones operativas del proyecto:**
`CONTROL/lecciones_operativas.md` — reglas derivadas de correcciones reales. Leer antes de cualquier tarea no trivial.

**2. Sincronizar scripts desde el toolkit:**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\sync_from_toolkit.ps1
```

Los scripts de `tools/` (bc3_tools.py, excel_tools.py, mediciones_validator.py) se sincronizan desde `urbanizacion-toolkit`.
No editar esos archivos directamente en este repo. Cualquier cambio va al toolkit primero.

**3. Auto-mejora obligatoria:**
Después de cada corrección del usuario, añadir la regla derivada a `CONTROL/lecciones_operativas.md` antes de cerrar la sesión.

---

## Plugin requerido

Este proyecto requiere el plugin **obra-civil** instalado en Claude Code.
Sin el plugin activo, los comandos de slash y los agentes especializados no estaran disponibles.
Verificar con `/list-plugins` o desde la configuracion de Claude Code.

---

## Reglas absolutas — sin excepciones

### BC3 y presupuesto

- **Prohibido escribir o editar BC3 a mano.** Toda modificacion de BC3 se hace exclusivamente a traves de `tools/bc3_tools.py`.
- **Las lineas `~M` (mediciones) son intocables** salvo que se ejecute con el flag `--allow-mediciones` explicitamente documentado en el encargo.
- Toda partida nueva o modificada debe quedar con codigo, nombre, descripcion, unidad, descompuesto, recursos enlazados, medicion y precio coherentes. No dejar `PRECIO PENDIENTE`, conceptos huerfanos ni mediciones mal arrastradas.
- Tras tocar un BC3, comprobar siempre las lineas `~C`, `~D`, `~T` y `~M` afectadas.
- Script de integridad obligatorio tras cualquier toque BC3: `tools\check_bc3_integrity.ps1`.

### Excel y mediciones

- **Usar `tools/excel_tools.py` para cualquier operacion sobre XLSX/XLSM.** No manipular los archivos Excel directamente desde scripts ad hoc.
- No sustituir formulas por valores. Snapshot previo obligatorio con `tools\check_excel_formula_guard.ps1` antes de editar un Excel existente.
- Si se crea un Excel de mediciones o trazabilidad, partir de plantilla del proyecto y mantener tipografia Montserrat.

### Codificacion y mojibake

- Ninguna tarea sobre DOCX, XLSX, XML Office o BC3 se da por terminada sin verificacion de mojibake.
- Secuencias prohibidas en entrega: `Ã`, `Â`, `â€"`, `â€œ`, `Ã'`, `Ã"`, `COMPROBACIÃ"N`, `URBANIZACIÃ"N` u equivalentes.
- Script de verificacion: `tools\check_office_mojibake.ps1`.

### DOCX

- Tablas visibles, legibles y coherentes. No se admite tabla vacia, oculta o desalineada.
- Tipografia Montserrat en contenido nuevo o normalizado.
- Verificar con `tools\check_docx_tables_consistency.ps1` tras editar tablas.
- Toda tabla tecnica lleva numeracion y descripcion: formato `Tabla N. Descripcion`.

### Cierre obligatorio de cada tarea

1. Segunda pasada de control cruzado.
2. Coherencia entre calculo, tablas, mediciones y presupuesto.
3. Verificacion anti-mojibake antes de responder al usuario.
4. No responder "terminado" sin indicar que control final se ejecuto y si hubo incidencias.

---

## Estructura de carpetas esperada del proyecto

```
PROYECTO/
├── CLAUDE.md                        ← autoridad local (extiende este archivo)
├── AGENTS.md                        ← reglas de agentes (sincronia con toolkit)
├── README.md
├── MAPA_PROYECTO.md
├── FUENTES_MAESTRAS.md
├── DECISIONES_PROYECTO.md
├── ESTADO_PROYECTO.md
├── new-project.ps1                  ← bootstrap para clonar esta plantilla
├── CONFIG/
│   ├── project_identity.json
│   ├── toolkit.lock.json
│   ├── repo_contract.json
│   ├── proyecto.template.json
│   ├── bootstrap.copy-manifest.json
│   └── trazabilidad_profiles.json
├── PLANNING/
│   └── KANBAN.md
├── CHECKLISTS/
│   ├── 01_INICIO.md
│   ├── 02_CONTROL_CALIDAD.md
│   └── 03_CIERRE.md
├── CONTROL/
│   └── trazabilidad/
│       ├── README.md
│       ├── nodes.json
│       ├── edges.json
│       └── coverage.json
├── CONTROL_CALIDAD/
│   └── registro_cambios.md
├── DOCS - MEMORIA/
├── DOCS - ANEJOS/
│   └── Plantillas/
├── PLANOS/
├── tools/                           ← scripts sincronizados desde urbanizacion-toolkit
│   ├── sync_from_toolkit.ps1        ← sincronizar antes de empezar
│   ├── bc3_tools.py                 ← UNICO punto de edicion BC3
│   ├── excel_tools.py               ← UNICO punto de edicion Excel
│   ├── mediciones_validator.py
│   ├── check_bc3_integrity.ps1
│   ├── check_excel_formula_guard.ps1
│   ├── check_office_mojibake.ps1
│   ├── check_docx_tables_consistency.ps1
│   ├── check_traceability_consistency.ps1
│   ├── run_traceability_profile.ps1
│   ├── run_project_closeout.ps1
│   └── run_estandar_proyecto.ps1
└── scripts/
    └── iniciar_proyecto_estandar.ps1
```

Carpetas que NO se revisan salvo peticion expresa: `_archive/`, `scratch/`, `.codex_tmp/`.

---

## Scripts de tools/ — referencia rapida

| Script | Cuando usarlo |
|---|---|
| `sync_from_toolkit.ps1` | Al arrancar sesion; sincroniza py y ps1 desde toolkit |
| `bc3_tools.py` | Toda edicion de BC3 — nunca editar BC3 a mano |
| `excel_tools.py` | Toda operacion sobre XLSX/XLSM |
| `mediciones_validator.py` | Validar mediciones antes de cerrar partidas |
| `check_bc3_integrity.ps1` | Post-edicion BC3 obligatorio |
| `check_excel_formula_guard.ps1` | Snapshot previo y verificacion post-edicion Excel |
| `check_office_mojibake.ps1` | Verificacion final anti-mojibake Office |
| `check_docx_tables_consistency.ps1` | Control de tablas y tipografia en DOCX |
| `check_traceability_consistency.ps1` | Coherencia transversal entre piezas del proyecto |
| `run_traceability_profile.ps1` | Trazabilidad por perfil oficial |
| `run_project_closeout.ps1` | Cierre mixto: Office + BC3 + trazabilidad |
| `run_estandar_proyecto.ps1` | Pipeline unico recomendado para cierre completo |

---

## Enrutado por tipo de tarea

- **DOCX / XLSX / PPTX / XML Office**: carril documental. Editar lo minimo, verificar contenido modificado, ejecutar anti-mojibake.
- **Maquetacion**: carril maquetacion. Consistencia visual, tipografia Montserrat, control de tablas Word, preservacion de formulas Excel.
- **BC3 / PZH / presupuesto**: carril BC3. Modificar con bc3_tools.py, revisar `~C ~D ~T ~M`, ejecutar integridad.
- **Pluviales / SSA**: carril pluviales. Solo el tramo necesario, contrastar fuente, cierre cruzado contra mediciones y BC3.
- **Tarea mixta**: separar capas (documental / BC3 / trazabilidad) y cerrar cada una con su control antes de responder.

---

## Perfiles oficiales de trazabilidad

- `base_general`: BC3 + auditoria + anejo 4 + mediciones auxiliares + matriz trazabilidad.
- `pluviales_fecales`: BC3 + auditoria + anejos 7 y 8 + reportes CSV trazables.
- `control_calidad_plan_obra`: BC3 + auditoria + anejos 14 y 15 + SyS (anejo 17).
- `residuos_sys`: BC3 + auditoria + anejo 13 + Excel GR + BC3 SyS + anejo 17.
- `todo_integral`: cierre global transversal (anejos 4, 7, 8, 13, 14, 15, 17 + BC3 + auditoria).

Ejecucion:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_traceability_profile.ps1 -Profile "base_general" -StrictProfile
```

---

## Protocolo de ahorro de contexto

- Clasificar la tarea en su carril y ejecutar el cierre minimo, no replantear el flujo entero cada vez.
- Priorizar scripts antes de revision libre larga.
- El agente que edita no se autoaprueba. Control final siempre, aunque sea breve.
