require 'grammars/python_v3.7.0'

RSpec.shared_examples 'a Python3 grammar' do
    subject(:parser) { Parsers::RecursiveDescent.new }

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

	it 'must parse a simple function definition' do
	    expect(parser.parse("def foo():\n    pass")).to eq([
		Grammars::Python::Statement.new(
		    Grammars::Python::Statement::FunctionDefinition.new(
			nil,
			"",
			"def",
			" ",
			"foo",
			"",
			"(",
			"",
			nil,
			"",
			")",
			nil,
			":",
			"",
			Grammars::Python::Statement::FunctionDefinition.last.new(
			    Grammars::Python::Statement::FunctionDefinition.last[1].new(
				"\n",
				"    ",
				[Grammars::Python::Statement.new(
			    	    Grammars::Python::Statement::Simple.new(
					Grammars::Python::SmallStatement.new(
					    Grammars::Python::SmallStatement::Pass
					),
					[],
					nil
				    )
				)],
				""
			    )
			)
		    )
		)
	    ])
	end

	it 'must parse a function definition that has positional parameters' do
	    expect(parser.parse("def foo(a):\n    pass")).to eq([
		Grammars::Python::Statement.new(
		    Grammars::Python::Statement::FunctionDefinition.new(
			nil,
			"",
			"def",
			" ",
			"foo",
			"",
			"(",
			"",
			Grammars::Python::FunctionParameters.new(
			    Grammars::Python::FunctionParameter.new(
				Grammars::Python::FunctionParameter::PlainName.new('a', nil)
			    ),
			    [],
			    ''
			),
			"",
			")",
			nil,
			":",
			"",
			Grammars::Python::Statement::FunctionDefinition.last.new(
			    Grammars::Python::Statement::FunctionDefinition.last[1].new(
				"\n",
				"    ",
				[Grammars::Python::Statement.new(
			    	    Grammars::Python::Statement::Simple.new(
					Grammars::Python::SmallStatement.new(
					    Grammars::Python::SmallStatement::Pass
					),
					[],
					nil
				    )
				)],
				""
			    )
			)
		    )
		)
	    ])
	end

	it 'must parse a function definition that has rest-parameters' do
	    expect(parser.parse("def foo(a, b, *c, **d):\n    pass")).to eq([
		Grammars::Python::Statement.new(
		    Grammars::Python::Statement::FunctionDefinition.new(
			nil,
			"",
			"def",
			" ",
			"foo",
			"",
			"(",
			"",
			Grammars::Python::FunctionParameters.new(
			    Grammars::Python::FunctionParameter.new(
				Grammars::Python::FunctionParameter::PlainName.new('a', nil),
			    ),
			    [
				Grammars::Python::FunctionParameters[1].grammar.new(
				    ', ',
				    Grammars::Python::FunctionParameter.new(
					Grammars::Python::FunctionParameter::PlainName.new('b', nil),
				    ),
				),
				Grammars::Python::FunctionParameters[1].grammar.new(
				    ', ',
				    Grammars::Python::FunctionParameter.new(
					Grammars::Python::FunctionParameter::StarName.new('*', Grammars::Python::FunctionParameter::PlainName.new('c', nil)),
				    ),
				),
				Grammars::Python::FunctionParameters[1].grammar.new(
				    ', ',
				    Grammars::Python::FunctionParameter.new(
					Grammars::Python::FunctionParameter::DoubleStarName.new('**', Grammars::Python::FunctionParameter::PlainName.new('d', nil))
				    ),
				)
			    ],
			    ''
			),
			"",
			")",
			nil,
			":",
			"",
			Grammars::Python::Statement::FunctionDefinition.last.new(
			    Grammars::Python::Statement::FunctionDefinition.last[1].new(
				"\n",
				"    ",
				[Grammars::Python::Statement.new(
			    	    Grammars::Python::Statement::Simple.new(
					Grammars::Python::SmallStatement.new(
					    Grammars::Python::SmallStatement::Pass
					),
					[],
					nil
				    )
				)],
				""
			    )
			)
		    )
		)
	    ])
	end

	context 'Function Definition' do
	    it 'must parse a function definition that returns nothing' do
		expect(parser.parse("def foo():\n    return")).to eq [
		Grammars::Python::Statement.new(
			Grammars::Python::Statement::FunctionDefinition.new(
			    nil,
			    "",
			    "def",
			    " ",
			    "foo",
			    "",
			    "(",
			    "",
			    nil,
			    "",
			    ")",
			    nil,
			    ":",
			    "",
			    Grammars::Python::Block.new(
				Grammars::Python::Block[1].new(
				    "\n",
				    "    ",
				    [Grammars::Python::Statement.new(
					Grammars::Python::Statement::Simple.new(
					    Grammars::Python::SmallStatement.new(
						Grammars::Python::SmallStatement::Return.new(
						    'return',
						    nil
						)
					    ),
					    [],
					    nil
					)
				    )],
				    ""
				)
			    )
			)
		    )
		]
	    end

	    it 'must parse a function definition that returns an integer literal' do
		expect(parser.parse("def foo():\n    return 42")).to eq [
		Grammars::Python::Statement.new(
			Grammars::Python::Statement::FunctionDefinition.new(
			    nil,
			    "",
			    "def",
			    " ",
			    "foo",
			    "",
			    "(",
			    "",
			    nil,
			    "",
			    ")",
			    nil,
			    ":",
			    "",
			    Grammars::Python::Block.new(
				Grammars::Python::Block[1].new(
				    "\n",
				    "    ",
				    [Grammars::Python::Statement.new(
					Grammars::Python::Statement::Simple.new(
					    Grammars::Python::SmallStatement.new(
						Grammars::Python::SmallStatement::Return.new(
						    'return',
						    Grammars::Python::SmallStatement::Return.last.grammar.new(
							' ',
							Grammars::Python::Expressions.new(
							    Grammars::Python::Expressions::Items.new(
								Grammars::Python::Expression.new(
								    Grammars::Python::Expression::BitwiseXor.new(
									Grammars::Python::BitwiseAnd.new(
									    Grammars::Python::BitwiseShift.new(
										Grammars::Python::Sum.new(
										    Grammars::Python::Term.new(
											Grammars::Python::Factor.new(
											    [],
											    Grammars::Python::Factor[1].new(
												Grammars::Python::Primary.new(
												    nil,
												    Grammars::Python::Atom.new('42'),
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
								)
							    ),
							    [],
							    nil
							)
						    )
						)
					    ),
					    [],
					    nil
					)
				    )],
				    ""
				)
			    )
			)
		    )
		]
	    end
	end
    end
end

RSpec.describe 'Python v3.7.0' do
    include_examples 'a Python3 grammar'
end
