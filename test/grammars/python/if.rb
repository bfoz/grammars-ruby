RSpec.shared_examples 'Python::Statement::If' do
    it 'must match a simple conditional statement' do
	expect(parser.parse("if a:\n    pass")).to eq([
	    Grammars::Python::Statement.new(
		Grammars::Python::Statement::If.new(
		    'if',
		    'a',
		    ':',
		    Grammars::Python::Block.new([
			Grammars::Python::Block.last.grammar.new(
			    "\n    ",
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

    it 'must parse a nested conditional statement' do
    	expect(parser.parse("if a:\n    pass\n    if b:\n        pass")).to eq([
	    Grammars::Python::Statement.new(
		Grammars::Python::Statement::If.new(
		    'if',
		    'a',
		    ':',
		    Grammars::Python::Block.new([
			Grammars::Python::Block.last.grammar.new(
			    "\n    ",
			    Grammars::Python::Statement::Simple.new(
				Grammars::Python::SmallStatement.new('pass'),
				[],
				nil
			    )
			),
			Grammars::Python::Block.last.grammar.new(
			    "\n    ",
			    Grammars::Python::Statement.new(

				Grammars::Python::Statement::If.new(
				    'if',
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

			    )
			)
		    ]),
		    [],
		    nil
		)
	    )
	])
    end
end
