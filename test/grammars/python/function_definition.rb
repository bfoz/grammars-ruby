RSpec.shared_examples 'Python::FunctionDefinition' do
    it 'must parse a simple function definition' do
	expect(parser.parse("def foo():\n    pass")).to eq([
	    Grammars::Python::Statement.new(
		Grammars::Python::Statement::FunctionDefinition.new(
		    nil, "def", " ", "foo", "(", nil, ")", nil, ":",
		    Grammars::Python::Block.new([
			Grammars::Python::Block.last.grammar.new(
			    "\n    ",
			    Grammars::Python::Statement.new(
				Grammars::Python::Statement::Simple.new(
				    Grammars::Python::SmallStatement.new(
					Grammars::Python::SmallStatement::Pass
				    ),
				    [],
				    nil
				)
			    )
			)
		    ])
		)
	    )
	])
    end

    it 'must parse a simple multi-statement function definition' do
	expect(parser.parse("def foo():\n    pass\n    return")).to eq([
	    Grammars::Python::Statement.new(
		Grammars::Python::Statement::FunctionDefinition.new(
		    nil, "def", " ", "foo", "(", nil, ")",
		    nil,
		    ":",
		    Grammars::Python::Block.new([
			Grammars::Python::Block.last.grammar.new(
			    "\n    ",
			    Grammars::Python::Statement.new(
				Grammars::Python::Statement::Simple.new(
				    Grammars::Python::SmallStatement.new(
					Grammars::Python::SmallStatement::Pass
				    ),
				    [],
				    nil
				)
			    ),
			),
			Grammars::Python::Block.last.grammar.new(
			    "\n    ",
			    Grammars::Python::Statement.new(
				Grammars::Python::Statement::Simple.new(
				    Grammars::Python::SmallStatement.new(
					Grammars::Python::SmallStatement::Return.new('return', nil)
				    ),
				    [],
				    nil
				)
			    ),
			)
		    ])
		)
	    )
	])
    end

    it 'must parse a multi-statement function definition' do
	expect(parser.parse("def foo():\n    pass\n    \n    return")).to eq([
	    Grammars::Python::Statement.new(
		Grammars::Python::Statement::FunctionDefinition.new(
		    nil, "def", " ", "foo", "(", nil, ")",
		    nil,
		    ":",
		    Grammars::Python::Block.new([
			Grammars::Python::Block.last.grammar.new(
			    "\n    ",
			    Grammars::Python::Statement.new(
				Grammars::Python::Statement::Simple.new(
				    Grammars::Python::SmallStatement.new(
					Grammars::Python::SmallStatement::Pass
				    ),
				    [],
				    nil
				)
			    ),
			),
			Grammars::Python::Block.last.grammar.new(
			    "\n    ",
			    nil,
			),
			Grammars::Python::Block.last.grammar.new(
			    "\n    ",
			    Grammars::Python::Statement.new(
				Grammars::Python::Statement::Simple.new(
				    Grammars::Python::SmallStatement.new(
					Grammars::Python::SmallStatement::Return.new('return', nil)
				    ),
				    [],
				    nil
				)
			    ),
			)
		    ])
		)
	    )
	])
    end

    it 'must parse a function definition that has multiple compound statements' do
    	expect(parser.parse("def foo():\n    if a:\n        pass\n    if b:\n        pass")).to eq([
	    Grammars::Python::Statement.new(
		Grammars::Python::Statement::FunctionDefinition.new(
		    nil, "def", " ", "foo", "(", nil, ")",
		    nil,
		    ":",
		    Grammars::Python::Block.new([
			Grammars::Python::Block.last.grammar.new(
			    "\n    ",
			    Grammars::Python::Statement.new(
				Grammars::Python::Statement::If.new(
				    'if',
				    ' ',
				    'a',
				    ':',
				    Grammars::Python::Block.new([
					 Grammars::Python::Block.last.grammar.new(
					    "\n        ",
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
			    ),
			),
			Grammars::Python::Block.last.grammar.new(
			    "\n    ",
			    Grammars::Python::Statement.new(
				Grammars::Python::Statement::If.new(
				    'if',
				    ' ',
				    'b',
				    ':',
				    Grammars::Python::Block.new([
					 Grammars::Python::Block.last.grammar.new(
					    "\n        ",
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
			    ),
			)
		    ])
		)
	    )
	])
    end

    it 'must parse a function definition that has positional parameters' do
	expect(parser.parse("def foo(a):\n    pass")).to eq([
	    Grammars::Python::Statement.new(
		Grammars::Python::Statement::FunctionDefinition.new(
		    nil, "def", " ", "foo", "(",
		    Grammars::Python::FunctionParameters.new(
			Grammars::Python::FunctionParameter.new(
			    Grammars::Python::FunctionParameter::PlainName.new('a', nil)
			),
			[],
			''
		    ),
		    ")",
		    nil,
		    ":",
		    Grammars::Python::Block.new([
			Grammars::Python::Block.last.grammar.new(
			    "\n    ",
			    Grammars::Python::Statement.new(
				Grammars::Python::Statement::Simple.new(
				    Grammars::Python::SmallStatement.new(
					Grammars::Python::SmallStatement::Pass
				    ),
				    [],
				    nil
				)
			    )
			)
		    ])
		)
	    )
	])
    end

    it 'must parse a function definition that has rest-parameters' do
	expect(parser.parse("def foo(a, b, *c, **d):\n    pass")).to eq([
	    Grammars::Python::Statement.new(
		Grammars::Python::Statement::FunctionDefinition.new(
		    nil, "def", " ", "foo", "(",
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
		    ")",
		    nil,
		    ":",
		    Grammars::Python::Block.new([
			Grammars::Python::Block.last.grammar.new(
			    "\n    ",
			    Grammars::Python::Statement.new(
				Grammars::Python::Statement::Simple.new(
				    Grammars::Python::SmallStatement.new(
					Grammars::Python::SmallStatement::Pass
				    ),
				    [],
				    nil
				)
			    )
			)
		    ])
		)
	    )
	])
    end

    it 'must parse a function definition that returns nothing' do
	expect(parser.parse("def foo():\n    return")).to eq [
	Grammars::Python::Statement.new(
		Grammars::Python::Statement::FunctionDefinition.new(
		    nil, "def", " ", "foo", "(", nil, ")", nil, ":",
		    Grammars::Python::Block.new([
			Grammars::Python::Block.last.grammar.new(
			    "\n    ",
			    Grammars::Python::Statement.new(
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
			    ),
			)
		    ])
		)
	    )
	]
    end

    it 'must parse a function definition that returns an integer literal' do
	expect(parser.parse("def foo():\n    return 42")).to eq [
	Grammars::Python::Statement.new(
		Grammars::Python::Statement::FunctionDefinition.new(
		    nil, "def", " ", "foo", "(", nil, ")", nil, ":",
		    Grammars::Python::Block.new([
			Grammars::Python::Block.last.grammar.new(
			    "\n    ",
			    Grammars::Python::Statement.new(
				Grammars::Python::Statement::Simple.new(
				    Grammars::Python::SmallStatement.new(
					Grammars::Python::SmallStatement::Return.new(
					    'return',
					    Grammars::Python::SmallStatement::Return.last.grammar.new(
						' ',
						Grammars::Python::Expressions.new(
						    Grammars::Python::Expressions::Items.new(
							'42'
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
			    )
			)
		    ])
		)
	    )
	]
    end
end
