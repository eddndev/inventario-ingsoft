# inventario-ingsoft

Entregable de **análisis y diseño** para el *Sistema de Inventario con Punto de
Venta y Análisis Predictivo de Reabastecimiento* de la tienda de ropa
**Peterby's** — proyecto final de Ingeniería de Software (ESCOM-IPN).

El sistema es una aplicación de escritorio en **Python + PyQt6** con base de
datos **SQLite** y un módulo de predicción de reabastecimiento basado en
**Random Forest**. Este repositorio no contiene la aplicación, sino los
artefactos de ingeniería que la sustentan:

- **Base de datos** — esquema SQL refinado y documentado.
- **Diccionario de datos** — propósito de cada tabla y campo (PDF, LaTeX).
- **Casos de uso** — especificación derivada de los requerimientos (PDF, LaTeX).
- **Diagramas UML** — entidad-relación (DER) y casos de uso (PlantUML → PNG/SVG).

## Estructura

```
inventario-ingsoft/
├── database/
│   ├── schema.sql              # Esquema refinado (fuente de la BD)
│   └── migrations/             # Traduccion versionada del esquema
├── docs/
│   ├── datos/
│   │   ├── diccionario-de-datos.tex
│   │   └── diagramas/der.puml          # (+ PNG/SVG)
│   ├── analisis/
│   │   ├── casos-de-uso.tex
│   │   └── diagramas/*.puml            # (+ PNG/SVG)
│   └── _build/                 # PDFs compilados (no versionado)
├── CONVENTIONS.md              # Convenciones especificas del proyecto
└── referencias/                # Insumos originales (no versionado)
```

## Cómo compilar

Requisitos: TeX Live (`latexmk`, `xelatex`), Java + `plantuml.jar`, Graphviz (`dot`).

```bash
# Diagramas (PlantUML -> PNG y SVG)
make -C docs diagramas

# Documentos (LaTeX -> PDF en docs/_build)
make -C docs pdf

# Todo
make -C docs
```

> Los PDF compilados (diccionario de datos y casos de uso) se publican en la
> sección **[Releases](https://github.com/eddndev/inventario-ingsoft/releases)**
> del repositorio; las fuentes `.tex`/`.puml` se versionan aquí.

## Entregables principales

| Entregable | Fuente | Salida |
|---|---|---|
| Esquema de base de datos | `database/schema.sql` | — |
| Diccionario de datos | `docs/datos/diccionario-de-datos.tex` | `docs/_build/diccionario-de-datos.pdf` |
| Casos de uso | `docs/analisis/casos-de-uso.tex` | `docs/_build/casos-de-uso.pdf` |
| Diagrama DER | `docs/datos/diagramas/der.puml` | `der.png` / `der.svg` |
| Diagramas de casos de uso | `docs/analisis/diagramas/*.puml` | `*.png` / `*.svg` |
