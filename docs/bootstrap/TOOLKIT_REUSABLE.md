# Integracion del Toolkit Reusable

La plantilla base puede arrancar un proyecto nuevo e instalar a la vez el contenido publicado en `urbanizacion-toolkit`.

## Cuando usarlo

- cuando el proyecto nuevo deba nacer con el catalogo reusable ya sincronizado
- cuando quieras separar plantilla base y toolkit para poder actualizar cada capa por su cuenta
- cuando el expediente vaya a heredar verificadores y scripts comunes sin copiar el historial de otro proyecto

## Comando recomendado

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\iniciar_proyecto_estandar.ps1 `
  -CodigoProyecto "999.0.1" `
  -NombreProyecto "Proyecto Demo Bootstrap" `
  -RutaDestinoRaiz ".\.codex_tmp\bootstrap-demo" `
  -Cliente "Demo Cliente" `
  -RepoProyecto "pepeluantunez/proyecto-demo-bootstrap" `
  -WorkspaceCodex "C:\Workspaces\proyecto-demo-bootstrap" `
  -ToolkitRepoPath "C:\Repos\urbanizacion-toolkit"
```

## Resultado esperado

- el proyecto se crea con la estructura curada de la plantilla
- se sustituyen los tokens del expediente
- se instalan `tools/`, `scripts/` y `catalog/` desde el toolkit reusable
- queda disponible `catalog/CATALOG.md` como inventario inicial de automatizaciones compartidas

## Validacion minima tras el bootstrap

1. abrir `CONFIG/proyecto.template.json`
2. comprobar que existe `catalog/CATALOG.md`
3. revisar que `tools/` contiene los verificadores esperados
4. hacer el primer commit del bootstrap ya con toolkit instalado
