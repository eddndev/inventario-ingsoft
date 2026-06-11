# Makefile -- diagramas (PlantUML) y documentos (LaTeX)
# Requiere: java + plantuml.jar, Graphviz (dot), TeX Live (latexmk, xelatex).

PLANTUML ?= java -jar $(HOME)/.local/lib/plantuml.jar
LATEXMK  ?= latexmk -xelatex -interaction=nonstopmode -halt-on-error
BUILD    := _build

PUML := $(wildcard datos/diagramas/*.puml) $(wildcard analisis/diagramas/cu-*.puml)
PNG  := $(PUML:.puml=.png)
SVG  := $(PUML:.puml=.svg)

.PHONY: all diagramas pdf clean
all: diagramas pdf

## diagramas: renderiza los .puml a PNG y SVG
diagramas: $(PNG) $(SVG)

%.png: %.puml
	$(PLANTUML) -tpng $<
%.svg: %.puml
	$(PLANTUML) -tsvg $<

## pdf: compila los documentos LaTeX a _build/
pdf: diagramas | $(BUILD)
	cd datos    && $(LATEXMK) -output-directory=../$(BUILD) diccionario-de-datos.tex
	cd analisis && $(LATEXMK) -output-directory=../$(BUILD) casos-de-uso.tex

$(BUILD):
	mkdir -p $(BUILD)

## clean: elimina PDFs y diagramas generados
clean:
	rm -rf $(BUILD)
	rm -f datos/diagramas/*.png datos/diagramas/*.svg
	rm -f analisis/diagramas/cu-*.png analisis/diagramas/cu-*.svg
