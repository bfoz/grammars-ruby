require 'grammars/python_v3.7.0'

require_relative 'python/expression'
require_relative 'python/function_definition'
require_relative 'python/if'

RSpec.shared_examples 'a Python3 grammar' do
    context 'Expression' do
	include_examples "Python::Expression"
    end

    context 'Statement' do
	before :each do
	    parser.push Grammars::Python::Statement
	end

	include_examples "Python::Statement::If"
	include_examples "Python::FunctionDefinition"
    end

    context 'Statements' do
	before :each do
	    parser.push Grammars::Python::Statements
	end

	it 'must parse multiple simple unindented statements' do
	    expect(parser.parse("pass\npass\n")).to eq([[
		Grammars::Python::Statements.grammar.new(
		    Grammars::Python::Statement.new(
			Grammars::Python::Statement::Simple.new(Grammars::Python::SmallStatement.new('pass'), [], nil),
		    )
		),
		Grammars::Python::Statements.grammar.new("\n"),
		Grammars::Python::Statements.grammar.new(
		    Grammars::Python::Statement.new(
			Grammars::Python::Statement::Simple.new(Grammars::Python::SmallStatement.new('pass'), [], nil),
		    )
		),
		Grammars::Python::Statements.grammar.new("\n"),
	    ]])
	end

	it 'must parse multiple simple unindented statements with blank lines' do
	    expect(parser.parse("pass\n\npass\n")).to eq([[
		Grammars::Python::Statements.grammar.new(
		    Grammars::Python::Statement.new(
			Grammars::Python::Statement::Simple.new(Grammars::Python::SmallStatement.new('pass'), [], nil),
		    )
		),
		Grammars::Python::Statements.grammar.new("\n"),
		Grammars::Python::Statements.grammar.new("\n"),
		Grammars::Python::Statements.grammar.new(
		    Grammars::Python::Statement.new(
			Grammars::Python::Statement::Simple.new(Grammars::Python::SmallStatement.new('pass'), [], nil),
		    )
		),
		Grammars::Python::Statements.grammar.new("\n"),
	    ]])
	end

	it 'must match multiple If statements' do
	    expect(parser.parse("if a:\n    pass\nif b:\n    pass")).to eq([
		[
		    Grammars::Python::Statements.grammar.new(
			Grammars::Python::Statement.new(
			    Grammars::Python::Statement::If.new(
				'if', ' ',
				'a',
				':',
				Grammars::Python::Block.new([
				    Grammars::Python::Block.last.grammar.new(
					"\n    ",
					Grammars::Python::Statement.new(
					    Grammars::Python::Statement::Simple.new(
						Grammars::Python::SmallStatement.new('pass'),
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
		    ),
		    Grammars::Python::Statements.grammar.new("\n"),
		    Grammars::Python::Statements.grammar.new(
			Grammars::Python::Statement.new(
			    Grammars::Python::Statement::If.new(
				'if', ' ',
				'b',
				':',
				Grammars::Python::Block.new([
				    Grammars::Python::Block.last.grammar.new(
					"\n    ",
					Grammars::Python::Statement.new(
					    Grammars::Python::Statement::Simple.new(
						Grammars::Python::SmallStatement.new('pass'),
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
		    )
		]
	    ])
	end

	it 'must parse multiple simple function definitions' do
	    expect(parser.parse("def foo():\n    pass\ndef bar():\n    pass\n")).to eq([
		[
		    Grammars::Python::Statements.grammar.new(
			Grammars::Python::Statement.new(
			    Grammars::Python::Statement::FunctionDefinition.new(
				nil, "def", " ", "foo", "(", nil, ")", nil, ":",
				Grammars::Python::Block.new([
				    Grammars::Python::Block.last.grammar.new(
					"\n    ",
					Grammars::Python::Statement.new(
					    Grammars::Python::Statement::Simple.new(
						Grammars::Python::SmallStatement.new('pass'),
						[],
						nil
					    )
					)
				    )
				]),
			    )
			)
		    ),
		    "\n",
		    Grammars::Python::Statements.grammar.new(
			Grammars::Python::Statement.new(
			    Grammars::Python::Statement::FunctionDefinition.new(
				nil, "def", " ", "bar", "(", nil, ")", nil, ":",
				Grammars::Python::Block.new([
				    Grammars::Python::Block.last.grammar.new(
					"\n    ",
					Grammars::Python::Statement.new(
					    Grammars::Python::Statement::Simple.new(
						Grammars::Python::SmallStatement.new('pass'),
						[],
						nil
					    )
					)
				    )
				]),
			    )
			)
		    ),
		    Grammars::Python::Statements.grammar.new("\n"),
		]
	    ])
	end

	it 'must parse multiple multi-statement function definitions' do
	    expect(parser.parse("def foo():\n    pass\n    return\ndef bar():\n    pass\n    return\n")).to eq([
		[
		    Grammars::Python::Statements.grammar.new(
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
					)
				    )
				])
			    )
			)
		    ),
		    "\n",
		    Grammars::Python::Statements.grammar.new(
			Grammars::Python::Statement.new(
			    Grammars::Python::Statement::FunctionDefinition.new(
				nil, "def", " ", "bar", "(", nil, ")", nil, ":",
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
					)
				    )
				])
			    )
			)
		    ),
		    Grammars::Python::Statements.grammar.new("\n"),
		]
	    ])
	end
    end
end

RSpec.describe 'Python v3.7.0' do
    subject(:parser) { Parsers::RecursiveDescent.new }

    include_examples 'a Python3 grammar'
end
