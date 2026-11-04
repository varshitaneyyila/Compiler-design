CC = gcc
FLEX = flex
BISON = bison

TARGET = stage2.exe

all: $(TARGET)

$(TARGET): parser.tab.c lex.yy.c
	$(CC) -o $(TARGET) parser.tab.c lex.yy.c

parser.tab.c parser.tab.h: parser.y
	$(BISON) -d -o parser.tab.c parser.y

lex.yy.c: lexer.l parser.tab.h
	$(FLEX) -o lex.yy.c lexer.l

run: $(TARGET)
	./$(TARGET) stage2.bcs output.txt
	@cat output.txt

test: $(TARGET)
	@for f in tests/*.bcs; do echo "===== $$f ====="; ./$(TARGET) "$$f" output.txt; cat output.txt; done

clean:
	rm -f $(TARGET) parser.tab.c parser.tab.h lex.yy.c output.txt

.PHONY: all run test clean