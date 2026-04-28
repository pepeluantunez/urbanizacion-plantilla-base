# Lecciones operativas — {{NOMBRE_PROYECTO}}

> Reglas derivadas de correcciones reales en este proyecto.
> Se leen al inicio de cualquier tarea no trivial.
> Después de cada corrección: añadir la regla antes de cerrar la sesión.
> Formato: regla → Por qué → Cómo aplicar.

---

## BC3 y codificación

**Regla: nunca escribir archivos BC3 con encoding UTF-8.**
Por qué: Presto lee BC3 en ANSI (Windows-1252 / latin-1). UTF-8 genera mojibake visible (Ã, â€", etc.).
Cómo aplicar: usar `encoding=bc3['encoding']` (latin-1) al escribir con bc3_tools como librería. Verificar con `tools/check_bc3_encoding.ps1` antes de cerrar.

**Regla: las referencias ~D a componentes usan el mismo sufijo # que los ~C.**
Por qué: inconsistencia # vs sin-# genera errores "COMPONENTE SIN ~C" en validate.
Cómo aplicar: tras merge o creación desde donor, ejecutar `bc3_tools.py validate`. Si el código referenciado no existe pero código+'#' sí existe, corregir la referencia.

**Regla: ejecutar recalc después de corregir referencias o estructura de BC3.**
Por qué: el capítulo raíz puede tener precio declarado desfasado tras cambios masivos.
Cómo aplicar: `bc3_tools.py recalc <archivo.bc3>` siempre tras modify masivo. Snapshot obligatorio antes.

---

## Gestión de archivos y repos

**Regla: antes de eliminar cualquier carpeta con contenido, moverla y verificar que la copia está completa.**
Por qué: borrar sin mover primero es irreversible.
Cómo aplicar: `cp -r` → verificar recuento de archivos → eliminar origen. Si el sandbox no tiene permisos, avisar al usuario.

**Regla: `shared-tools/` es la fuente canónica de bc3_tools.py, excel_tools.py y mediciones_validator.py.**
Por qué: si la copia local en `tools/` diverge, las herramientas quedan desincronizadas del ecosistema.
Cómo aplicar: ejecutar `tools/check_tools_sync.ps1` antes de tareas que usen las herramientas.

---

## Excel y mediciones

**Regla: nunca leer cantidades de un xlsx directamente — usar siempre `excel_tools.py`.**
Por qué: los Excel del proyecto tienen rangos de celdas combinadas. Leer sin la tool lleva a inventar cantidades.
Cómo aplicar: `python3 tools/excel_tools.py read <archivo.xlsx> --sheet=<hoja>`. Leer el CSV resultante.

---

## Cierre de tareas

**Regla: una tarea sobre BC3, DOCX o XLSX no se cierra sin verificación explícita.**
Cómo aplicar:
- BC3: `bc3_tools.py validate` + `check_bc3_encoding.ps1` + SHA256 actualizado en FUENTES_MAESTRAS
- DOCX/XLSX: control anti-mojibake (buscar Ã, Â, â€" en el XML interno)

---

## Auto-mejora

**Regla: después de cada corrección del usuario, añadir la regla derivada a este archivo antes de cerrar la sesión.**
Por qué: sin este registro, los mismos errores se repiten en sesiones futuras.
Cómo aplicar: causa raíz → regla en formato "Regla / Por qué / Cómo aplicar" → añadir aquí → confirmar al usuario.
