# Comandos Rapidos de Estandarizacion

## 1) Cierre rapido flexible (iteracion)
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '.\tools\run_estandar_proyecto.ps1' -Paths @('.\DOCS\Documentos de Trabajo\<carpeta-anejo>\<documento.docx>','.\DOCS\Documentos de Trabajo\<carpeta-anejo>\<mediciones.xlsx>','.\PRESUPUESTO\<codigo>.bc3') -Modo flexible"
```

## 2) Cierre estricto final
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '.\tools\run_estandar_proyecto.ps1' -Paths @('.\DOCS\Documentos de Trabajo\<carpeta-anejo>\<documento.docx>','.\DOCS\Documentos de Trabajo\<carpeta-anejo>\<mediciones.xlsx>','.\PRESUPUESTO\<codigo>.bc3') -Modo estricto"
```

## 3) Cierre estricto + trazabilidad base
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '.\tools\run_estandar_proyecto.ps1' -Paths @('.\DOCS\Documentos de Trabajo\<carpeta-1>','.\DOCS\Documentos de Trabajo\<carpeta-2>','.\PRESUPUESTO\<codigo>.bc3') -Modo estricto -TraceProfile 'base_general'"
```

## 4) Trazabilidad por perfil
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_traceability_profile.ps1 -Profile base_general -StrictProfile
```

## 5) Trazabilidad por perfil y conceptos clave
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_traceability_profile.ps1 -Profile <perfil> -Needles "<codigo1>","<codigo2>" -StrictProfile
```

## 6) Guardar baseline de formulas Excel
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\check_excel_formula_guard.ps1 -Paths ".\DOCS\Documentos de Trabajo\<carpeta-anejo>\<mediciones.xlsx>" -WriteManifestPath ".\.codex_tmp\excel_formulas_before.json"
```

## 7) Verificar formulas Excel tras cambios
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\check_excel_formula_guard.ps1 -Paths ".\DOCS\Documentos de Trabajo\<carpeta-anejo>\<mediciones.xlsx>" -BaselineManifestPath ".\.codex_tmp\excel_formulas_before.json"
```

## 8) Autofix de captions de tablas DOCX + validacion
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\autofix_docx_captions.ps1 -Paths ".\DOCS\Documentos de Trabajo\<carpeta-anejo>\<documento.docx>" -CaptionPrefix "Tabla" -DefaultDescription "Descripcion"
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\check_docx_tables_consistency.ps1 -Paths ".\DOCS\Documentos de Trabajo\<carpeta-anejo>\<documento.docx>" -ExpectedFont "Montserrat" -EnforceFont 1 -RequireTableCaption 1
```

## 9) Trazabilidad estricta por bloque
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_traceability_profile.ps1 -Profile <perfil> -StrictProfile
```

## 10) Trazabilidad estricta global
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_traceability_profile.ps1 -Profile todo_integral -StrictProfile
```
