.PHONY : all latex bibtex view nonstop clean distclean

TARGET=rasha19iros
SOURCE=$(TARGET).tex
NONSTOP=-interaction nonstopmode -halt-on-error -file-line-error

all:
	pdflatex $(SOURCE)
	bibtex $(TARGET)
	pdflatex $(SOURCE)
	pdflatex $(SOURCE)

latex:
	pdflatex $(SOURCE)
	pdflatex $(SOURCE)

bibtex:
	bibtex $(TARGET)

view:
	open $(TARGET).pdf &

nonstop:
	max_print_line=1048576 pdflatex $(NONSTOP) $(SOURCE)
	bibtex $(TARGET)
	max_print_line=1048576 pdflatex $(NONSTOP) $(SOURCE)
	max_print_line=1048576 pdflatex $(NONSTOP) $(SOURCE)

clean:
	rm -f $(TARGET).aux $(TARGET).bbl $(TARGET).blg $(TARGET).log

distclean:clean
	rm -f $(TARGET).pdf
