# PDF compilados

Versiones compiladas de los entregables documentales. Se generan a partir de las
fuentes LaTeX con `make -C docs pdf` (o `make -C docs`) y se publican aquí.

| Archivo | Fuente | Contenido |
|---|---|---|
| `diccionario-de-datos.pdf` | `../datos/diccionario-de-datos.tex` | Propósito de cada tabla y campo (24 tablas) + DER. |
| `casos-de-uso.pdf` | `../analisis/casos-de-uso.tex` | 16 casos de uso + diagramas UML + trazabilidad RF→UC. |

> Artefactos generados: la fuente de verdad son los `.tex` y `.puml`. Si editas
> una fuente, vuelve a compilar (`make -C docs pdf`) para regenerar estos PDF.
