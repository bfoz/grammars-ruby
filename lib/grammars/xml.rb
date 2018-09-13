module Grammars
    # https://www.w3.org/TR/REC-xml/
    # https://www.w3.org/TR/2006/REC-xml11-20060816/
    module XML
	using Grammar::DSL

	# [3]	S	   	::=   	(#x20 | #x9 | #xD | #xA)+
	S = /[ \t\r\n]+/

	# [26]	VersionNum	::=   	'1.1'
	VersionNum = '1.1'

	# [25]	Eq	   	::=   	S? '=' S?
	Eq = concatenation(S.optional, '=', S.optional)

	# [24]	VersionInfo	::=   	S 'version' Eq ("'" VersionNum "'" | '"' VersionNum '"')
	VersionInfo = concatenation(S, 'version', Eq, concatenation("'", VersionNum, "'") | concatenation('"', VersionNum, '"'))

	# [23]	XMLDecl		::=   	'<?xml' VersionInfo EncodingDecl? SDDecl? S? '?>'
	XMLDecl = concatenation('<?xml', VersionInfo, EncodingDecl.optional, SDDecl.optional, S.optional, '?>')

	# [28a]	DeclSep		::=   	PEReference | S
	DeclSep = PEReference | S

	# [75]	ExternalID	::=   	'SYSTEM' S SystemLiteral | 'PUBLIC' S PubidLiteral S SystemLiteral
	ExternalID = concatenation('SYSTEM', S, SystemLiteral) | concatenation('PUBLIC', S, PubidLiteral, S, SystemLiteral)

	# [83]	PublicID	::=   	'PUBLIC' S PubidLiteral
	PublicID = concatenation('PUBLIC', S, PubidLiteral)

	# [82]	NotationDecl	::=   	'<!NOTATION' S Name S (ExternalID | PublicID) S? '>'
	NotationDecl = concatenation('<!NOTATION', S, Name, S, (ExternalID | PublicID), S.optional, '>')

	# [29]	markupdecl	::=   	elementdecl | AttlistDecl | EntityDecl | NotationDecl | PI | Comment
	markupdecl = elementdecl | AttlistDecl | EntityDecl | NotationDecl | PI | Comment

	# [28b]	intSubset	::=   	(markupdecl | DeclSep)*
	intSubset = alternation(markupdecl, DeclSep).any

	# [28]	doctypedecl	::=   	'<!DOCTYPE' S Name (S ExternalID)? S? ('[' intSubset ']' S?)? '>'
	doctypedecl = concatenation('<!DOCTYPE', S, Name, concatenation(S, ExternalID).optional, S.optional, concatenation('[', intSubset, ']', S.optional).optional, '>')

	# [22]	prolog		::=   	XMLDecl Misc* (doctypedecl Misc*)?
	Prolog = concatenation(XMLDecl, Misc.any, concatenation(doctypedecl, Misc.any).optional)

	# [1] document		::=   	( prolog element Misc* ) - ( Char* RestrictedChar Char* )
	Document = concatenation(Prolog, Element, Misc.any)

	# [2] 	Char		::=   	[#x1-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]
	Char = /[\u0001-\uD7FF\uE000-\uFFFD\u{10000}-\u{10FFFF}]/

	# [2a]	RestrictedChar	::=   	[#x1-#x8] | [#xB-#xC] | [#xE-#x1F] | [#x7F-#x84] | [#x86-#x9F]
	RestrictedChar = /[\u0001-\u0008\u000B-\u000C\u000E-\u001F\u007F-\u0084\u0086-\u009F]/

	# [4]   NameStartChar	::=   	":" | [A-Z] | "_" | [a-z] | [#xC0-#xD6] | [#xD8-#xF6] | [#xF8-#x2FF] | [#x370-#x37D] | [#x37F-#x1FFF] | [#x200C-#x200D] | [#x2070-#x218F] | [#x2C00-#x2FEF] | [#x3001-#xD7FF] | [#xF900-#xFDCF] | [#xFDF0-#xFFFD] | [#x10000-#xEFFFF]
	# [4a]  NameChar	::=   	NameStartChar | "-" | "." | [0-9] | #xB7 | [#x0300-#x036F] | [#x203F-#x2040]
	# [5]   Name		::=   	NameStartChar (NameChar)*
	Name = /[\w:][\w\.\-:]*/

	# [6]   Names		::=   	Name (#x20 Name)*
	Names = concatenation(Name, concatenation(' ', Name).any)

	# [7]   Nmtoken		::=   	(NameChar)+
	Nmtoken = NameChar.one_or_more

	# [8]   Nmtokens	::=   	Nmtoken (#x20 Nmtoken)*
	Nmtokens = concatenation(Nmtoken, concatenation(' ', Nmtoken).any)

	# [9]	EntityValue	::=   	'"' ([^%&"] | PEReference | Reference)* '"' |  "'" ([^%&'] | PEReference | Reference)* "'"
	EntityValue = concatenation('"', (/[^%&"]/ | PEReference | Reference).any, '"') | concatenation("'", (/[^%&']/ | PEReference | Reference).any, "'")

	# [10]	AttValue	::=   	'"' ([^<&"] | Reference)* '"' |  "'" ([^<&'] | Reference)* "'"
	AttValue = concatenation('"', alternation(/[^<&"]*/, Reference).any, '"') | concatenation("'", alternation(/[^<&"]*/, Reference).any, "'")

	# [11]	SystemLiteral	::=   	('"' [^"]* '"') | ("'" [^']* "'")
	SystemLiteral = concatenation('"', /[^"]*/, '"') | concatenation("'", /[^']*/, "'")

	# [13]	PubidChar	::=   	#x20 | #xD | #xA | [a-zA-Z0-9] | [-'()+,./:=?;!*#@$_%]
	PubidChar0 = /[a-zA-Z0-9\-'\(-\,\.\/:=\?;!#@\$_%]/
	PubidChar1 = /[a-zA-Z0-9\-"\(-\,\.\/:=\?;!#@\$_%]/

	# [12]	PubidLiteral	::=   	'"' PubidChar* '"' | "'" (PubidChar - "'")* "'"
	PubidLiteral = concatenation('"', PubidChar0.any, '"') | concatenation("'", PubidChar1.any, "'")

	# [14]	CharData	::=   	[^<&]* - ([^<&]* ']]>' [^<&]*)
	# CharData = /[^<&]*/

	# [15]	Comment		::=   	'<!--' ((Char - '-') | ('-' (Char - '-')))* '-->'
	Comment = concatenation('<!--', Char.except('-') | concatenation('-', Char.except('-')).any, '-->')

	# [17]	PITarget	::=   	Name - (('X' | 'x') ('M' | 'm') ('L' | 'l'))
	PITarget = Name.except(/[xX][mM][lL]/)

	# [16]	PI		::=   	'<?' PITarget (S (Char* - (Char* '?>' Char*)))? '?>'
	PI = concatenation('<?', PITarget, concatenation(S, (Char.any.except(concatenation(Char.any, '?>', Char.any)))).optional, '?>')

	# [18]	CDSect		::=   	CDStart CData CDEnd
	# [19]	CDStart		::=   	'<![CDATA['
	# [21]	CDEnd		::=   	']]>'
	CDSect = concatenation('<![CDATA[', CData, ']]>')

	# [20]	CData		::=   	(Char* - (Char* ']]>' Char*))
	# CData = Char.any.except(concatenation(Char.any, ']]>', Char.any))
	CData = Char.any.until(']]>')

	# [27]	Misc	   	::=   	Comment | PI | S
	Misc = Comment | PI | S

	# [31]	extSubsetDecl	::=   	( markupdecl | conditionalSect | DeclSep)*
	extSubsetDecl = (markupdeclm | conditionalSect | DeclSep).any

	# [30]	extSubset	::=   	TextDecl? extSubsetDecl
	extSubset = concatenation(TextDecl.optional, extSubsetDecl)

	# [32]	SDDecl	   	::=   	S 'standalone' Eq (("'" ('yes' | 'no') "'") | ('"' ('yes' | 'no') '"'))
	SDDecl = concatenation(S, 'standalone', Eq, (concatenation("'", ('yes' | 'no'), "'") | concatenation('"', ('yes' | 'no'), '"')))

	# [41]	Attribute	::=   	Name Eq AttValue
	Attribute = concatenation(Name, Eq, AttValue)

	# [40]	STag	   	::=   	'<' Name (S Attribute)* S? '>'
	STag = concatenation('<', Name, concatenation(S, Attribute).any, S.optional, '>')

	# [42]	ETag	   	::=   	'</' Name S? '>'
	ETag = concatenation('</', Name, S.optional, '>')

	# [43]	content	   	::=   	CharData? ((element | Reference | CDSect | PI | Comment) CharData?)*
	content = concatenation(CharData.optional, concatenation((element | Reference | CDSect | PI | Comment), CharData.optional).any)

	# [44]	EmptyElemTag	::=   	'<' Name (S Attribute)* S? '/>'
	EmptyElemTag = concatenation('<', Name, concatenation(S, Attribute).any, S.optional, '/>')

	# [39]	element	   	::=   	EmptyElemTag | STag content ETag
	element = EmptyElemTag | concatenation(STag, content, ETag)

	# [45]	elementdecl	::=   	'<!ELEMENT' S Name S contentspec S? '>'
	elementdecl = concatenation('<!ELEMENT', S, Name, S, contentspec, S.optional, '>')

	# [48]	cp	   	::=   	(Name | choice | seq) ('?' | '*' | '+')?
	cp = concatenation(Name | choice | seq, '?', '*', '+')

	# [49]	choice	   	::=   	'(' S? cp ( S? '|' S? cp )+ S? ')'
	choice = concatenation('(', S.optional, cp, concatenation(S.optional, '|', S.optional, cp).one_or_more, S.optional, ')')

	# [50]	seq	   	::=   	'(' S? cp ( S? ',' S? cp )* S? ')'
	seq = concatenation('(', S.optional, cp, concatenation(S.optional, ',', S.optional, cp).any, S.optional, ')')

	# [47]	children	::=   	(choice | seq) ('?' | '*' | '+')?
	children = concatenation(choice | seq, '?' | '*' | '+')

	# [51]	Mixed	   	::=   	'(' S? '#PCDATA' (S? '|' S? Name)* S? ')*' | '(' S? '#PCDATA' S? ')'
	Mixed = concatenation('(', S.optional, '#PCDATA', concatenation(S.optional, '|'. S.optional, Name).any, S.optional, ')*') | concatenation('(', S.optional, '#PCDATA', S?, ')')

	# [46]	contentspec	::=   	'EMPTY' | 'ANY' | Mixed | children
	contentspec = 'EMPTY' | 'ANY' | Mixed | children

	# [58]	NotationType	::=   	'NOTATION' S '(' S? Name (S? '|' S? Name)* S? ')'
	NotationType = concatenation('NOTATION', S, '(', S.optional, Name, concatenation(S.optional, '|', S.optional, Name).any, S.optional, ')')

	# [59]	Enumeration	::=   	'(' S? Nmtoken (S? '|' S? Nmtoken)* S? ')'
	Enumeration = concatenation('(', S.optional, Nmtoken, concatenation(S.optional, '|', S.optional, Nmtoken).any, S.optional, ')')

	# [54]	AttType	   	::=   	StringType | TokenizedType | EnumeratedType
	# [55]	StringType	::=   	'CDATA'
	# [56]	TokenizedType	::=   	'ID' | 'IDREF'	 | 'IDREFS'	 | 'ENTITY'	 | 'ENTITIES'	 | 'NMTOKEN' | 'NMTOKENS'
	# [57]	EnumeratedType	::=   	NotationType | Enumeration
	AttType = 'CDATA' | 'ID' | 'IDREF' | 'IDREFS' | 'ENTITY' | 'ENTITIES' | 'NMTOKEN' | 'NMTOKENS' | NotationType | Enumeration

	# [53]	AttDef	   	::=   	S Name S AttType S DefaultDecl
	AttDef = concatenation(S, Name, S, AttType, S, DefaultDecl)

	# [52]	AttlistDecl	::=   	'<!ATTLIST' S Name AttDef* S? '>'
	AttlistDecl = concatenation('<!ATTLIST', S, Name, AttDef.any, S.optional, '>')

	# [60]	DefaultDecl	::=   	'#REQUIRED' | '#IMPLIED' | (('#FIXED' S)? AttValue)
	DefaultDecl = '#REQUIRED' | '#IMPLIED' | concatenation(concatenation('#FIXED', S).optional, AttValue)

	# [62]	includeSect	::=   	'<![' S? 'INCLUDE' S? '[' extSubsetDecl ']]>'
	includeSect = concatenation('<![', S.optional, 'INCLUDE', S.optional, '[', extSubsetDecl, ']]>')

	# [65]	Ignore	   	::=   	Char* - (Char* ('<![' | ']]>') Char*)
	Ignore = Char.any.except()

	# [64]	ignoreSectContents	   ::=   	Ignore ('<![' ignoreSectContents ']]>' Ignore)*
	ignoreSectContents = concatenation(Ignore, concatenation('<![', ignoreSectContents, ']]>', Ignore).any)

	# [63]	ignoreSect	::=   	'<![' S? 'IGNORE' S? '[' ignoreSectContents* ']]>'
	ignoreSect = concatenation('<![', S.optional, 'IGNORE', S.optional, '[', ignoreSectContents.any, ']]>')

	# [61]	conditionalSect	::=   	includeSect | ignoreSect
	conditionalSect = includeSect | ignoreSect

	# [66]	CharRef	   	::=   	'&#' [0-9]+ ';' | '&#x' [0-9a-fA-F]+ ';'
	CharRef = concatenation('&#', /[0-9]+/, ';') | concatenation('&#x', /[0-9a-fA-F]+/, ';')

	# [67]	Reference	::=   	EntityRef | CharRef
	Reference = EntityRef | CharRef

	# [68]	EntityRef	::=   	'&' Name ';'
	EntityRef = concatenation('&', Name, ';')

	# [69]	PEReference	::=   	'%' Name ';'
	PEReference = concatenation('%', Name, ';')

	# [76]	NDataDecl	::=   	S 'NDATA' S Name
	NDataDecl = concatenation(S, 'NDATA', S, Name)

	# [73]	EntityDef	::=   	EntityValue | (ExternalID NDataDecl?)
	EntityDef = EntityValue | concatenation(ExternalID, NDataDecl.optional)

	# [71]	GEDecl	   	::=   	'<!ENTITY' S Name S EntityDef S? '>'
	GEDecl = concatenation('<!ENTITY', S, Name, S, EntityDef, S.optional, '>')

	# [74]	PEDef	   	::=   	EntityValue | ExternalID
	PEDef = EntityValue | ExternalID

	# [72]	PEDecl	   	::=   	'<!ENTITY' S '%' S Name S PEDef S? '>'
	PEDecl = concatenation('<!ENTITY', S, '%', S, Name, S, PEDef, S.optional, '>')

	# [70]	EntityDecl	::=   	GEDecl | PEDecl
	EntityDecl = GEDecl | PEDecl

	# [78]	extParsedEnt	::=   	( TextDecl? content ) - ( Char* RestrictedChar Char* )
	extParsedEnt = concatenation(TextDecl.optional, content).except(Char.any, RestrictedChar, Char.any)

	# [81]	EncName	   	::=   	[A-Za-z] ([A-Za-z0-9._] | '-')*
	EncName = /[A-Za-z][A-Za-z0-9\._\-]*/

	# [80]	EncodingDecl	::=   	S 'encoding' Eq ('"' EncName '"' | "'" EncName "'" )
	EncodingDecl = concatenation(S, 'encoding', Eq, concatenation('"', EncName, '"') | concatenation("'", EncName, "'" ))

	# [77]	TextDecl	::=   	'<?xml' VersionInfo? EncodingDecl S? '?>'
	TextDecl = concatenation('<?xml', VersionInfo.optional, EncodingDecl, S.optional, '?>')
    end
end
