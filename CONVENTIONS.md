# Convenciones del proyecto — inventario-ingsoft

Decisiones concretas de **este** repositorio. Parten de las convenciones
personales de ingeniería (el `CONVENTIONS.md` del directorio padre) y solo
añaden lo específico del proyecto: alcance, stack y esquema de datos. Ante
cualquier punto no cubierto aquí, aplica la convención global.

---

## 1. Alcance del repositorio

Este repositorio es el **entregable de análisis y diseño** para el "Sistema de
Inventario con Punto de Venta y Análisis Predictivo de Reabastecimiento" de la
tienda de ropa Peterby's (proyecto final de Ingeniería de Software, ESCOM-IPN).

Contiene, en concreto:

- **Base de datos**: esquema SQL refinado y diccionario de datos.
- **Análisis**: especificación de casos de uso y su trazabilidad con los
  requerimientos.
- **Diagramas UML**: entidad-relación (DER) y casos de uso.

No contiene el código fuente de la aplicación: ese sistema (Python + PyQt6) lo
desarrolla el equipo cliente por separado. El material original que sirve de
insumo (código y documento técnico) vive en `referencias/`, que **no se versiona**.

## 2. Stack del sistema documentado

- **Lenguaje**: Python 3.11.
- **Interfaz**: PyQt6 (escritorio, un solo punto de venta, operación local).
- **Base de datos**: SQLite (archivo local, sin servidor).
- **Módulo predictivo**: Random Forest (scikit-learn) sobre el historial de ventas.

## 3. Convenciones de datos del proyecto

Concretan la sección "Diseño de datos" de las convenciones globales:

- **Idioma del esquema**: los nombres de tablas y columnas van en **español sin
  acentos** (ASCII), porque son el dominio del negocio y deben coincidir con el
  código existente del equipo (p. ej. `productos`, `variantes_producto`,
  `fecha_creacion`). Esto respeta "el dominio en el idioma del negocio va en los
  datos", manteniéndolo en ASCII.
- **Tablas en plural**, clave primaria `id` (INTEGER AUTOINCREMENT).
- **Claves foráneas** con sufijo `_id`. Cuando el rol aclara la relación se
  permite un prefijo semántico (p. ej. `cajero_id` referenciando `usuarios`); se
  documenta en el diccionario.
- **Marcas de tiempo**: `fecha_creacion` en toda tabla con altas; además
  `fecha_actualizacion` en las entidades que se editan.
- **Catálogos de estado** con valores controlados mediante `CHECK` o tabla
  catálogo (estado de venta, rol de usuario, tipo de movimiento, método de pago).
- **El DER es la fuente de diseño**; `database/schema.sql` es su traducción 1:1.

## 4. Documentación

- Los entregables documentales se escriben en **LaTeX** y se compilan a PDF
  (formato profesional). Fuente en `.tex`, PDF en `docs/_build/` (no versionado;
  se adjunta en las entregas/releases).
- Texto en **español con acentos**; identificadores de datos en ASCII.
- Compilación: `latexmk -xelatex` (ver `docs/Makefile`).

## 5. Diagramas

- **PlantUML** como fuente versionable (`.puml`), renderizado a **PNG y SVG** con
  `plantuml.jar` (Graphviz `dot` para diagramas de casos de uso).
- Tipos: DER en `docs/datos/diagramas/`, casos de uso en
  `docs/analisis/diagramas/`.

## 6. Git

Igual que la convención global: `main` desplegable, commit génesis (README,
.gitignore, convenciones), después todo por rama (`docs/*`, `feat/*`, `fix/*`),
Conventional Commits en inglés y ASCII, integración por squash & merge.
