require 'grammars/ebnf'

RSpec.describe 'EBNF' do
    subject(:parser) { Parsers::RecursiveDescent.new }

    def create_identifier_match(name, location:nil)
	first_letter = name[0]
	the_rest = name[1..-1].chars.map.with_index {|c, i| Grammars::EBNF::Identifier[1].grammar.new(c, location:(location&.+i&.+1)) }
	Grammars::EBNF::Identifier.new(first_letter, the_rest, location:location)
    end

    def create_terminal_match(text, location:nil)
	Grammars::EBNF::RHS::Expression.new(
	    Grammars::EBNF::Terminal.new(
		Grammars::EBNF::Terminal[1].new('"', text.chars.map.with_index {|a, i| Grammars::EBNF::Character1.new(a, location:(location&.+i&.+1))}, '"', location:location),
		location:location
	    ),
	    location:location
	)
    end

    context Grammars::EBNF::Rule do
	before :each do
	    parser.push Grammars::EBNF::Rule
	end

	it 'must parse a simple rule' do
	    expect(parser.parse('rule = lhs ;')).to eq([
		Grammars::EBNF::Rule.new(
		    create_identifier_match('rule', location:0),
		    ' = ',
		    Grammars::EBNF::RHS.new(	# A Concatenation of an Alternation and a Repetition
			Grammars::EBNF::RHS[0].new(create_identifier_match('lhs'), []),
			[]
		    ),
		    ' ;',
		)
	    ])
	end

	it 'must parse an alternation rule' do
	    expect(parser.parse('rule = lhs | rhs | "foo" ;')).to eq([
		Grammars::EBNF::Rule.new(
		    create_identifier_match('rule', location:0),
		    ' = ',
		    Grammars::EBNF::RHS.new(	# A Concatenation of an Alternation and a Repetition
			Grammars::EBNF::RHS::List.new(
			    create_identifier_match('lhs', location:7),
			    [],
			    location:7
			),
			[Grammars::EBNF::RHS[1].grammar.new(
			    ' | ',
			     Grammars::EBNF::RHS::List.new(create_identifier_match('rhs'), []),
			 ),
			 Grammars::EBNF::RHS[1].grammar.new(
			    ' | ',
			     Grammars::EBNF::RHS::List.new(create_terminal_match('foo'), [])
			 )
			],
		    ),
		    ' ;',
		)
	    ])
	end

	it 'must parse a concatenation rule' do
	    expect(parser.parse('rule = lhs , "=" , rhs , ";" ;')).to eq([
		Grammars::EBNF::Rule.new(
		    create_identifier_match('rule', location:0),
		    ' = ',
		    Grammars::EBNF::RHS.new(	# A Concatenation of an Alternation and a Repetition
			Grammars::EBNF::RHS::List.new(
			    create_identifier_match('lhs', location:7),
			    [Grammars::EBNF::RHS::List[1].grammar.new(' , ', create_terminal_match('=', location:13), location:10),
			     Grammars::EBNF::RHS::List[1].grammar.new(' , ', create_identifier_match('rhs', location:19), location:16),
			     Grammars::EBNF::RHS::List[1].grammar.new(' , ', create_terminal_match(';', location:25), location:22)
			    ],
			    location:7
			),
			[],
			location:7
		    ),
		    ' ;',
		    location:0
		)
	    ])
	end

	it 'must parse a recursive rule' do
	    expect(parser.parse("syntax = rule | syntax ;")).to eq([
		Grammars::EBNF::Rule.new(
		    create_identifier_match("syntax"),
		    " = ",
		    Grammars::EBNF::RHS.new(
			Grammars::EBNF::RHS::List.new(
				create_identifier_match('rule'),
				[]
			),
			[Grammars::EBNF::RHS[1].grammar.new(
			    ' | ',
			    Grammars::EBNF::RHS::List.new(
				create_identifier_match('syntax'),
				[]
			    ),
			)]
		    ),
		    " ;"
		)
	    ])
	end
    end

end
