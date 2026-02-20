JAVAC=javac
JFLEX=jflex

all: Token.class Lexer.class Scanner.class

%.class: %.java
	$(JAVAC) $^

Lexer.java: sgml.flex
	$(JFLEX) sgml.flex

clean:
	rm -f Lexer.java *.class *~
