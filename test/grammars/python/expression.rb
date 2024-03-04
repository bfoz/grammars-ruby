RSpec.shared_examples 'Python::Expression' do
    before :each do
	parser.push Grammars::Python::Expression
    end

    it 'must parse an AND expression' do
	expect(parser.parse('42&42')).to eq([Grammars::Python::Expression.new(
	    Grammars::Python::Expression[0].new(				# xor_expr
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
	    Grammars::Python::Expression[0].new(				# xor_expr
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
	    Grammars::Python::Expression[0].new(				# xor_expr
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
		    Grammars::Python::Expression[0][0].new(			# and_expr
			Grammars::Python::Expression[0][0][0].new(		# shift_expr
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
			    Grammars::Python::Expression[0][0].new(		# and_expr
				Grammars::Python::Expression[0][0][0].new(	# shift_expr
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
