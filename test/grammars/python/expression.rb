RSpec.shared_examples 'Python::Expression' do
    before :each do
	parser.push Grammars::Python::Expression
    end

    context 'Atom' do
	it 'must parse a base 2 number' do
	    expect(parser.parse('1010')).to eq([
		Grammars::Python::Expression.new(
		    Grammars::Python::Expression::Atom.new('1010')
		)
	    ])
	end

	it 'must parse a base 10 number' do
	    expect(parser.parse('42')).to eq([
		Grammars::Python::Expression.new(
		    Grammars::Python::Expression::Atom.new('42')
		)
	    ])
	end

	it 'must parse a base 16 number' do
	    expect(parser.parse('0xA3')).to eq([
		Grammars::Python::Expression.new(
		    Grammars::Python::Expression::Atom.new('0xA3')
		)
	    ])
	end

	it 'must parse a double quoted string' do
	    expect(parser.parse('"foo"')).to eq([
		Grammars::Python::Expression.new(
		    Grammars::Python::Expression::Atom.new('"foo"')
		)
	    ])
	end

	it 'must parse literal ellipsis' do
	    expect(parser.parse('...')).to eq([
		Grammars::Python::Expression.new(
		    Grammars::Python::Expression::Atom.new('...')
		)
	    ])
	end

	it 'must parse literal False' do
	    expect(parser.parse('False')).to eq([
		Grammars::Python::Expression.new(
		    Grammars::Python::Expression::Atom.new('False')
		)
	    ])
	end

	it 'must parse literal None' do
	    expect(parser.parse('None')).to eq([
		Grammars::Python::Expression.new(
		    Grammars::Python::Expression::Atom.new('None')
		)
	    ])
	end

	it 'must parse literal True' do
	    expect(parser.parse('True')).to eq([
		Grammars::Python::Expression.new(
		    Grammars::Python::Expression::Atom.new('True')
		)
	    ])
	end
    end

    context 'Term' do
	it 'must parse a division term' do
	    expect(parser.parse('42/42')).to eq([
		Grammars::Python::Expression.new(
		    Grammars::Python::Expression::Term.new(
			Grammars::Python::Expression::Factor.new(
			    [],
			    Grammars::Python::Expression::Factor[1].new(
				Grammars::Python::Expression::Primary.new(
				    nil,
				    Grammars::Python::Expression::Atom.new('42'),
				    []
				),
				nil
			    )
			),
			[
			    Grammars::Python::Expression::Term.last.grammar.new(
				'/',
				Grammars::Python::Expression::Factor.new(
				    [],
				    Grammars::Python::Expression::Factor[1].new(
					Grammars::Python::Expression::Primary.new(
					    nil,
					    Grammars::Python::Expression::Atom.new('42'),
					    []
					),
					nil
				    )
				)
			    )
			]
		    )
		)
	    ])
	end

	it 'must parse a multiplicative term' do
	    expect(parser.parse('42*42')).to eq([
		Grammars::Python::Expression.new(
		    Grammars::Python::Expression::Term.new(
			Grammars::Python::Expression::Factor.new(
			    [],
			    Grammars::Python::Expression::Factor[1].new(
				Grammars::Python::Expression::Primary.new(
				    nil,
				    Grammars::Python::Expression::Atom.new('42'),
				    []
				),
				nil
			    )
			),
			[
			    Grammars::Python::Expression::Term.last.grammar.new(
				'*',
				Grammars::Python::Expression::Factor.new(
				    [],
				    Grammars::Python::Expression::Factor[1].new(
					Grammars::Python::Expression::Primary.new(
					    nil,
					    Grammars::Python::Expression::Atom.new('42'),
					    []
					),
					nil
				    )
				)
			    )
			]
		    )
		)
	    ])
	end
    end

    context 'Arithmetic' do
	it 'must parse an addition expression' do
	    expect(parser.parse('42+42')).to eq([
		Grammars::Python::Expression.new(
		    Grammars::Python::Expression::Sum.new(
			Grammars::Python::Expression::Term.new(
			   Grammars::Python::Expression::Factor.new(
				[],
				Grammars::Python::Expression::Factor[1].new(
				    Grammars::Python::Expression::Primary.new(
					nil,
					Grammars::Python::Expression::Atom.new('42'),
					[]
				    ),
				    nil
				)
			    ),
			    []
			),
			[
			    Grammars::Python::Expression::Sum.last.grammar.new(
				'+',
				Grammars::Python::Expression::Term.new(
				    Grammars::Python::Expression::Factor.new(
					[],
					Grammars::Python::Expression::Factor[1].new(
					    Grammars::Python::Expression::Primary.new(
						nil,
						Grammars::Python::Expression::Atom.new('42'),
						[]
					    ),
					    nil
					)
				    ),
				    []
				)
			    )
			]
		    ),
		)
	    ])
	end

	it 'must parse a subtraction expression' do
	    expect(parser.parse('42-42')).to eq([
		Grammars::Python::Expression.new(
			Grammars::Python::Expression::Sum.new(
			    Grammars::Python::Expression::Term.new(
				Grammars::Python::Expression::Factor.new(
				    [],
				    Grammars::Python::Expression::Factor[1].new(
					Grammars::Python::Expression::Primary.new(
					    nil,
					    Grammars::Python::Expression::Atom.new('42'),
					    []
					),
					nil
				    )
				),
				[]
			    ),
			[
			    Grammars::Python::Expression::Sum.last.grammar.new(
				'-',
				Grammars::Python::Expression::Term.new(
				    Grammars::Python::Expression::Factor.new(
					[],
					Grammars::Python::Expression::Factor[1].new(
					    Grammars::Python::Expression::Primary.new(
						nil,
						Grammars::Python::Expression::Atom.new('42'),
						[]
					    ),
					    nil
					)
				    ),
				    []
				)
			    )
			]
		    ),
		)
	    ])
	end
    end

    context 'Bitwise' do
	it 'must parse a shift expression' do
	    expect(parser.parse('42<<42')).to eq([
		Grammars::Python::Expression.new(
		    Grammars::Python::Expression::BitwiseShift.new(
			Grammars::Python::Expression::Sum.new(
			    Grammars::Python::Expression::Term.new(
				Grammars::Python::Expression::Factor.new(
				    [],
				    Grammars::Python::Expression::Factor[1].new(
					Grammars::Python::Expression::Primary.new(
					    nil,
					    Grammars::Python::Expression::Atom.new('42'),
					    []
					),
					nil
				    )
				),
				[]
			    ),
			    []
			),
			[
			    Grammars::Python::Expression::BitwiseShift.last.grammar.new(
				'<<', 	# Alternation
				Grammars::Python::Expression::Sum.new(
				    Grammars::Python::Expression::Term.new(
					Grammars::Python::Expression::Factor.new(
					    [],
					    Grammars::Python::Expression::Factor[1].new(
						Grammars::Python::Expression::Primary.new(
						    nil,
						    Grammars::Python::Expression::Atom.new('42'),
						    []
						),
						nil
					    )
					),
					[]
				    ),
				    []
				),
			    )
			]
		    )
		)
	    ])
	end

	it 'must parse an AND expression' do
	    expect(parser.parse('42&42')).to eq([
		Grammars::Python::Expression.new(
		    Grammars::Python::Expression::BitwiseAnd.new(
			Grammars::Python::Expression::BitwiseShift.new(
			    Grammars::Python::Expression::Sum.new(
				Grammars::Python::Expression::Term.new(
				    Grammars::Python::Expression::Factor.new(
					[],
					Grammars::Python::Expression::Factor[1].new(
					    Grammars::Python::Expression::Primary.new(
						nil,
						Grammars::Python::Expression::Atom.new('42'),
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
			[
			    Grammars::Python::Expression::BitwiseAnd[1].grammar.new(
				'&',
				Grammars::Python::Expression::BitwiseShift.new(
				    Grammars::Python::Expression::Sum.new(
					Grammars::Python::Expression::Term.new(
					    Grammars::Python::Expression::Factor.new(
						[],
						Grammars::Python::Expression::Factor[1].new(
						    Grammars::Python::Expression::Primary.new(
							nil,
							Grammars::Python::Expression::Atom.new('42'),
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
				)
			    )
			]
		    )
		)
	    ])
	end

	it 'must parse an XOR expression' do
	    expect(parser.parse('42^42')).to eq([
		Grammars::Python::Expression.new(
		    Grammars::Python::Expression::BitwiseXor.new(
			Grammars::Python::Expression::BitwiseAnd.new(
			    Grammars::Python::Expression::BitwiseShift.new(
				Grammars::Python::Expression::Sum.new(
				    Grammars::Python::Expression::Term.new(
					Grammars::Python::Expression::Factor.new(
					    [],
					    Grammars::Python::Expression::Factor[1].new(
						Grammars::Python::Expression::Primary.new(
						     nil,
						     Grammars::Python::Expression::Atom.new('42'),
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
			[
			    Grammars::Python::Expression::BitwiseXor[1].grammar.new(
				'^',
				Grammars::Python::Expression::BitwiseAnd.new(
				    Grammars::Python::Expression::BitwiseShift.new(
					Grammars::Python::Expression::Sum.new(
					    Grammars::Python::Expression::Term.new(
						Grammars::Python::Expression::Factor.new(
						    [],
						    Grammars::Python::Expression::Factor[1].new(
							Grammars::Python::Expression::Primary.new(
							    nil,
							    Grammars::Python::Expression::Atom.new('42'),
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
				)
			    )
			]
		    )
		)
	    ])
	end

	it 'must parse an OR expression' do
	    expect(parser.parse('42|42')).to eq([
		Grammars::Python::Expression.new(
		    Grammars::Python::Expression::BitwiseOr.new(
			Grammars::Python::Expression::BitwiseXor.new(
			    Grammars::Python::Expression::BitwiseAnd.new(
				Grammars::Python::Expression::BitwiseShift.new(
				    Grammars::Python::Expression::Sum.new(
					Grammars::Python::Expression::Term.new(
					    Grammars::Python::Expression::Factor.new(
						[],
						Grammars::Python::Expression::Factor[1].new(
						    Grammars::Python::Expression::Primary.new(
							nil,
							Grammars::Python::Expression::Atom.new('42'),
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
			[
			    Grammars::Python::Expression::BitwiseOr[1].grammar.new(
				'|',
				Grammars::Python::Expression::BitwiseXor.new(
				    Grammars::Python::Expression::BitwiseAnd.new(
					Grammars::Python::Expression::BitwiseShift.new(
					    Grammars::Python::Expression::Sum.new(
						Grammars::Python::Expression::Term.new(
						    Grammars::Python::Expression::Factor.new(
							[],
							Grammars::Python::Expression::Factor[1].new(
							    Grammars::Python::Expression::Primary.new(
								nil,
								Grammars::Python::Expression::Atom.new('42'),
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
			    )
			]
		    )
		)
	    ])
	end
    end
end
