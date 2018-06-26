require 'grammar/dsl'

module Grammars
    # https://en.wikipedia.org/wiki/Backus-Naur_form
    module BNF
	using Grammar::DSL

	# <character>      ::= <letter> | <digit> | <symbol>
	# <letter>         ::= "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J" | "K" | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T" | "U" | "V" | "W" | "X" | "Y" | "Z" | "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x" | "y" | "z"
	# <digit>          ::= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
	# <symbol>         ::=  "|" | " " | "!" | "#" | "$" | "%" | "&" | "(" | ")" | "*" | "+" | "," | "-" | "." | "/" | ":" | ";" | ">" | "=" | "<" | "?" | "@" | "[" | "\" | "]" | "^" | "_" | "`" | "{" | "}" | "~"
	Character = /[a-zA-Z0-9 -!#-&(-\/:-@\[-`{-~]/	# Everything except single- and double-quotes

	# <character1>     ::= <character> | "'"
	Character1 = alternation(Character, "'")

	# <character2>     ::= <character> | '"'
	Character2 = alternation(Character, '"')

	# <literal>        ::= '"' <text1> '"' | "'" <text2> "'"
	# <text1>          ::= "" | <character1> <text1>
	# <text2>          ::= "" | <character2> <text2>
	Literal = concatenation('"', Character1.any, '"') | concatenation("'", Character2.any, "'")

	# <rule-char>      ::= <letter> | <digit> | "-"
	# <rule-name>      ::= <letter> | <rule-name> <rule-char>
	RuleName = /[a-zA-Z0-9-]*/

	# <term>           ::= <literal> | "<" <rule-name> ">"
	Terminal = Literal | concatenation('<', RuleName, '>')

	# <opt-whitespace> ::= " " <opt-whitespace> | ""
	OptWhitespace = /[ \t\f\v]*/

	# <list>           ::= <term> | <term> <opt-whitespace> <list>
	List = concatenation(Terminal, concatenation(OptWhitespace, Terminal).any)

	# <expression>     ::= <list> | <list> <opt-whitespace> "|" <opt-whitespace> <expression>
	Expression = concatenation(List, concatenation(OptWhitespace, /\|/, OptWhitespace, List).any)

	# <rule>           ::= <opt-whitespace> "<" <rule-name> ">" <opt-whitespace> "::=" <opt-whitespace> <expression> <line-end>
	# <line-end>       ::= <opt-whitespace> <EOL> | <line-end> <line-end>
	Rule = concatenation(/\s*/, '<', RuleName, '>', OptWhitespace, '::=', OptWhitespace, Expression, /( *\n)+/)

	# <syntax>         ::= <rule> | <rule> <syntax>
	Syntax = Rule.at_least(1)
    end
end