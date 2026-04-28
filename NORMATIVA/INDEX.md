# Indice de normativa

## Capas

1. `00_fuentes_pdf/`
   - PDFs fuente.
   - `local-only` por defecto.

2. `01_texto_extraido/`
   - Texto extraido desde PDF.
   - Versionable y buscable.

3. `02_indices/`
   - Catalogos, aliases y resumentes curados.

4. `03_matrices/`
   - Cruces entre anejos, normas y evidencia.

## Flujo minimo

1. Copiar o enlazar PDFs en `00_fuentes_pdf/`.
2. Ejecutar:

```powershell
.\tools\build_normativa_corpus.ps1 -SourceRoot .\NORMATIVA\00_fuentes_pdf -NormativaRoot .\NORMATIVA
```

3. Buscar rapido:

```powershell
.\tools\search_normativa_corpus.ps1 -Query "Decreto 293/2009"
.\tools\search_normativa_corpus.ps1 -Query "PG-3 firme"
```

4. Usar `.\tools\check_normativa_scope.ps1` como guarda ligera sobre anejos.
