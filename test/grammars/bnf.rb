require 'grammars/bnf'

RSpec.describe 'BNF' do
    subject(:parser) { Parsers::RecursiveDescent.new }

    it 'must parse a simple rule' do
	parser.push Grammars::BNF::Rule
	expect(parser.parse("<syntax> ::= <rule>\n")).to eq([
		Grammars::BNF::Rule.new(
			"",
			"<",
			"syntax",
			">",
			" ",
			"::=",
			" ",
			Grammars::BNF::Expression.new(
				Grammars::BNF::List.new(
					Grammars::BNF::Terminal.new(
						Grammars::BNF::Terminal.elements[1].new("<", "rule", ">")
					),
					[]
				),
				[]
			),
			"\n"
		)
	])
    end

    it 'must parse a recursive rule' do
    	parser.push Grammars::BNF::Syntax
	expect(parser.parse("<syntax> ::= <rule> | <rule> <syntax>\n")).to eq([[
		Grammars::BNF::Rule.new(
			"",
			"<",
			"syntax",
			">",
			" ",
			"::=",
			" ",
			Grammars::BNF::Expression.new(
				Grammars::BNF::List.new(
					Grammars::BNF::Terminal.new(
						Grammars::BNF::Terminal.elements[1].new("<", "rule", ">")
					),
					[]
				),
				[Grammars::BNF::Expression.elements[1].grammar.new(' ', '|', ' ',
					Grammars::BNF::List.new(
						Grammars::BNF::Terminal.new(Grammars::BNF::Terminal.elements[1].new("<", "rule", ">")),
						[Grammars::BNF::List.elements[1].grammar.new(' ',
							Grammars::BNF::Terminal.new(Grammars::BNF::Terminal.elements[1].new("<", "syntax", ">"))
						)]
					),
				)]
			),
			"\n"
		)
	]])
    end
end