# Tools reutilizables

Esta carpeta contiene utilidades tecnicas compartidas entre proyectos.

Recomendaciones:

- Mantener `bin/` y `obj/` fuera de la plantilla base.
- Si se recompila una herramienta, versionar solo codigo fuente y scripts de build.
- Documentar en cada herramienta sus dependencias y modo de ejecucion.
- `build_normativa_corpus.ps1` convierte PDFs fuente locales en texto e indices versionables.
- `search_normativa_corpus.ps1` permite buscar rapido en el corpus ya extraido.
