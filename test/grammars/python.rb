require 'grammars/python_v3.7.0'

require_relative 'python/function_definition'

RSpec.shared_examples 'a Python3 grammar' do
    def arith_expr_number(number)
	Grammars::Python::Expression[0][0][0].first.new(							# arith_expr
	    Grammars::Python::Expression[0][0][0].first.first.new(						# term
		    Grammars::Python::Factor.new(								# factor
		    	[],
			Grammars::Python::Expression[0][0][0][0][0][0][1].new(					# power
			    Grammars::Python::Expression[0][0][0][0][0][0][1][0].new( 				# atom_expr
				nil,
				Grammars::Python::Expression[0][0][0][0][0][0][1][0][1].new(			# atom
				    number.to_s									# NUMBER
				),
				[]
			    ),
			    nil
			)
		    ),
		    []
	    ),
	    []
	)
    end

    context 'Expression' do
	before :each do
	    parser.push Grammars::Python::Expression
	end

	it 'must parse an AND expression' do
	    expect(parser.parse('42&42')).to eq([Grammars::Python::Expression.new(
		Grammars::Python::Expression[0].new(					# xor_expr
		    Grammars::Python::Expression[0][0].new(				# and_expr
			Grammars::Python::Expression[0][0][0].new(			# shift_expr
			    arith_expr_number('42'),
			    []
			),
			[
			    Grammars::Python::Expression[0][0][1].grammar.new(
			    	'&',
			    	Grammars::Python::Expression[0][0][0].new(		# shift_expr
				    arith_expr_number('42'),
				    []
				)
			    )
			]
		    ),
		    []
		),
		[]
	    )])
	end

	it 'must parse a shift expression' do
	    expect(parser.parse('42<<42')).to eq([Grammars::Python::Expression.new(
		Grammars::Python::Expression[0].new(					# xor_expr
		    Grammars::Python::Expression[0][0].new(				# and_expr
			Grammars::Python::Expression[0][0][0].new(			# shift_expr
			    arith_expr_number('42'),
			    [
				Grammars::Python::Expression[0][0][0].last.grammar.new(
				    '<<', 	# Alternation
				    arith_expr_number('42')
				)
			    ]
			),
			[]
		    ),
		    []
		),
		[]
	    )])
	end

	it 'must parse an XOR expression' do
	    expect(parser.parse('42^42')).to eq([Grammars::Python::Expression.new(
		Grammars::Python::Expression[0].new(					# xor_expr
		    Grammars::Python::Expression[0][0].new(				# and_expr
			Grammars::Python::Expression[0][0][0].new(			# shift_expr
			    arith_expr_number('42'),
			    []
			),
			[]
		    ),
		    [
			Grammars::Python::Expression[0][1].grammar.new(
			    '^',
			    Grammars::Python::Expression[0][0].new(			# and_expr
				Grammars::Python::Expression[0][0][0].new(		# shift_expr
				    arith_expr_number('42'),
				    []
				),
				[]
			    )
			)
		    ]
		),
		[]
	    )])
	end

	it 'must parse an OR expression' do
	    expect(parser.parse('42|42')).to eq([
		Grammars::Python::Expression.new(
		    Grammars::Python::Expression[0].new(				# xor_expr
			Grammars::Python::Expression[0][0].new(				# and_expr
			    Grammars::Python::Expression[0][0][0].new(			# shift_expr
				arith_expr_number('42'),
				[]
			    ),
			    []
			),
			[]
		    ),
		    [
			Grammars::Python::Expression[1].grammar.new(
			    '|',
			    Grammars::Python::Expression[0].new(			# xor_expr
				Grammars::Python::Expression[0][0].new(			# and_expr
				    Grammars::Python::Expression[0][0][0].new(		# shift_expr
					arith_expr_number('42'),
					[]
				    ),
				    []
				),
				[]
			    ),
			)
		    ]
		)
	    ])
	end
    end

    context 'Statement' do
	before :each do
	    parser.push Grammars::Python::Statement
	end

	it 'must match a simple if statement' do
	    expect(parser.parse("if a:\n    pass")).to eq([
		Grammars::Python::Statement.new(
		    Grammars::Python::Statement::If.new(
			'if',
			Grammars::Python::Expression.new(
			    Grammars::Python::Expression::BitwiseXor.new(
				Grammars::Python::BitwiseAnd.new(
				    Grammars::Python::BitwiseShift.new(
					Grammars::Python::Sum.new(
					    Grammars::Python::Term.new(
						Grammars::Python::Factor.new(
						    [],
						    Grammars::Python::Factor.last.new(
							Grammars::Python::Primary.new(
							    nil,
							    Grammars::Python::Atom.new('a'),
							    []
							),
							nil
						    )
						),
						[]
					    ),
					    []
					),
					[]
				    ),
				    []
				),
				[]
			    ),
			    []
			),
			':',
			Grammars::Python::Suite.new([
			    Grammars::Python::Block.new(
				"\n",
				'    ',
				Grammars::Python::Statement::Simple.new(
				    Grammars::Python::SmallStatement.new('pass'),
				    [],
				    nil
				)
			    )
			]),
			[],
			nil
		    )
		)
	    ])
	end

	include_examples "Python::FunctionDefinition"
    end
end

RSpec.describe 'Python v3.7.0' do
    subject(:parser) { Parsers::RecursiveDescent.new }

    include_examples 'a Python3 grammar'
end
