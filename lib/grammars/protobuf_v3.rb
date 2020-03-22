require 'grammar/dsl'

module Grammars
    module Protobuf
	using Grammar::DSL

	# implicit_separator /\s*/
	ignore /\s*/

	# --- Lexical elements ---

	# Identifiers
	Identifier = /[a-zA-z][a-zA-Z0-9_]*/
	FullIdentifier = concatenation(Identifier, concatenation('.', Identifier).any)

	MessageName = Identifier
	EnumName = Identifier
	FieldName = Identifier
	OneOfName = Identifier
	ServiceName = Identifier
	RPCName = Identifier

	# messageType = [ "." ] { ident "." } messageName
	MessageType = concatenation('.'.optional, concatenation(Identifier, '.').any, MessageName)

	# enumType = [ "." ] { ident "." } enumName
	EnumType = concatenation('.'.optional, concatenation(Identifier, '.').any, EnumName)

	# groupName = capitalLetter { letter | decimalDigit | "_" }
	GroupName = /[A-Z][a-zA-z0-9_]*/

	# Integer literals
	OctalLiteral = /0[0-7]*/
	DecimalLiteral = /[1-9][0-9]*/
	HexLiteral = /o[xX][0-9a-fA-F]+/
	IntegerLiteral     = DecimalLiteral | OctalLiteral | HexLiteral

	FloatLiteral = alternation(/[0-9]+\.[0-9]*([eE][+-][0-9]+)?/, /[0-9]+[eE][+-][0-9]+/, /\.[0-9]+([eE][+-][0-9]+)?/, 'inf', 'nan')

	# String literals
	HexEscape = /\\[xX][0-9a-fA-F]{2}/
	OctalEscape = /\\[0-7]{3}/
	CharacterEscape = /\\[abfnrtv\\'"]/
	CharValue1 = HexEscape | OctalEscape | CharacterEscape | /[^\0\n\\']/
	CharValue2 = HexEscape | OctalEscape | CharacterEscape | /[^\0\n\\"]/
	StringLiteral = concatenation("'", CharValue1.any, "'") | concatenation('"', CharValue2.any, '"')

	EmptyStatement = ";"
	Constant = FullIdentifier | concatenation(("-" | "+").optional, IntegerLiteral) | concatenation(("-" | "+").optional, FloatLiteral) | StringLiteral | "true" | "false"

	# Syntax
	# The syntax statement is used to define the protobuf version.
	Syntax = /syntax\s*=\s*(['"])proto3\1;/

	# Import Statement
	# The import statement is used to import another .proto's definitions.
	Import = concatenation("import", ("weak" | "public").optional, StringLiteral, ";")

	# Package
	# The package specifier can be used to prevent name clashes between protocol message types.
	Package = concatenation("package", FullIdentifier, ";")

	# Option
	# Options can be used in proto files, messages, enums and services. An option can be a protobuf defined option or a custom option. For more information, see Options in the language guide.
	OptionName = concatenation(Identifier | concatenation('(', FullIdentifier, ')'), concatenation('.', Identifier).any)
	Option = concatenation('option', OptionName, '=', Constant, ';')

	# Fields
	# Fields are the basic elements of a protocol buffer message. Fields can be normal fields, oneof fields, or map fields. A field has a type and field number.

	# Normal field
	# Each field has type, name and field number. It may have field options.
	Type = "double" | "float" | "int32" | "int64" | "uint32" | "uint64" | "sint32" | "sint64" | "fixed32" | "fixed64" | "sfixed32" | "sfixed64" | "bool" | "string" | "bytes" | MessageType | EnumType
	FieldNumber = IntegerLiteral;
	FieldOption = concatenation(OptionName, '=', Constant)
	FieldOptions = concatenation(FieldOption, concatenation(',', FieldOption).any)
	Field = concatenation('repeated'.optional, Type, FieldName, '=', FieldNumber, concatenation('[', FieldOptions, ']').optional, ';')

	# Oneof and oneof field
	# A oneof consists of oneof fields and a oneof name.
	OneOfField = concatenation(Type, FieldName, '=', FieldNumber, concatenation('[', FieldOptions, ']').optional, ';')
	OneOf = concatenation('oneof', OneOfName, '{', (OneOfField | EmptyStatement).any, '}')

	# Map field
	# A map field has a key type, value type, name, and field number. The key type can be any integral or string type.
        MapField = concatenation do
            element 'map'
            element '<'
            element KeyType: "int32" | "int64" | "uint32" | "uint64" | "sint32" | "sint64" | "fixed32" | "fixed64" | "sfixed32" | "sfixed64" | "bool" | "string"
            element ','
            element Type
            element '>'
            element Name: Identifier
            element '='
            element FieldNumber
            element concatenation('[', FieldOptions, ']').optional
            element ';'
        end

	# Reserved
	# Reserved statements declare a range of field numbers or field names that cannot be used in this message.
	Range = concatenation(IntegerLiteral, concatenation('to', IntegerLiteral | "max").optional)	# range =  intLit [ "to" ( intLit | "max" ) ]
	Ranges = concatenation(Range, concatenation(',', Range))					# ranges = range { "," range }
	FieldNames = concatenation(FieldName, concatenation(',', FieldName))				# fieldNames = fieldName { "," fieldName }
	Reserved = concatenation("reserved", Ranges | FieldNames, ';')					# reserved = "reserved" ( ranges | fieldNames ) ";"

	# --- Top Level definitions ---

	# Enum definition
	# The enum definition consists of a name and an enum body. The enum body can have options and enum fields. Enum definitions must start with enum value zero.
	Enum = concatenation do
	    element "enum"
	    element Name: EnumName

	    EnumValueOption = concatenation(OptionName, '=', Constant)
	    EnumField = concatenation(Identifier, '=', IntegerLiteral, concatenation('[', EnumValueOption, concatenation(',', EnumValueOption).any, ']').optional, ';')
	    element Body: concatenation('{', (Option | EnumField | EmptyStatement).any, '}')
	end

	# Message definition
	# A message consists of a message name and a message body. The message body can have fields, nested enum definitions, nested message definitions, options, oneofs, map fields, and reserved statements.
	Message = concatenation do |message|
	    element "message"
	    element Name: MessageName
	    element Body: concatenation('{', (Field | Enum | message | Option | OneOf | MapField | Reserved | EmptyStatement).any, '}')
	end

	RPC = concatenation("rpc", RPCName, "(", "stream".optional, MessageType, ")", "returns", "(", "stream".optional, MessageType, ")", (concatenation("{", (Option | EmptyStatement).any, "}") | ";"))
	Service = concatenation("service", ServiceName, "{", (Option | RPC | EmptyStatement).any, "}")

	# proto = syntax { import | package | option | topLevelDef | emptyStatement }
	# topLevelDef = message | enum | service
	Proto = concatenation(Syntax, (Import | Package | Option | Message | Enum | Service | EmptyStatement).any)
    end
end
