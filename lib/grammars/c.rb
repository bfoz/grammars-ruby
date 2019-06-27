require 'grammar/dsl'

module Grammars
    # http://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf
    module C
	using Grammar::DSL

	storage_class_spec	= 'auto' | 'register' | 'static' | 'extern' | 'typedef'
	struct_or_union	= 'struct' | 'union'

	# A.1.3 Identifiers

	#(6.4.2.1)
	identifier	= /[^0-9][0-9_a-zA-Z]*/

	type_qualifier	= 'const' | 'volatile'
	type_qualifier_list	= type_qualifier.at_least(1)
	pointer	= alternation(
		concatenation(alternation(concatenation("*", type_qualifier_list), "*").any, "*", type_qualifier_list),
		concatenation(alternation(concatenation("*", type_qualifier_list), "*").any, "*")
	)
	abstract_declarator = Grammar::Recursion.new
	conditional_expression = Grammar::Recursion.new
	declarator = Grammar::Recursion.new
	decl_specs = Grammar::Recursion.new
	const_exp	= conditional_expression
	param_decl	= alternation do
		element concatenation(decl_specs, declarator)
		element concatenation(decl_specs, abstract_declarator)
		element decl_specs
	end
	param_list	= concatenation do
		element param_decl
		element concatenation(",", param_decl).any
	end
	param_type_list	= alternation do
		element param_list
		element concatenation(param_list, ",", "...")
	end
	direct_abstract_declarator	= alternation do
		element concatenation("(", abstract_declarator, ")", alternation(concatenation("[", const_exp.optional, "]"), concatenation("(", param_type_list.optional, ")")).any)
		element concatenation("[", const_exp, "]", alternation(concatenation("[", const_exp, "]"), concatenation("[", "]"), concatenation("(", param_type_list, ")"), concatenation("(", ")")).any)
		element concatenation("[", "]", alternation(concatenation("[", const_exp, "]"), concatenation("[", "]"), concatenation("(", param_type_list, ")"), concatenation("(", ")")).any)
		element concatenation("(", param_type_list, ")", alternation(concatenation("[", const_exp, "]"), concatenation("[", "]"), concatenation("(", param_type_list, ")"), concatenation("(", ")")).any)
		element concatenation("(", ")", alternation(concatenation("[", const_exp, "]"), concatenation("[", "]"), concatenation("(", param_type_list, ")"), concatenation("(", ")")).any)
	end
	abstract_declarator.grammar	= concatenation(pointer.optional, direct_abstract_declarator.optional)

	# A.1.5 Constants

	# (6.4.4.1)
	decimal_constant	= /[1-9][0-9]*/
	octal_constant	= /0[0-7]*/
	hexadecimal_constant	= /0[xX][0-9A-Fa-f]+/
	long_suffix	= /[lL]/
	long_long_suffix	= /ll|LL/
	unsigned_suffix	= /[uU]/
	integer_suffix 	= alternation do
		element concatenation(unsigned_suffix, long_suffix.optional)
		element concatenation(unsigned_suffix, long_long_suffix)
		element concatenation(long_suffix, unsigned_suffix.optional)
		element concatenation(long_long_suffix, unsigned_suffix.optional)
	end
	integer_constant	= alternation do
		element concatenation(decimal_constant, integer_suffix.optional)
		element concatenation(octal_constant, integer_suffix.optional)
		element concatenation(hexadecimal_constant, integer_suffix.optional)
	end

	# (6.4.4.2)
	exponent_part	= /[eE][+-]?[0-9]+/
	fractional_constant	= alternation(/[0-9]*\.[0-9]+/, /[0-9]+\./)
	floating_suffix	= /[flFL]/
	decimal_floating_constant	= alternation do
		element concatenation(fractional_constant, exponent_part.optional, floating_suffix.optional)
		element concatenation(/[0-9]+/, exponent_part, floating_suffix.optional)
	end
	binary_exponent_part	= /[pP][+-]?[0-9]+/
	hexadecimal_fractional_constant	= alternation do
		element concatenation(/[0-9a-fA-F]*/, '.', /[0-9a-fA-F]+/)
		element concatenation(/[0-9a-fA-F]+/, '.')
	end
	hexadecimal_floating_constant 	= alternation do
		element concatenation(/0[xX]/, hexadecimal_fractional_constant, binary_exponent_part, floating_suffix.optional)
		element concatenation(/0[xX]/, /[0-9a-fA-F]+/, binary_exponent_part, floating_suffix.optional)
	end
	floating_constant	= alternation(decimal_floating_constant, hexadecimal_floating_constant)

	# (6.4.4.3)
	enumeration_constant	= identifier

	# (6.4.4.4)
	c_char = alternation(/[^,\\\n]/, "\\'", '\"', '\?', '\\', '\a', '\b', '\f', '\n', '\r', '\t', '\v', /\\[0-7]{1,3}/, /\\x[0-9a-fA-F]+/).at_least(1)
	character_constant	= alternation do
		element concatenation("'", c_char, "'")
		element concatenation("L'", c_char, "'")
		element concatenation("u'", c_char, "'")
		element concatenation("U'", c_char, "'")
	end

	# (6.4.4)
	constant 	= alternation(integer_constant, floating_constant, enumeration_constant, character_constant)

	# A.1.6 String literals

	# (6.4.5)
	s_char = alternation(/[^,\\\n]/, "\\'", '\"', '\?', '\\', '\a', '\b', '\f', '\n', '\r', '\t', '\v', /\\[0-7]{1,3}/, /\\x[0-9a-fA-F]+/)
	string_literal	= concatenation(/(u8|u|U|L)?/, '"', s_char.any, '"')

	assignment_operator	= '=' | '*=' | '/=' | '%=' | '+=' | '-=' | '<<=' | '>>=' | '&=' | '^=' | '|='
	expression = Grammar::Recursion.new
	type_name = Grammar::Recursion.new
	unary_exp = Grammar::Recursion.new
	assignment_exp	= concatenation do
		element concatenation(unary_exp, assignment_operator).any
		element conditional_expression
	end
	unary_operator	= '&' | '*' | '+' | '-' | '~' | '!'
	unary_exp	= alternation do |unary_exp|
		cast_exp	= concatenation do
			element concatenation("(", type_name, ")").any
			element unary_exp
		end
		mult_exp	= concatenation do
			element cast_exp
			element alternation(concatenation("*", cast_exp), concatenation("/", cast_exp), concatenation("%", cast_exp)).any
		end
		additive_exp	= concatenation do
			element mult_exp
			element alternation(concatenation("+", mult_exp), concatenation("-", mult_exp)).any
		end
		shift_expression	= concatenation do
			element additive_exp
			element alternation(concatenation("<<", additive_exp), concatenation(">>", additive_exp)).any
		end
		relational_exp	= concatenation do
			element shift_expression
			element alternation(concatenation("<", shift_expression), concatenation(">", shift_expression), concatenation("<=", shift_expression), concatenation(">=", shift_expression)).any
		end
		equality_exp	= concatenation do
			element relational_exp
			element alternation(concatenation("==", relational_exp), concatenation("!=", relational_exp)).any
		end
		and_exp	= concatenation do
			element equality_exp
			element concatenation("&", equality_exp).any
		end
		exclusive_or_exp	= concatenation do
			element and_exp
			element concatenation("^", and_exp).any
		end
		inclusive_or_exp	= concatenation do
			element exclusive_or_exp
			element concatenation("|", exclusive_or_exp).any
		end
		logical_and_exp	= concatenation do
			element inclusive_or_exp
			element concatenation("&&", inclusive_or_exp).any
		end
		logical_or_exp	= concatenation do
			element logical_and_exp
			element concatenation("||", logical_and_exp).any
		end

		# (6.5.17)
		expression.grammar	= concatenation do
			# (6.5.16)
			conditional_expression.grammar	= concatenation do
				element concatenation(logical_or_exp, "?", expression, ":").any
				element logical_or_exp
			end

			element assignment_exp
			element concatenation(",", assignment_exp).any
		end

		primary_exp	= alternation do
			element identifier
			element constant
			element string_literal
			element concatenation("(", expression, ")")
		end
		argument_exp_list	= concatenation do
			element assignment_exp
			element concatenation(",", assignment_exp).any
		end
		postfix_exp	= concatenation do
			element primary_exp
			element alternation(concatenation("[", expression, "]"), concatenation("(", argument_exp_list, ")"), concatenation("(", ")"), concatenation(".", identifier), concatenation("->", identifier), "++", "--").any
		end

		element concatenation(('++' | '--' | 'sizeof').any, postfix_exp)
		element concatenation(('++' | '--' | 'sizeof').any, unary_operator, cast_exp)
		element concatenation(('++' | '--' | 'sizeof').any, "sizeof", "(", type_name, ")")
	end

	id_list	= concatenation(identifier, concatenation(",", identifier).any)
	direct_declarator	= alternation do |direct_declarator|
		element concatenation(identifier, alternation(concatenation("[", const_exp, "]"), concatenation("[", "]"), concatenation("(", param_type_list, ")"), concatenation("(", id_list, ")"), concatenation("(", ")")).any)
		element concatenation("(", declarator, ")", alternation(concatenation("[", const_exp, "]"), concatenation("[", "]"), concatenation("(", param_type_list, ")"), concatenation("(", id_list, ")"), concatenation("(", ")")).any)
	end
	declarator.grammar	= concatenation(pointer.optional, direct_declarator)
	struct_declarator	= alternation do |struct_declarator|
		element declarator
		element concatenation(declarator, ":", const_exp)
		element concatenation(":", const_exp)
	end
	struct_declarator_list	= concatenation do |struct_declarator_list|
		element struct_declarator
		element concatenation(",", struct_declarator).any
	end
	struct_decl_list = Grammar::Recursion.new
	struct_or_union_spec	= alternation do |struct_or_union_spec|
		element concatenation(struct_or_union, identifier, "{", struct_decl_list, "}")
		element concatenation(struct_or_union, "{", struct_decl_list, "}")
		element concatenation(struct_or_union, identifier)
	end
	enumerator	= alternation do |enumerator|
		element identifier
		element concatenation(identifier, "=", const_exp)
	end
	enumerator_list	= concatenation do |enumerator_list|
		element enumerator
		element concatenation(",", enumerator).any
	end
	enum_spec	= alternation do |enum_spec|
		element concatenation("enum", identifier, "{", enumerator_list, "}")
		element concatenation("enum", "{", enumerator_list, "}")
		element concatenation("enum", identifier)
	end
	typedef_name	= identifier

	# (6.7.2)
	type_specifier	= alternation do |type_specifier|
		element "void"
		element "char"
		element "short"
		element "int"
		element "long"
		element "float"
		element "double"
		element "signed"
		element "unsigned"
		element struct_or_union_spec
		element enum_spec
		element typedef_name
	end

	# (6.7.2.1)
	specifier_qualifier_list	= alternation(type_specifier, type_qualifier).at_least(1)
	struct_decl	= concatenation(specifier_qualifier_list, struct_declarator_list, ";")
	struct_decl_list.grammar	= struct_decl.at_least(1)

	# (6.7.7)
	type_name.grammar	= concatenation(specifier_qualifier_list, abstract_declarator.optional)

	decl_specs.grammar	= alternation do |decl_specs|
		element concatenation(alternation(storage_class_spec, type_specifier, type_qualifier).any, storage_class_spec)
		element concatenation(alternation(storage_class_spec, type_specifier, type_qualifier).any, type_specifier)
		element concatenation(alternation(storage_class_spec, type_specifier, type_qualifier).any, type_qualifier)
	end
	initializer	= alternation do |initializer|
		initializer_list	= concatenation(initializer, concatenation(",", initializer).any)
		element assignment_exp
		element concatenation("{", initializer_list, "}")
		element concatenation("{", initializer_list, ",", "}")
	end
	init_declarator	= alternation(declarator, concatenation(declarator, "=", initializer))
	init_declarator_list	= concatenation(init_declarator, concatenation(",", init_declarator).any)
	decl	= alternation(concatenation(decl_specs, init_declarator_list, ";"), concatenation(decl_specs, ";"))
	decl_list	= decl.at_least(1)
	compound_stat = Grammar::Recursion.new
	stat	= alternation do |stat|
		labeled_stat	= alternation do
			element concatenation(identifier, ":", stat)
			element concatenation("case", const_exp, ":", stat)
			element concatenation("default", ":", stat)
		end
		exp_stat	= alternation(concatenation(expression, ";"), ";")
		selection_stat	= alternation do
			element concatenation("if", "(", expression, ")", stat)
			element concatenation("if", "(", expression, ")", stat, "else", stat)
			element concatenation("switch", "(", expression, ")", stat)
		end
		iteration_stat	= alternation do
			element concatenation("while", "(", expression, ")", stat)
			element concatenation("do", stat, "while", "(", expression, ")", ";")
			element concatenation("for", "(", expression, ";", expression, ";", expression, ")", stat)
			element concatenation("for", "(", expression, ";", expression, ";", ")", stat)
			element concatenation("for", "(", expression, ";", ";", expression, ")", stat)
			element concatenation("for", "(", expression, ";", ";", ")", stat)
			element concatenation("for", "(", ";", expression, ";", expression, ")", stat)
			element concatenation("for", "(", ";", expression, ";", ")", stat)
			element concatenation("for", "(", ";", ";", expression, ")", stat)
			element concatenation("for", "(", ";", ";", ")", stat)
		end
		jump_stat	= alternation(concatenation("goto", identifier, ";"), concatenation("continue", ";"), concatenation("break", ";"), concatenation("return", expression, ";"), concatenation("return", ";"))

		element labeled_stat
		element exp_stat
		element compound_stat
		element selection_stat
		element iteration_stat
		element jump_stat
	end
	stat_list	= stat.at_least(1)
	compound_stat.grammar	= alternation do |compound_stat|
		element concatenation("{", decl_list, stat_list, "}")
		element concatenation("{", stat_list, "}")
		element concatenation("{", decl_list, "}")
		element concatenation("{", "}")
	end
	function_definition	= alternation(concatenation(decl_specs, declarator, decl_list, compound_stat), concatenation(declarator, decl_list, compound_stat), concatenation(decl_specs, declarator, compound_stat), concatenation(declarator, compound_stat))
	external_decl	= alternation(function_definition, decl)
	translation_unit	= external_decl.at_least(1)
    end
end
