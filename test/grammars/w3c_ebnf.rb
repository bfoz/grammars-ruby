require 'grammars/w3c_ebnf'

RSpec.describe Grammars::W3C_EBNF do
    subject(:parser) { Parsers::RecursiveDescent.new }

    it 'must parse an Identifier' do
	parser.push Grammars::W3C_EBNF::Identifier
	expect(parser.parse('identifier0')).to eq(['identifier0'])
    end

    it 'must parse an Expression with a single Identifier' do
	parser.push Grammars::W3C_EBNF::RHS::Expression
	expect(parser.parse('identifier0')).to eql(['identifier0'])
    end

    it 'must parse an Expression with two Identifiers' do
	parser.push Grammars::W3C_EBNF::RHS::List
	expect(parser.parse('identifier0 identifier1')).to eq([Grammars::W3C_EBNF::RHS::List.new('identifier0', [Grammars::W3C_EBNF::RHS::List[1].grammar.new(' ', 'identifier1')])])
    end

    it 'must parse a repeated Identifier' do
	parser.push Grammars::W3C_EBNF::RHS::Expression
	expect(parser.parse('identifier0*')).to eq([Grammars::W3C_EBNF::RHS::Expression.new('identifier0', [Grammars::W3C_EBNF::RHS::Expression[1].grammar.new('*')])])
    end

    it 'must parse a Unicode character range' do
	parser.push Grammars::W3C_EBNF::Range
	expect(parser.parse('[#x00-#xFF]')).to eq([
		Grammars::W3C_EBNF::Range.new(
			'[',
			[Grammars::W3C_EBNF::Range[1].grammar[1].new(
				Grammars::W3C_EBNF::Hexadecimal.new('#x', '00'),
				'-',
				Grammars::W3C_EBNF::Hexadecimal.new('#x', 'FF')
			)],
			']'
		)])
    end

    context 'Grammars::W3C_EBNF::RHS::Expression' do
	before :each do
	    parser.push Grammars::W3C_EBNF::RHS::Expression
	end

	it 'must parse an excluded repetition' do
	    expect(parser.parse("abc* - def")).to eq([
		Grammars::W3C_EBNF::RHS::Expression.new(
		    'abc',
		    [
			Grammars::W3C_EBNF::RHS::Expression[1].grammar[1].new('*'),
			Grammars::W3C_EBNF::RHS::Expression[1].grammar[0].new(
			    ' - ',
			    Grammars::W3C_EBNF::RHS::Expression.new('def', [])
			),
		    ]
		)
	    ])
	end

	it 'must parse a repeated exclusion' do
	    expect(parser.parse("abc - def*")).to eq([
		Grammars::W3C_EBNF::RHS::Expression.new(
		    'abc',
		    [
			Grammars::W3C_EBNF::RHS::Expression[1].grammar[0].new(
			    ' - ',
			    Grammars::W3C_EBNF::RHS::Expression.new(
				'def',
				[
				    Grammars::W3C_EBNF::RHS::Expression[1].grammar[1].new('*')
				]
			    )
			)
		    ]
		)
	    ])
	end
    end

    context 'Grammars::W3C_EBNF::RHS::List' do
	before :each do
	    parser.push Grammars::W3C_EBNF::RHS::List
	end

	it 'must parse a concatenation with a center exclusion' do
	    expect(parser.parse("abc def - uvw xyz")).to eq([
		Grammars::W3C_EBNF::RHS::List.new(
		    Grammars::W3C_EBNF::RHS::Expression.new('abc', []),
		    [
			Grammars::W3C_EBNF::RHS::List[1].grammar.new(
			    ' ',
			    Grammars::W3C_EBNF::RHS::Expression.new('def', [
				Grammars::W3C_EBNF::RHS::Expression[1].grammar[0].new(
				    ' - ',
				    Grammars::W3C_EBNF::RHS::Expression.new('uvw', []),
				)
			    ]),
			),
			Grammars::W3C_EBNF::RHS::List[1].grammar.new(
			    ' ',
			    Grammars::W3C_EBNF::RHS::Expression.new('xyz', []),
			)
		    ]
		)
	    ])
	end
    end

    context Grammars::W3C_EBNF::Rule do
	before :each do
	    parser.push Grammars::W3C_EBNF::Rule
	end

	it 'must parse a simple rule' do
	    parser.push Grammars::W3C_EBNF::Rule
	    expect(parser.parse("syntax ::= rule\n")).to eq([
		Grammars::W3C_EBNF::Rule.new(
			"syntax",
			' ::= ',
			Grammars::W3C_EBNF::RHS.new(
				Grammars::W3C_EBNF::RHS::List.new(
					Grammars::W3C_EBNF::RHS::Expression.new('rule', []),
					[]
				),
				[]
			),
			"\n"
		)
	    ])
	end

	it 'must parse an alternation rule' do
	    expect(parser.parse("rule ::= identifier0 | identifier1\n")).to eq([
		Grammars::W3C_EBNF::Rule.new(
			'rule',
			' ::= ',
			Grammars::W3C_EBNF::RHS.new(
				Grammars::W3C_EBNF::RHS::List.new(
					Grammars::W3C_EBNF::RHS::Expression.new('identifier0', []),
					[]
				),
				[Grammars::W3C_EBNF::RHS[1].grammar.new(
					' | ',
					Grammars::W3C_EBNF::RHS::List.new(
						Grammars::W3C_EBNF::RHS::Expression.new('identifier1', []),
						[]
					)
				)]
			),
			"\n"
		)
	])
	end

	it 'must parse an concatenation rule' do
	    expect(parser.parse("rule ::= identifier0 identifier1\n")).to eq([
		Grammars::W3C_EBNF::Rule.new(
			'rule',
			' ::= ',
			Grammars::W3C_EBNF::RHS.new(
				Grammars::W3C_EBNF::RHS::List.new(
					Grammars::W3C_EBNF::RHS::Expression.new('identifier0', []),
					[Grammars::W3C_EBNF::RHS::List[1].grammar.new(' ', Grammars::W3C_EBNF::RHS::Expression.new('identifier1', []))]
				),
				[]
			),
			"\n"
		)
	])
	end

	it 'must parse an alernation of concatenations' do
	    expect(parser.parse('rule ::= identifier0 identifier1 | identifier2 identifier3')).to eq([
		Grammars::W3C_EBNF::Rule.new(
			'rule',
			' ::= ',
			Grammars::W3C_EBNF::RHS.new(
				Grammars::W3C_EBNF::RHS::List.new(
					Grammars::W3C_EBNF::RHS::Expression.new('identifier0', []),
					[Grammars::W3C_EBNF::RHS::List[1].grammar.new(' ', Grammars::W3C_EBNF::RHS::Expression.new('identifier1', []))]
				),
				[Grammars::W3C_EBNF::RHS[1].grammar.new(
					' | ',
					Grammars::W3C_EBNF::RHS::List.new(
						Grammars::W3C_EBNF::RHS::Expression.new('identifier2', []),
						[Grammars::W3C_EBNF::RHS::List[1].grammar.new(' ', Grammars::W3C_EBNF::RHS::Expression.new('identifier3', []))]
					)
				)]
			),
			""
		)
	    ])
	end

	it 'must parse a recursive rule' do
	    expect(parser.parse("syntax ::= rule | rule syntax\n")).to eq([
		Grammars::W3C_EBNF::Rule.new(
			"syntax",
			' ::= ',
			Grammars::W3C_EBNF::RHS.new(
				Grammars::W3C_EBNF::RHS::List.new(
					Grammars::W3C_EBNF::RHS::Expression.new('rule', []),
					[]
				),
				[Grammars::W3C_EBNF::RHS[1].grammar.new(
					' | ',
					Grammars::W3C_EBNF::RHS::List.new(
						Grammars::W3C_EBNF::RHS::Expression.new('rule', []),
						[Grammars::W3C_EBNF::RHS::List[1].grammar.new(
							' ',
							Grammars::W3C_EBNF::RHS::Expression.new('syntax', []),
						)]
					),
				)]
			),
			"\n"
		)
	    ])
	end
    end
end
