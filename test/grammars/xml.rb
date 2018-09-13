require 'grammars/xml'

RSpec.describe Grammars::XML do
    subject(:parser) { Parsers::RecursiveDescent.new }

    it 'it must match a tag name' do
	parser.push Grammars::XML::Name
	expect(parser.parse('foo')).to eq(['foo'])
    end

    it 'it must match an attribute value' do
	parser.push Grammars::XML::AttValue
	expect(parser.parse('"42"')).to eq([Grammars::XML::AttValue.new(Grammars::XML::AttValue[0].new('"', ['42'], '"'))])
    end

    it 'must match a tag attribute' do
	parser.push Grammars::XML::Attribute
	expect(parser.parse('foo="42"')).to eq([Grammars::XML::Attribute.new('foo', '=', Grammars::XML::AttValue.new(Grammars::XML::AttValue[0].new('"', ['42'], '"')))])
    end

    it 'must parse an STag without attributes' do
	parser.push Grammars::XML::STag
	expect(parser.parse('<tag>')).to eq([Grammars::XML::STag.new('<', 'tag', [], nil, '>')])
    end

    it 'must parse an STag with attributes' do
	parser.push Grammars::XML::STag
	concatenation_klass = Grammars::XML::STag[2].grammar
	expect(parser.parse('<tag foo="42">')).to eq([Grammars::XML::STag.new(
		'<',
		'tag',
		[concatenation_klass.new(
			' ',
			Grammars::XML::Attribute.new('foo', '=', Grammars::XML::AttValue.new(Grammars::XML::AttValue[0].new('"', ['42'], '"')))
			)
		],
		nil,
		'>')
	])
    end
end
