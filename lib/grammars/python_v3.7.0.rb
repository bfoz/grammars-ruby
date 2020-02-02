require 'grammar/dsl'

module Grammars
    # Grammar for Python

    # NOTE WELL: You should also follow all the steps listed at
    # https://devguide.python.org/grammar/

    # Start symbols for the grammar:
    #       single_input is a single interactive statement;
    #       file_input is a module or sequence of commands read from an input file;
    #       eval_input is the input for the eval() functions.
    # NB: compound_stmt in single_input is followed by extra NEWLINE!
    module Python
	using Grammar::DSL

	DEDENT = //
	ENDMARKER = ''
	INDENT = /[\t ]+/
	NAME = /\w+/
	NEWLINE = /\n/

	BINARY_NUMBER = /0[bB][01_]+/
	DECIMAL_NUMBER = /[+\-]?\d+(\.\d+)?/
	HEXADECIMAL_NUMBER = /0[xX][0-9a-fA-F_]+/
	OCTAL_NUMBER = /0[oO][0-7_]+/
	NUMBER = BINARY_NUMBER | DECIMAL_NUMBER | HEXADECIMAL_NUMBER | OCTAL_NUMBER

	STRING = /\w+/

	# @group Expression

	# test: or_test ['if' or_test 'else' test] | lambdef
	arglist = nil
	expr = nil
	exprlist = nil
	star_expr = nil
	testlist = nil
	yield_expr = nil
	Test = alternation do |_test|

	    # testlist: test (',' test)* [',']
	    testlist = concatenation(_test, concatenation(',', _test).any, ','.optional)

	    # sliceop: ':' [test]
	    sliceop = concatenation(':', _test.optional)

	    # subscript: test | [test] ':' [test] [sliceop]
	    subscript = _test | concatenation(_test.optional, ':', _test.optional, sliceop.optional)

	    # subscriptlist: subscript (',' subscript)* [',']
	    subscriptlist = concatenation(subscript, concatenation(',', subscript).any, ','.optional)

	    # vfpdef: NAME
	    vfpdef = NAME

	    # varargslist: (vfpdef ['=' test] (',' vfpdef ['=' test])* [',' [
	    #         '*' [vfpdef] (',' vfpdef ['=' test])* [',' ['**' vfpdef [',']]]
	    #       | '**' vfpdef [',']]]
	    #   | '*' [vfpdef] (',' vfpdef ['=' test])* [',' ['**' vfpdef [',']]]
	    #   | '**' vfpdef [',']
	    # )
	    varargslist = alternation(
		concatenation(
			vfpdef,
			concatenation('=', _test).optional,
			concatenation(',', vfpdef, concatenation('=', _test).optional).any,
			concatenation(
				',',
				concatenation(
					'*',
					vfpdef.optional,
					concatenation(',', vfpdef, concatenation('=', _test).optional).any,
					alternation(
						concatenation(
							',',
							concatenation('**', vfpdef, ','.optional).optional
						).optional,
						concatenation('**', vfpdef, ','.optional)
					)
				).optional
			).optional
		),
		concatenation(
			'*',
			vfpdef.optional,
			concatenation(
				',',
				vfpdef,
				concatenation('=', _test).optional
			).any,
			concatenation(',', concatenation('**', vfpdef, ','.optional).optional).optional
		),
		concatenation('**', vfpdef, ','.optional)
	    )

	    # lambdef: 'lambda' [varargslist] ':' test
	    lambdef = concatenation('lambda', varargslist.optional, ':', _test)

	    # yield_arg: 'from' test | testlist
	    yield_arg = concatenation('from', _test) | testlist

	    # yield_expr: 'yield' [yield_arg]
	    yield_expr = concatenation('yield', yield_arg.optional)

	    # expr: xor_expr ('|' xor_expr)*
	    or_test = nil
	    Expression = concatenation do |expr|

		# <> isn't actually a valid comparison operator in Python. It's here for the
		# sake of a __future__ import described in PEP 401 (which really works :-)
		# comp_op: '<'|'>'|'=='|'>='|'<='|'<>'|'!='|'in'|'not' 'in'|'is'|'is' 'not'
		comp_op = '<'|'>'|'=='|'>='|'<='|'<>'|'!='|'in'|concatenation('not', 'in')|'is'|concatenation('is', 'not')

		# not_test: 'not' not_test | comparison
		# comparison: expr (comp_op expr)*
		not_test = alternation do |_not_test|
		    element concatenation('not', /\s*/, _not_test)
		    element Comparison: concatenation(expr, ComparisonRepetition = concatenation(comp_op, expr).any)
		end

		# and_test: not_test ('and' not_test)*
		and_test = concatenation(not_test, concatenation('and', not_test).any)

		# or_test: and_test ('or' and_test)*
		or_test = concatenation(and_test, concatenation('or', and_test).any)

		# star_expr: '*' expr
		star_expr = concatenation('*', expr)

		# exprlist: (expr|star_expr) (',' (expr|star_expr))* [',']
		Expressions = concatenation do
		    element Items: alternation(expr, star_expr)
		    element concatenation(',', Items).any
		    element ','.optional
		end
		exprlist = Expressions

		# test_nocond: or_test | lambdef_nocond
		test_nocond = alternation do |test_nocond|
		    # lambdef_nocond: 'lambda' [varargslist] ':' test_nocond
		    lambdef_nocond = concatenation('lambda', varargslist.optional, ':', test_nocond)

		    element or_test
		    element lambdef_nocond
		end

		# comp_iter: comp_for | comp_if
		comp_for = nil
		comp_iter = alternation do |comp_iter|

		    # sync_comp_for: 'for' exprlist 'in' or_test [comp_iter]
		    sync_comp_for = concatenation('for', exprlist, 'in', or_test, comp_iter.optional)

		    # comp_for: ['async'] sync_comp_for
		    comp_for = concatenation('async'.optional, sync_comp_for)

		    # comp_if: 'if' test_nocond [comp_iter]
		    comp_if = concatenation('if', test_nocond, comp_iter.optional)

		    element comp_for
		    element comp_if
		end

		# The reason that keywords are test nodes instead of NAME is that using NAME
		# results in an ambiguity. ast.c makes sure it's a NAME.
		# "test '=' test" is really "keyword '=' test", but we have no such token.
		# These need to be in a single rule to avoid grammar that is ambiguous
		# to our LL(1) parser. Even though 'test' includes '*expr' in star_expr,
		# we explicitly match '*' here, too, to give it proper precedence.
		# Illegal combinations and orderings are blocked in ast.c:
		# multiple (test comp_for) arguments are blocked; keyword unpackings
		# that precede iterable unpackings are blocked; etc.
		# argument: ( test [comp_for] |
		#             test '=' test |
		#             '**' test |
		#             '*' test )
		argument =   concatenation(_test, comp_for.optional) |
		             concatenation(_test, '=', _test) |
		             concatenation('**', _test) |
		             concatenation('*', _test)

		# arglist: argument (',' argument)*  [',']
		arglist = concatenation(argument, concatenation(',', argument).any, ','.optional)

		# dictorsetmaker: ( ((test ':' test | '**' expr)
		#                    (comp_for | (',' (test ':' test | '**' expr))* [','])) |
		#                   ((test | star_expr)
		#                    (comp_for | (',' (test | star_expr))* [','])) )
		dictorsetmaker = alternation(
				    concatenation(
					(concatenation(_test, ':', _test) | concatenation('**', expr)),
					(comp_for | concatenation(concatenation(',', (concatenation(_test, ':', _test) | concatenation('**', expr)) ).any, ','.optional))
				    ),
				    concatenation(
					(_test | star_expr),
					(comp_for | concatenation(concatenation(',', (_test | star_expr)).any, ','.optional))
				    )
				)

		# testlist_comp: (test|star_expr) ( comp_for | (',' (test|star_expr))* [','] )
		testlist_comp = concatenation((_test|star_expr), ( comp_for | concatenation(concatenation(',', (_test|star_expr)).any, ','.optional) ) )

		# trailer: '(' [arglist] ')' | '[' subscriptlist ']' | '.' NAME
		trailer = concatenation('(', arglist.optional, ')') | concatenation('[', subscriptlist, ']') | concatenation('.', NAME)

		# atom: ('(' [yield_expr|testlist_comp] ')' |
		#        '[' [testlist_comp] ']' |
		#        '{' [dictorsetmaker] '}' |
		#        NAME | NUMBER | STRING+ | '...' | 'None' | 'True' | 'False')
		Atom = concatenation('(', (yield_expr | testlist_comp).optional, ')') |
		       concatenation('[', testlist_comp.optional, ']') |
		       concatenation('{', dictorsetmaker.optional, '}') |
		       NAME | NUMBER | STRING | '...' | 'None' | 'True' | 'False'

		# atom_expr: ['await'] atom trailer*
		Primary = concatenation('await'.optional, Atom, trailer.any)

		# factor: ('+'|'-'|'~') factor | power
		# power: atom_expr ['**' factor]
		Factor = concatenation do |factor|
		    element ('+'|'-'|'~').any
		    element concatenation(Primary, concatenation('**', factor).optional)
		end

		# term: factor (('*'|'@'|'/'|'%'|'//') factor)*
		Term = concatenation(Factor, concatenation(('*'|'@'|'/'|'%'|'//'), Factor).any)

		# arith_expr: term (('+'|'-') term)*
		Sum = concatenation(Term, concatenation(('+'|'-'), Term).any)

		# shift_expr: arith_expr (('<<'|'>>') arith_expr)*
		BitwiseShift = concatenation(Sum, concatenation(('<<'|'>>'), Sum).any)

		# and_expr: shift_expr ('&' shift_expr)*
		BitwiseAnd = concatenation(BitwiseShift, concatenation('&', BitwiseShift).any)

		# xor_expr: and_expr ('^' and_expr)*
		element BitwiseXor: concatenation(BitwiseAnd, concatenation('^', BitwiseAnd).any)
		element concatenation('|', BitwiseXor).any
	    end

	    # @endgroup Expression

	    element TestFirst: concatenation(or_test, concatenation('if', or_test, 'else', _test).optional)
	    element LambdaDefinition: lambdef
	end

	# @group Statements

	# testlist_star_expr: (test|star_expr) (',' (test|star_expr))* [',']
	# testlist_star_expr = concatenation(Test|star_expr, concatenation(',', Test|star_expr).any, ','.optional)
	# Testlist_star_expr = concatenation(Test, TestListRepetition = concatenation(',', Test).any, ','.optional)

	# For normal and annotated assignments, additional restrictions enforced by the interpreter

	# annassign: ':' test ['=' test]
	annassign = concatenation(':', Test, concatenation('=', Test).optional)

	# augassign: ('+=' | '-=' | '*=' | '@=' | '/=' | '%=' | '&=' | '|=' | '^=' |
	#             '<<=' | '>>=' | '**=' | '//=')
	augassign = ('+=' | '-=' | '*=' | '@=' | '/=' | '%=' | '&=' | '|=' | '^=' | '<<=' | '>>=' | '**=' | '//=')

	# expr_stmt: testlist_star_expr (annassign | augassign (yield_expr|testlist) |
	#                      ('=' (yield_expr|testlist_star_expr))*)
	Expr_stmt = concatenation do
	    element Testlist_star_expr: concatenation(Test|star_expr, concatenation(',', Test|star_expr).any, ','.optional)
	    element annassign | concatenation(augassign, (yield_expr|testlist)) | concatenation('=', (yield_expr|Testlist_star_expr)).any
	end

	# dotted_name: NAME ('.' NAME)*
	dotted_name = concatenation(NAME, concatenation('.', NAME).any)

	# dotted_as_name: dotted_name ['as' NAME]
	dotted_as_name = concatenation(dotted_name, concatenation('as', NAME).optional)

	# dotted_as_names: dotted_as_name (',' dotted_as_name)*
	dotted_as_names = concatenation(dotted_as_name, concatenation(',', dotted_as_name).any)

	# import_name: 'import' dotted_as_names
	import_name = concatenation('import', dotted_as_names)

	# import_as_name: NAME ['as' NAME]
	import_as_name = concatenation(NAME, concatenation('as', NAME).optional)

	# import_as_names: import_as_name (',' import_as_name)* [',']
	import_as_names = concatenation(import_as_name, concatenation(',', import_as_name).any, ','.optional)

	# note below: the ('.' | '...') is necessary because '...' is tokenized as ELLIPSIS
	# import_from: ('from' (('.' | '...')* dotted_name | ('.' | '...')+)
	#               'import' ('*' | '(' import_as_names ')' | import_as_names))
	import_from = concatenation('from', (concatenation(('.' | '...').any, dotted_name) | ('.' | '...').one_or_more), 'import', ('*' | concatenation('(', import_as_names, ')') | import_as_names))

	# t_primary:
	#     | t_primary '.' NAME &t_lookahead
	#     | t_primary slicing &t_lookahead
	#     | t_primary genexp  &t_lookahead
	#     | t_primary '(' [arguments] ')' &t_lookahead
	#     | atom &t_lookahead
	# t_lookahead: '(' | '[' | '.'

	# target:
	#     | t_primary '.' NAME !t_lookahead
	#     | t_primary slicing !t_lookahead
	#     | t_atom
	# target = alternation do |_target|
	#     # targets: ','.target+ [',']
	#     targets = concatenation(target, concatenation(',', target), ','.optional)

	#     element concatenation(t_primary, '.', NAME)
	#     element concatenation(t_primary, slicing)

	#     # t_atom:
	#     #     | NAME
	#     #     | '(' [targets] ')'
	#     #     | '[' [targets] ']'
	#     element NAME
	#     element concatenation('(', targets.optional, ')')
	#     element concatenation('[', targets.optional, ']')
	# end

	# NOTE: yield_expression may start with 'yield'; yield_expr must start with 'yield'
	# assignment:
	#     | !'lambda' target ':' expression ['=' yield_expression]
	#     | (star_targets '=')+ (yield_expr | expressions)
	#     | target augassign (yield_expr | expressions)


	# NOTE: assignment MUST precede expression, else the parser will get stuck;
	# but it must follow all others, else reserved words will match a simple NAME.
	# small_stmt:
	#     | return_stmt
	#     | import_stmt
	#     | pass_stmt
	#     | raise_stmt
	#     | yield_stmt
	#     | assert_stmt
	#     | del_stmt
	#     | global_stmt
	#     | nonlocal_stmt
	#     | break_stmt
	#     | continue_stmt
	#     | assignment
	#     | expressions
	SmallStatement = alternation do
	    element Return: concatenation('return', concatenation(/\s+/, exprlist).optional)	# return_stmt: 'return' [expressions]
	    element Import: (import_name | import_from)					# import_stmt: import_name | import_from
	    element Pass: 'pass'							# pass_stmt: 'pass'
	    element Raise: concatenation('raise', concatenation(Test, concatenation('from', Test).optional).optional)	# raise_stmt: 'raise' [_test ['from' _test]]
	    element Yield: yield_expr							# yield_stmt: yield_expr
	    element Assert: concatenation('assert', Test, concatenation(',', Test).optional)	# assert_stmt: 'assert' test [',' test]
	    element Delete: concatenation('del', exprlist)				# del_stmt: 'del' exprlist
	    element Global: concatenation('global', NAME, concatenation(',', NAME).any)	# global_stmt: 'global' NAME (',' NAME)*
	    element NonLocal: concatenation('nonlocal', NAME, concatenation(',', NAME).any)	# nonlocal_stmt: 'nonlocal' NAME (',' NAME)*
	    element Break: 'break'							# break_stmt: 'break'
	    element Continue: 'continue'						# continue_stmt: 'continue'
	 #    element Assignment: alternation {
		# element concatenation(target, ':', Expression, concatenation('=', yield_expression).optional)
		# element concatenation(concatenation(star_targets, '=').one_or_more, (yield_expression | expressions))
		# element concatenation(target, augassign, (yield_expression | expressions))
	 #    }
	 #    element expressions
	end

	# @endgroup

	# NB compile.c makes sure that the default except clause is last
	# except_clause: 'except' [test ['as' NAME]]
	except_clause = concatenation('except', concatenation(Test, concatenation('as', NAME).optional))

	FunctionParameter = alternation do
	    element PlainName: concatenation(NAME, concatenation(':', Test).optional)
	    element NameWithDefault: concatenation(PlainName, '=', Test)
	    element StarName: concatenation('*', PlainName.optional)
	    element DoubleStarName: concatenation('**', PlainName.optional)
	end

	FunctionParameters = concatenation(FunctionParameter, concatenation(/\s*,\s*/, FunctionParameter).any, /(\s*,)?/)

	# stmt: simple_stmt | compound_stmt
	Statement = alternation do |stmt|
	    # simple_stmt: small_stmt (';' small_stmt)* [';'] NEWLINE
	    element Simple: concatenation(SmallStatement, concatenation(';', SmallStatement).any, ';'.optional)

	    # suite: simple_stmt | NEWLINE INDENT stmt+ DEDENT
	    suite = Simple | concatenation(NEWLINE, INDENT, stmt.one_or_more, DEDENT)
	    Block = suite

	    # funcdef: 'def' NAME parameters ['->' test] ':' suite
	    element FunctionDefinition: concatenation('async'.optional, /\s*/, 'def', /\s*/, NAME, /\s*/, '(', /\s*/, FunctionParameters.optional, /\s*/, ')', concatenation('->', Test).optional, ':', /[[:blank:]]*/, Block)

	    # classdef: 'class' NAME ['(' [arglist] ')'] ':' suite
	    classdef = concatenation('class', NAME, concatenation('(', arglist.optional, ')').optional, ':', suite)

	    # decorator: '@' dotted_name [ '(' [arglist] ')' ] NEWLINE
	    decorator = concatenation('@', dotted_name, concatenation('(', arglist.optional, ')'), NEWLINE)

	    # decorators: decorator+
	    decorators = decorator.one_or_more

	    # decorated: decorators (classdef | funcdef | async_funcdef)
	    decorated = concatenation(decorators, (classdef | FunctionDefinition))

	    # @group Compound Statements

	    # for_stmt: 'for' exprlist 'in' testlist ':' suite ['else' ':' suite]
	    element For: concatenation('async'.optional, /\s*/, 'for', exprlist, 'in', testlist, ':', suite, concatenation('else', ':', suite).optional)

	    # with_item: test ['as' expr]
	    with_item = concatenation(Test, concatenation('as', Expression).optional)

	    # with_stmt: 'with' with_item (',' with_item)*  ':' suite
	    element With: concatenation('async'.optional, /\s*/, 'with', with_item, concatenation(',', with_item).any,  ':', suite)

	    # if_stmt: 'if' test ':' suite ('elif' test ':' suite)* ['else' ':' suite]
	    element If: concatenation('if', Test, ':', suite, concatenation('elif', Test, ':', suite).any, concatenation('else', ':', suite).optional)

	    # while_stmt: 'while' test ':' suite ['else' ':' suite]
	    element While: concatenation('while', Test, ':', suite, concatenation('else', ':', suite).optional)

	    # try_stmt: ('try' ':' suite
	    # 	   ((except_clause ':' suite)+
	    # 	    ['else' ':' suite]
	    # 	    ['finally' ':' suite] |
	    # 	   'finally' ':' suite))
	    try_stmt = concatenation(
		'try', ':', suite,
		alternation(
		    concatenation(
			concatenation(except_clause, ':', suite).one_or_more,
			concatenation('else', ':', suite).optional,
			concatenation('finally', ':', suite).optional
		    ),
		    concatenation('finally', ':', suite)
		)
	    )

	    # compound_stmt: if_stmt | while_stmt | for_stmt | try_stmt | with_stmt | funcdef | classdef | decorated | async_stmt
	    # async_stmt: 'async' (funcdef | with_stmt | for_stmt)
	    element try_stmt
	    element classdef
	    element decorated
	end

	# file_input: (NEWLINE | stmt)* ENDMARKER
	Statements = (NEWLINE | Statement).any
    end
end
