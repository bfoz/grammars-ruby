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
	NAME = /\s+/
	NEWLINE = /\n/

	BINARY_NUMBER = /0[bB][01_]+/
	DECIMAL_NUMBER = /[+\-]?\d+(\.\d+)?/
	HEXADECIMAL_NUMBER = /0[xX][0-9a-fA-F_]+/
	OCTAL_NUMBER = /0[oO][0-7_]+/
	NUMBER = BINARY_NUMBER | DECIMAL_NUMBER | HEXADECIMAL_NUMBER | OCTAL_NUMBER

	STRING = /\s/

	# @group Expression

	# test: or_test ['if' or_test 'else' test] | lambdef
	arglist = nil
	expr = nil
	exprlist = nil
	star_expr = nil
	testlist = nil
	testlist_star_expr = nil
	yield_expr = nil
	_test = alternation do |_test|

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

		# comparison: expr (comp_op expr)*
		comparison = concatenation(expr, concatenation(comp_op, expr).any)

		# not_test: 'not' not_test | comparison
		not_test = alternation do |_not_test|
		    element concatenation('not', /\s*/, _not_test)
		    element comparison
		end

		# and_test: not_test ('and' not_test)*
		and_test = concatenation(not_test, concatenation('and', not_test).any)

		# or_test: and_test ('or' and_test)*
		or_test = concatenation(and_test, concatenation('or', and_test).any)

		# star_expr: '*' expr
		star_expr = concatenation('*', expr)

		# exprlist: (expr|star_expr) (',' (expr|star_expr))* [',']
		exprlist = concatenation((expr|star_expr), concatenation(',', (expr|star_expr)).any, ','.optional)

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
		atom = concatenation('(', (yield_expr | testlist_comp).optional, ')') |
		       concatenation('[', testlist_comp.optional, ']') |
		       concatenation('{', dictorsetmaker.optional, '}') |
		       NAME | NUMBER | STRING.one_or_more | '...' | 'None' | 'True' | 'False'

		# atom_expr: ['await'] atom trailer*
		atom_expr = concatenation('await'.optional, atom, trailer.any)

		# factor: ('+'|'-'|'~') factor | power
		factor = alternation do |factor|
		    # power: atom_expr ['**' factor]
		    power = concatenation(atom_expr, concatenation('**', factor).optional)

		    element concatenation(('+'|'-'|'~'), factor)
		    element power
		end

		# term: factor (('*'|'@'|'/'|'%'|'//') factor)*
		term = concatenation(factor, concatenation(('*'|'@'|'/'|'%'|'//'), factor).any)

		# arith_expr: term (('+'|'-') term)*
		arith_expr = concatenation(term, concatenation(('+'|'-'), term).any)

		# shift_expr: arith_expr (('<<'|'>>') arith_expr)*
		shift_expr = concatenation(arith_expr, concatenation(('<<'|'>>'), arith_expr).any)

		# and_expr: shift_expr ('&' shift_expr)*
		and_expr = concatenation(shift_expr, concatenation('&', shift_expr).any)

		# xor_expr: and_expr ('^' and_expr)*
		xor_expr = concatenation(and_expr, concatenation('^', and_expr).any)

		element xor_expr
		element concatenation('|', xor_expr).any
	    end

	    # @endgroup Expression

	    element concatenation(or_test, concatenation('if', or_test, 'else', _test).optional)
	    element lambdef
	end

	# @group Statements

	# testlist_star_expr: (test|star_expr) (',' (test|star_expr))* [',']
	testlist_star_expr = concatenation(_test|star_expr, concatenation(',', _test|star_expr).any, ','.optional)

	# For normal and annotated assignments, additional restrictions enforced by the interpreter

	# annassign: ':' test ['=' test]
	annassign = concatenation(':', _test, concatenation('=', _test).optional)

	# augassign: ('+=' | '-=' | '*=' | '@=' | '/=' | '%=' | '&=' | '|=' | '^=' |
	#             '<<=' | '>>=' | '**=' | '//=')
	augassign = ('+=' | '-=' | '*=' | '@=' | '/=' | '%=' | '&=' | '|=' | '^=' | '<<=' | '>>=' | '**=' | '//=')

	# expr_stmt: testlist_star_expr (annassign | augassign (yield_expr|testlist) |
	#                      ('=' (yield_expr|testlist_star_expr))*)
	expr_stmt = concatenation(
	    testlist_star_expr,
	    (annassign | concatenation(augassign, (yield_expr|testlist)) | concatenation('=', (yield_expr|testlist_star_expr)).any)
	)

	# del_stmt: 'del' exprlist
	del_stmt = concatenation('del', exprlist)

	# pass_stmt: 'pass'
	pass_stmt = 'pass'

	# break_stmt: 'break'
	break_stmt = 'break'

	# continue_stmt: 'continue'
	continue_stmt =  'continue'

	# return_stmt: 'return' [testlist]
	return_stmt = concatenation('return', testlist.optional)

	# yield_stmt: yield_expr
	yield_stmt = yield_expr

	# raise_stmt: 'raise' [_test ['from' _test]]
	raise_stmt = concatenation('raise', concatenation(_test, concatenation('from', _test).optional).optional)

	# flow_stmt: break_stmt | continue_stmt | return_stmt | raise_stmt | yield_stmt
	flow_stmt = break_stmt | continue_stmt | return_stmt | raise_stmt | yield_stmt


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

	# import_stmt: import_name | import_from
	import_stmt = import_name | import_from

	# global_stmt: 'global' NAME (',' NAME)*
	global_stmt = concatenation('global', NAME, concatenation(',', NAME).any)

	# nonlocal_stmt: 'nonlocal' NAME (',' NAME)*
	nonlocal_stmt = concatenation('nonlocal', NAME, concatenation(',', NAME).any)

	# assert_stmt: 'assert' test [',' test]
	assert_stmt = concatenation('assert', _test, concatenation(',', _test).optional)

	# small_stmt: (expr_stmt | del_stmt | pass_stmt | flow_stmt |
	#              import_stmt | global_stmt | nonlocal_stmt | assert_stmt)
	small_stmt = expr_stmt | del_stmt | pass_stmt | flow_stmt | import_stmt | global_stmt | nonlocal_stmt | assert_stmt

	# simple_stmt: small_stmt (';' small_stmt)* [';'] NEWLINE
	SimpleStatement = concatenation(small_stmt, concatenation(';', small_stmt).any, ';'.optional, NEWLINE)

	# @endgroup

	# NB compile.c makes sure that the default except clause is last
	# except_clause: 'except' [test ['as' NAME]]
	except_clause = concatenation('except', concatenation(_test, concatenation('as', NAME).optional))

	# tfpdef: NAME [':' test]
	tfpdef = concatenation(NAME, concatenation(':', _test).optional)

	# typedargslist: (tfpdef ['=' test] (',' tfpdef ['=' test])* [',' [
	#         '*' [tfpdef] (',' tfpdef ['=' test])* [',' ['**' tfpdef [',']]]
	#       | '**' tfpdef [',']]]
	#   | '*' [tfpdef] (',' tfpdef ['=' test])* [',' ['**' tfpdef [',']]]
	#   | '**' tfpdef [','])
	typedargslist = alternation(
	    concatenation(
		tfpdef,
		concatenation('=', _test),
		concatenation(
			',',
			tfpdef,
			concatenation('=', _test).optional
		).any,
		concatenation(
			',',
			concatenation(
				'*',
				tfpdef.optional,
				concatenation(
					',',
					tfpdef,
					concatenation('=', _test).optional
				).any,
				alternation(
					concatenation(
						',',
						concatenation('**', tfpdef, ','.optional).optional
					).optional,
				 	concatenation('**', tfpdef, ','.optional)
				)
			).optional
		).optional
	    ),
	    concatenation('*',
		tfpdef.optional,
		concatenation(
			',',
			tfpdef,
			concatenation('=', _test).optional
		).any,
		concatenation(
			',',
			concatenation('**', tfpdef, ','.optional).optional
		).optional
	    ),
	    concatenation('**', tfpdef, ','.optional)
	)

	# stmt: simple_stmt | compound_stmt
	compound_stmt = nil
	stmt = alternation do |stmt|

	    # suite: simple_stmt | NEWLINE INDENT stmt+ DEDENT
	    suite = SimpleStatement | concatenation(NEWLINE, INDENT, stmt.one_or_more, DEDENT)

	    # parameters: '(' [typedargslist] ')'
	    parameters = concatenation('(', typedargslist.optional, ')')

	    # funcdef: 'def' NAME parameters ['->' test] ':' suite
	    funcdef = concatenation('def', NAME, parameters, concatenation('->', _test).optional, ':', suite)

	    # async_funcdef: 'async' funcdef
	    async_funcdef = concatenation('async', funcdef)

	    # classdef: 'class' NAME ['(' [arglist] ')'] ':' suite
	    classdef = concatenation('class', NAME, concatenation('(', arglist.optional, ')').optional, ':', suite)

	    # decorator: '@' dotted_name [ '(' [arglist] ')' ] NEWLINE
	    decorator = concatenation('@', dotted_name, concatenation('(', arglist.optional, ')'), NEWLINE)

	    # decorators: decorator+
	    decorators = decorator.one_or_more

	    # decorated: decorators (classdef | funcdef | async_funcdef)
	    decorated = concatenation(decorators, (classdef | funcdef | async_funcdef))

	    # @group Compound Statements

	    # for_stmt: 'for' exprlist 'in' testlist ':' suite ['else' ':' suite]
	    for_stmt = concatenation('for', exprlist, 'in', testlist, ':', suite, concatenation('else', ':', suite).optional)

	    # with_item: test ['as' expr]
	    with_item = concatenation(_test, concatenation('as', Expression).optional)

	    # with_stmt: 'with' with_item (',' with_item)*  ':' suite
	    with_stmt = concatenation('with', with_item, concatenation(',', with_item).any,  ':', suite)

	    # async_stmt: 'async' (funcdef | with_stmt | for_stmt)
	    async_stmt = concatenation('async', (funcdef | with_stmt | for_stmt))

	    # if_stmt: 'if' test ':' suite ('elif' test ':' suite)* ['else' ':' suite]
	    if_stmt = concatenation('if', _test, ':', suite, concatenation('elif', _test, ':', suite).any, concatenation('else', ':', suite).optional)

	    # while_stmt: 'while' test ':' suite ['else' ':' suite]
	    while_stmt = concatenation('while', _test, ':', suite, concatenation('else', ':', suite).optional)

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
	    compound_stmt = if_stmt | while_stmt | for_stmt | try_stmt | with_stmt | funcdef | classdef | decorated | async_stmt

	    # @endgroup Compound Statements

	    element SimpleStatement
	    element compound_stmt
	end

	# single_input: NEWLINE | simple_stmt | compound_stmt NEWLINE
	single_input = NEWLINE | SimpleStatement | concatenation(compound_stmt, NEWLINE)

	# file_input: (NEWLINE | stmt)* ENDMARKER
	file_input = concatenation((NEWLINE | stmt).any, ENDMARKER)

	# eval_input: testlist NEWLINE* ENDMARKER
	TestList = testlist
	EvalInput = concatenation(TestList, NEWLINE.any, ENDMARKER)

	# not used in grammar, but may appear in "node" passed from Parser to Compiler
	# encoding_decl: NAME
    end
end
