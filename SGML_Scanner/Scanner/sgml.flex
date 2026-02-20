/*
  File Name: sgml.flex

  Purpose:
  JFlex specification for scanning SGML tagged documents.
  This scanner validates proper nesting of tags using a global stack,
  filters irrelevant SGML content, and tokenizes text inside relevant
  tags according to the requirements of the Warmup Assignment.
*/

import java.util.ArrayList;
   
%%
   
%class Lexer
%type Token
%line
%column
%unicode
 
%eofval{
  return null;
%eofval};

%{
  /*
    Stack used to validate proper nesting of SGML tags.
    Each open tag name is pushed onto the stack and matched
    against closing tags as they are encountered.
  */
  
  private static ArrayList<String> tagStack = new ArrayList<String>();

  /*
    List of tag names whose content is considered relevant
    and should be preserved in the output.
  */

  private static String[] relevantTags = {
    "doc", "text", "date", "docno", "headline", "length", "p"
  };

  //Checks whether a given tag name is considered relevant.

  private boolean isRelevantTag(String tag) {
    for (String t : relevantTags)
      if (t.equals(tag))
        return true;
    return false;
  }
  
  /*
    Determines whether all currently open tags on the stack
    are relevant. Text is only tokenized when this condition holds.
  */

  private boolean allRelevant() {
    for (String t : tagStack)
      if (!isRelevantTag(t))
        return false;
    return true;
  }

%}

LETTER   = [A-Za-z]
DIGIT    = [0-9]
TAGNAME  = {LETTER}({LETTER}|{DIGIT}|-)*
WS       = [ \t\r\n]+

alnum        = {LETTER}|{DIGIT}

sign         = [+-]?
integer      = {sign}{DIGIT}+
real         = {sign}{DIGIT}+"."{DIGIT}+
number       = {real}|{integer}

word         = {alnum}+

apostrophe   = \'|’
apostrophized = ({word}|{hyphenated})({apostrophe}{word})+

hyphen       = -
hyphenated   = {word}({hyphen}{word})+

punctuation  = [^A-Za-z0-9 \t\r\n]

%%

/* ---------- OPEN TAG ---------- 
  Recognizes open SGML tags.
  Extracts the tag name, pushes relevant tags onto the stack,
  and emits an OPEN-* token only when all enclosing tags are relevant.
*/

"<"{WS}*{TAGNAME}([^>])*">" {
  String raw = yytext();
  String tag = raw.replaceAll("[<>]", "").trim();
  tag = tag.split("\\s+")[0].toLowerCase();

  tagStack.add(tag);

  if (isRelevantTag(tag) && allRelevant()) {
    return new Token(Token.TAG, "OPEN-" + tag.toUpperCase(), yyline, yycolumn);
  }
}

/* ---------- CLOSE TAG ----------
  Recognizes closing SGML tags.
  Matches the tag against the top of the stack to validate nesting,
  reports mismatches, and emits a CLOSE-* token when appropriate.
*/

"</"{WS}*{TAGNAME}{WS}*">" {
  String raw = yytext();
  String tag = raw.replaceAll("[</>]", "").trim().toLowerCase();

  if (tagStack.isEmpty()) {
    System.err.println("ERROR: Unmatched closing tag: " + tag);
    return null;
  }

  String open = tagStack.remove(tagStack.size() - 1);

  if (!open.equals(tag)) {
    System.err.println(
      "ERROR: Tag mismatch: opened <" + open + "> closed </" + tag + ">"
    );
  }

  if (isRelevantTag(tag) && allRelevant()) {
    return new Token(Token.TAG, "CLOSE-" + tag.toUpperCase(), yyline, yycolumn);
  }
}

/*
  Tokenization rules applied only when all enclosing tags are relevant.
  These rules classify text into WORD, NUMBER, APOSTROPHIZED,
  HYPHENATED, and PUNCTUATION tokens.
*/

{apostrophized} {
  if (allRelevant())
    return new Token(Token.APOSTROPHIZED, yytext(), yyline, yycolumn);
}

{hyphenated} {
  if (allRelevant())
    return new Token(Token.HYPHENATED, yytext(), yyline, yycolumn);
}

{number} {
  if (allRelevant())
    return new Token(Token.NUMBER, yytext(), yyline, yycolumn);
}

{word} {
  if (allRelevant())
    return new Token(Token.WORD, yytext(), yyline, yycolumn);
}

{punctuation} {
  if (allRelevant())
    return new Token(Token.PUNCTUATION, yytext(), yyline, yycolumn);
}


/* ---------- IGNORE EVERYTHING ELSE ---------- */
[^] { /* ignore */ }

/* ---------- EOF ---------- 
  End of file handling.
  Reports any unmatched tags remaining on the stack after scanning completes.
*/
<<EOF>> {
  if (!tagStack.isEmpty()) {
   System.err.println("ERROR: Unmatched tags remaining on stack:");
   for (int i = tagStack.size() - 1; i >= 0; i--) {
      System.err.println("ERROR:   <" + tagStack.get(i) + ">");
   }
  }
  return null;
}
