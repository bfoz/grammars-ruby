require 'grammars/ebnf'

RSpec.describe 'EBNF' do
    subject(:parser) { Parsers::RecursiveDescent.new }

    it 'must parse a simple rule' do
	parser.push Grammars::EBNF::Rule
	expect(parser.parse('rule = lhs ;')).to eq([
	    Grammars::EBNF::Rule.new(
		Grammars::EBNF::Identifier.new('r', [Grammars::EBNF::Identifier[1].grammar.new('u'),
						     Grammars::EBNF::Identifier[1].grammar.new('l'),
						     Grammars::EBNF::Identifier[1].grammar.new('e')]),
		' = ',
		Grammars::EBNF::RHS.grammar.new(	# A Concatenation of an Alternation and a Repetition
		    Grammars::EBNF::RHS.grammar[0].new(
			Grammars::EBNF::Identifier.new('l', [Grammars::EBNF::Identifier[1].grammar.new('h'),
							     Grammars::EBNF::Identifier[1].grammar.new('s')])
		    ),

		    # The second element is the Repetition. The Repetition's element is an Alternation.
		    []
		),
		' ;',
	    )
	])
    end

    it 'must parse a single rule' do
	parser.push Grammars::EBNF::Rule
	expect(parser.parse('rule = lhs , "=" , rhs , ";" ;')).to eq([
	    Grammars::EBNF::Rule.new(
		Grammars::EBNF::Identifier.new('r', [Grammars::EBNF::Identifier[1].grammar.new('u'),
						     Grammars::EBNF::Identifier[1].grammar.new('l'),
						     Grammars::EBNF::Identifier[1].grammar.new('e')]),
		' = ',
		Grammars::EBNF::RHS.grammar.new(	# A Concatenation of an Alternation and a Repetition
		    Grammars::EBNF::RHS.grammar[0].new(
			Grammars::EBNF::Identifier.new('l', [Grammars::EBNF::Identifier[1].grammar.new('h'),
							     Grammars::EBNF::Identifier[1].grammar.new('s')])
		    ),

		    # The second element is the Repetition. The Repetition's element is an Alternation.
		    [Grammars::EBNF::RHS.grammar[1].grammar.new(
			Grammars::EBNF::RHS.grammar[1].grammar[1].new(
			    ' , ',				# The separator
			    Grammars::EBNF::RHS.grammar.new(	# The recursion, which is a Concatenation...
				Grammars::EBNF::RHS.grammar[0].new(	# The first element is an Alternation...
				    Grammars::EBNF::Terminal.new(	# Which is a Terminal in this case
					Grammars::EBNF::Terminal[1].new('"', [Grammars::EBNF::Character1.new('=')], '"')
				    )
				),
				# The second element is a Concatenation
				[Grammars::EBNF::RHS.grammar[1].grammar.new(
				    Grammars::EBNF::RHS.grammar[1].grammar[1].new(
					' , ',
					Grammars::EBNF::RHS.grammar.new(	# The recursion, which is a Concatenation...
					    Grammars::EBNF::RHS.grammar[0].new(	# The first element is an Alternation...
								Grammars::EBNF::Identifier.new('r', [Grammars::EBNF::Identifier[1].grammar.new('h'),
												     Grammars::EBNF::Identifier[1].grammar.new('s')]
								)
					    ),
					    [Grammars::EBNF::RHS.grammar[1].grammar.new(
						Grammars::EBNF::RHS.grammar[1].grammar[1].new(
						    ' , ',
						    Grammars::EBNF::RHS.grammar.new(	# The recursion, which is a Concatenation...
							Grammars::EBNF::RHS.grammar[0].new(	# The first element is an Alternation...
							    Grammars::EBNF::Terminal.new(	# Which is a Terminal in this case
								Grammars::EBNF::Terminal[1].new('"', [Grammars::EBNF::Character1.new(';')], '"')
							    )
							),
							[]
						    )
						)
					    )]
					)
				    )
				)]
			    )
			)
		    )]
		),
		' ;',
	    )
	])
    end
end
