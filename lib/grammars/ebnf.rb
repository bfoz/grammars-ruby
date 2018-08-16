require 'grammar/dsl'

module Grammars
    # https://en.wikipedia.org/wiki/Extended_Backus-Naur_form
    module EBNF
	using Grammar::DSL

	# letter = "A" | "B" | "C" | "D" | "E" | "F" | "G"| "H" | "I" | "J" | "K" | "L" | "M" | "N"| "O" | "P" | "Q" | "R" | "S" | "T" | "U"| "V" | "W" | "X" | "Y" | "Z" | "a" | "b"| "c" | "d" | "e" | "f" | "g" | "h" | "i"| "j" | "k" | "l" | "m" | "n" | "o" | "p"| "q" | "r" | "s" | "t" | "u" | "v" | "w"| "x" | "y" | "z" ;
	Letter = /[a-zA-Z]/

	# digit = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ;
	Digit = /[0-9]/

	# symbol = "[" | "]" | "{" | "}" | "(" | ")" | "<" | ">" | "'" | '"' | "=" | "|" | "." | "," | ";" ;
	Symbol0 = /[\[\]{}\(\)<>"=\|\.,;]/
	Symbol1 = /[\[\]{}\(\)<>'=\|\.,;]/

	# character = letter | digit | symbol | "_" ;
	Character0 = alternation(Letter, Digit, Symbol0, "_")
	Character1 = alternation(Letter, Digit, Symbol1, "_")

	# identifier = letter , { letter | digit | "_" } ;
	Identifier = concatenation(Letter, (Letter | Digit | "_").at_least(0))

	# terminal = "'" , character , { character } , "'" | '"' , character , { character } , '"' ;
	Terminal = alternation(concatenation("'", Character0.at_least(1), "'"), concatenation('"', Character1.at_least(1), '"'))

	# rhs = identifier | terminal | "[" , rhs , "]" | "{" , rhs , "}" | "(" , rhs , ")" | rhs , "|" , rhs | rhs , "," , rhs ;
	concatenation :RHS do
	    alternation :Expression do
		element Identifier
		element Terminal
		element concatenation('[', RHS, ']')		# Optional-repeat group
		element concatenation('{', RHS, '}')		# Any-repeat group
		element concatenation('(', RHS, ')')		# Group
	    end

	    element List: concatenation(Expression, concatenation(/\s*,\s*/, Expression).any)
	    element concatenation(/\s*\|\s*/, List).any
	end

	#rule = lhs , "=" , rhs , ";" ;
	# lhs = identifier ;
	Rule = concatenation(Identifier, /\s*=\s*/, RHS, /\s*;(\s*\n)*/)

	#grammar = { rule } ;
	Grammar = Rule.any
    end
end
