require 'grammars/python_v3.7.0'

RSpec.shared_examples 'a Python3 grammar' do
    subject(:parser) { Parsers::RecursiveDescent.new }

    def arith_expr_number(number)
	Grammars::Python::Expression[0][0][0].first.new(							# arith_expr
	    Grammars::Python::Expression[0][0][0].first.first.new(						# term
		    Grammars::Python::Expression[0][0][0][0][0][0].new(						# factor
			Grammars::Python::Expression[0][0][0][0][0][0][1].new(					# power
			    Grammars::Python::Expression[0][0][0][0][0][0][1][0].new( 				# atom_expr
				nil,
				Grammars::Python::Expression[0][0][0][0][0][0][1][0][1].new(			# atom
				    Grammars::Python::Expression[0][0][0][0][0][0][1][0][1][4].new(number.to_s)	# NUMBER
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
end

RSpec.describe 'Python v3.7.0' do
    include_examples 'a Python3 grammar'
end
