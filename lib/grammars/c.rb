require 'grammar/dsl'

module Grammars
    module C
	using Grammar::DSL

	storage_class_spec	= 'auto' | 'register' | 'static' | 'extern' | 'typedef'
	struct_or_union	= 'struct' | 'union'
	id	= "identifier_regex"
	type_qualifier	= 'const' | 'volatile'
	spec_qualifier_list	= alternation do |spec_qualifier_list|
		element concatenation(alternation(type_spec, type_qualifier).any, type_spec)
		element concatenation(alternation(type_spec, type_qualifier).any, type_qualifier)
	end
	type_qualifier_list	= type_qualifier.at_least(1)
	pointer	= alternation(concatenation(alternation(concatenation("*", type_qualifier_list), "*").any, "*", type_qualifier_list), concatenation(alternation(concatenation("*", type_qualifier_list), "*").any, "*"))
	param_decl	= alternation do |param_decl|
		element concatenation(decl_specs, declarator)
		element concatenation(decl_specs, abstract_declarator)
		element decl_specs
	end
	param_list	= concatenation do |param_list|
		element param_decl
		element concatenation(",", param_decl).any
	end
	param_type_list	= alternation do |param_type_list|
		element param_list
		element concatenation(param_list, ",", "...")
	end
	direct_abstract_declarator	= alternation do |direct_abstract_declarator|
		element concatenation("(", abstract_declarator, ")", alternation(concatenation("[", const_exp, "]"), concatenation("[", "]"), concatenation("(", param_type_list, ")"), concatenation("(", ")")).any)
		element concatenation("[", const_exp, "]", alternation(concatenation("[", const_exp, "]"), concatenation("[", "]"), concatenation("(", param_type_list, ")"), concatenation("(", ")")).any)
		element concatenation("[", "]", alternation(concatenation("[", const_exp, "]"), concatenation("[", "]"), concatenation("(", param_type_list, ")"), concatenation("(", ")")).any)
		element concatenation("(", param_type_list, ")", alternation(concatenation("[", const_exp, "]"), concatenation("[", "]"), concatenation("(", param_type_list, ")"), concatenation("(", ")")).any)
		element concatenation("(", ")", alternation(concatenation("[", const_exp, "]"), concatenation("[", "]"), concatenation("(", param_type_list, ")"), concatenation("(", ")")).any)
	end
	abstract_declarator	= alternation do |abstract_declarator|
		element pointer
		element concatenation(pointer, direct_abstract_declarator)
		element direct_abstract_declarator
	end
	type_name	= alternation do |type_name|
		element concatenation(spec_qualifier_list, abstract_declarator)
		element spec_qualifier_list
	end
	int_const	= "int_regex"
	char_const	= "char_regex"
	float_const	= "float_regex"
	enumeration_const	= "enum_regex"
	const	= alternation(int_const, char_const, float_const, enumeration_const)
	string	= "string_regex"
	assignment_operator	= '=' | '*=' | '/=' | '%=' | '+=' | '-=' | '<<=' | '>>=' | '&=' | '^=' | '|='
	assignment_exp	= concatenation do |assignment_exp|
		element concatenation(unary_exp, assignment_operator).any
		element conditional_exp
	end
	exp	= concatenation do |exp|
		element assignment_exp
		element concatenation(",", assignment_exp).any
	end
	primary_exp	= alternation do |primary_exp|
		element id
		element const
		element string
		element concatenation("(", exp, ")")
	end
	argument_exp_list	= concatenation do |argument_exp_list|
		element assignment_exp
		element concatenation(",", assignment_exp).any
	end
	postfix_exp	= concatenation do |postfix_exp|
		element primary_exp
		element alternation(concatenation("[", exp, "]"), concatenation("(", argument_exp_list, ")"), concatenation("(", ")"), concatenation(".", id), concatenation("->", id), "++", "--").any
	end
	unary_operator	= '&' | '*' | '+' | '-' | '~' | '!'
	unary_exp	= alternation do |unary_exp|
		element concatenation(('++' | '--' | 'sizeof').any, postfix_exp)
		element concatenation(('++' | '--' | 'sizeof').any, unary_operator, cast_exp)
		element concatenation(('++' | '--' | 'sizeof').any, "sizeof", "(", type_name, ")")
	end
	cast_exp	= concatenation do |cast_exp|
		element concatenation("(", type_name, ")").any
		element unary_exp
	end
	mult_exp	= concatenation do |mult_exp|
		element cast_exp
		element alternation(concatenation("*", cast_exp), concatenation("/", cast_exp), concatenation("%", cast_exp)).any
	end
	additive_exp	= concatenation do |additive_exp|
		element mult_exp
		element alternation(concatenation("+", mult_exp), concatenation("-", mult_exp)).any
	end
	shift_expression	= concatenation do |shift_expression|
		element additive_exp
		element alternation(concatenation("<<", additive_exp), concatenation(">>", additive_exp)).any
	end
	relational_exp	= concatenation do |relational_exp|
		element shift_expression
		element alternation(concatenation("<", shift_expression), concatenation(">", shift_expression), concatenation("<=", shift_expression), concatenation(">=", shift_expression)).any
	end
	equality_exp	= concatenation do |equality_exp|
		element relational_exp
		element alternation(concatenation("==", relational_exp), concatenation("!=", relational_exp)).any
	end
	and_exp	= concatenation do |and_exp|
		element equality_exp
		element concatenation("&", equality_exp).any
	end
	exclusive_or_exp	= concatenation do |exclusive_or_exp|
		element and_exp
		element concatenation("^", and_exp).any
	end
	inclusive_or_exp	= concatenation do |inclusive_or_exp|
		element exclusive_or_exp
		element concatenation("|", exclusive_or_exp).any
	end
	logical_and_exp	= concatenation do |logical_and_exp|
		element inclusive_or_exp
		element concatenation("&&", inclusive_or_exp).any
	end
	logical_or_exp	= concatenation do |logical_or_exp|
		element logical_and_exp
		element concatenation("||", logical_and_exp).any
	end
	conditional_exp	= concatenation do |conditional_exp|
		element concatenation(logical_or_exp, "?", exp, ":").any
		element logical_or_exp
	end
	const_exp	= conditional_exp
	id_list	= concatenation(id, concatenation(",", id).any)
	direct_declarator	= alternation do |direct_declarator|
		element concatenation(id, alternation(concatenation("[", const_exp, "]"), concatenation("[", "]"), concatenation("(", param_type_list, ")"), concatenation("(", id_list, ")"), concatenation("(", ")")).any)
		element concatenation("(", declarator, ")", alternation(concatenation("[", const_exp, "]"), concatenation("[", "]"), concatenation("(", param_type_list, ")"), concatenation("(", id_list, ")"), concatenation("(", ")")).any)
	end
	declarator	= alternation do |declarator|
		element concatenation(pointer, direct_declarator)
		element direct_declarator
	end
	struct_declarator	= alternation do |struct_declarator|
		element declarator
		element concatenation(declarator, ":", const_exp)
		element concatenation(":", const_exp)
	end
	struct_declarator_list	= concatenation do |struct_declarator_list|
		element struct_declarator
		element concatenation(",", struct_declarator).any
	end
	struct_decl	= concatenation do |struct_decl|
		element spec_qualifier_list
		element struct_declarator_list
		element ";"
	end
	struct_decl_list	= struct_decl.at_least(1)
	struct_or_union_spec	= alternation do |struct_or_union_spec|
		element concatenation(struct_or_union, id, "{", struct_decl_list, "}")
		element concatenation(struct_or_union, "{", struct_decl_list, "}")
		element concatenation(struct_or_union, id)
	end
	enumerator	= alternation do |enumerator|
		element id
		element concatenation(id, "=", const_exp)
	end
	enumerator_list	= concatenation do |enumerator_list|
		element enumerator
		element concatenation(",", enumerator).any
	end
	enum_spec	= alternation do |enum_spec|
		element concatenation("enum", id, "{", enumerator_list, "}")
		element concatenation("enum", "{", enumerator_list, "}")
		element concatenation("enum", id)
	end
	typedef_name	= id
	type_spec	= alternation do |type_spec|
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
	decl_specs	= alternation do |decl_specs|
		element concatenation(alternation(storage_class_spec, type_spec, type_qualifier).any, storage_class_spec)
		element concatenation(alternation(storage_class_spec, type_spec, type_qualifier).any, type_spec)
		element concatenation(alternation(storage_class_spec, type_spec, type_qualifier).any, type_qualifier)
	end
	initializer_list	= concatenation(initializer, concatenation(",", initializer).any)
	initializer	= alternation do |initializer|
		element assignment_exp
		element concatenation("{", initializer_list, "}")
		element concatenation("{", initializer_list, ",", "}")
	end
	init_declarator	= alternation(declarator, concatenation(declarator, "=", initializer))
	init_declarator_list	= concatenation(init_declarator, concatenation(",", init_declarator).any)
	decl	= alternation(concatenation(decl_specs, init_declarator_list, ";"), concatenation(decl_specs, ";"))
	decl_list	= decl.at_least(1)
	labeled_stat	= alternation do |labeled_stat|
		element concatenation(id, ":", stat)
		element concatenation("case", const_exp, ":", stat)
		element concatenation("default", ":", stat)
	end
	exp_stat	= alternation(concatenation(exp, ";"), ";")
	selection_stat	= alternation do |selection_stat|
		element concatenation("if", "(", exp, ")", stat)
		element concatenation("if", "(", exp, ")", stat, "else", stat)
		element concatenation("switch", "(", exp, ")", stat)
	end
	iteration_stat	= alternation do |iteration_stat|
		element concatenation("while", "(", exp, ")", stat)
		element concatenation("do", stat, "while", "(", exp, ")", ";")
		element concatenation("for", "(", exp, ";", exp, ";", exp, ")", stat)
		element concatenation("for", "(", exp, ";", exp, ";", ")", stat)
		element concatenation("for", "(", exp, ";", ";", exp, ")", stat)
		element concatenation("for", "(", exp, ";", ";", ")", stat)
		element concatenation("for", "(", ";", exp, ";", exp, ")", stat)
		element concatenation("for", "(", ";", exp, ";", ")", stat)
		element concatenation("for", "(", ";", ";", exp, ")", stat)
		element concatenation("for", "(", ";", ";", ")", stat)
	end
	jump_stat	= alternation(concatenation("goto", id, ";"), concatenation("continue", ";"), concatenation("break", ";"), concatenation("return", exp, ";"), concatenation("return", ";"))
	stat	= alternation do |stat|
		element labeled_stat
		element exp_stat
		element compound_stat
		element selection_stat
		element iteration_stat
		element jump_stat
	end
	stat_list	= stat.at_least(1)
	compound_stat	= alternation do |compound_stat|
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
