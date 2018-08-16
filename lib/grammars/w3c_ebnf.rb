require 'grammar/dsl'

module Grammars
    # The W3C created its own, slightly different, version of EBNF for some unknown reason
    # https://www.w3.org/TR/REC-xml/#sec-notation
    module W3C_EBNF
	using Grammar::DSL

	Hexadecimal = concatenation('#x', /[0-9a-fA-F]+/)
	Character = alternation(Hexadecimal, /[ !"]/, /[\u{24}-\u{FFFF}]/)
	RangeCharacter = alternation(Hexadecimal, /[ !"]/, /[\u{24}-\u{5C}\u{5E}-\u{FFFF}]/)	# Character.except(']')
	Range = concatenation('[', alternation(RangeCharacter, concatenation(RangeCharacter, '-', RangeCharacter)).one_or_more, ']')
	NegatedRange = concatenation('[^', alternation(RangeCharacter, concatenation(RangeCharacter, '-', RangeCharacter)).one_or_more, ']')

	Character0 = /[a-zA-Z0-9_\[\]{}\(\)<>"=\|\.,;]+/		# Exclude single-quote
	Character1 = /[a-zA-Z0-9_\[\]{}\(\)<>'=\|\.,;]+/		# Exclude double-quote
	Terminal = alternation(concatenation("'", Character0, "'"), concatenation('"', Character1, '"'))

	Identifier = /[a-zA-Z][a-zA-Z0-9_]+/

	# rhs = #xN | Range | identifier | terminal | "(" , rhs , ")";
	concatenation :RHS do
	    alternation :Expression do
		element Hexadecimal
		element Identifier
		element Terminal
		element Range
		element NegatedRange
		element concatenation(Expression, /\s*-\s*/, Expression)
		element concatenation(Expression, /[\?\*\+]/)		# Repetition
		element concatenation('(', RHS, ')')			# Group
	    end

	    element List: concatenation(Expression, concatenation(/\s*/, Expression).any)
	    element concatenation(/\s*\|\s*/, List).any
	end

	# Rule = Identifier "::=" RHS
	Rule = concatenation(Identifier, /\s*::=\s*/, RHS, /\s*\n*/)

	Grammar = Rule.any
    end
end
