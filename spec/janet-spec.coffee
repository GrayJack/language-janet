# describe "Janet grammar", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("language-janet")

    runs ->
      grammar = atom.grammars.grammarForScopeName("source.janet")

  it "parses the grammar", ->
    expect(grammar).toBeDefined()
    expect(grammar.scopeName).toBe "source.janet"

  it "tokenizes comments", ->
    {tokens} = grammar.tokenizeLine "# janet"
    expect(tokens[0]).toEqual value: "#", scopes: ["source.janet", "comment.line.semicolon.janet", "punctuation.definition.comment.janet"]
    # expect(tokens[1]).toEqual value: " janet", scopes: ["source.janet", "comment.line.semicolon.janet"]

  it "tokenizes shebang comments", ->
    {tokens} = grammar.tokenizeLine "#!/usr/bin/env janet"
    expect(tokens[0]).toEqual value: "#!", scopes: ["source.janet", "comment.line.shebang.janet", "punctuation.definition.comment.shebang.janet"]
    expect(tokens[1]).toEqual value: "/usr/bin/env janet", scopes: ["source.janet", "comment.line.shebang.janet"]

  it "tokenizes strings", ->
    {tokens} = grammar.tokenizeLine '"foo bar"'
    expect(tokens[0]).toEqual value: '"', scopes: ["source.janet", "string.quoted.double.janet", "punctuation.definition.string.begin.janet"]
    expect(tokens[1]).toEqual value: 'foo bar', scopes: ["source.janet", "string.quoted.double.janet"]
    expect(tokens[2]).toEqual value: '"', scopes: ["source.janet", "string.quoted.double.janet", "punctuation.definition.string.end.janet"]

  it "tokenizes character escape sequences", ->
    {tokens} = grammar.tokenizeLine '"\\n"'
    expect(tokens[0]).toEqual value: '"', scopes: ["source.janet", "string.quoted.double.janet", "punctuation.definition.string.begin.janet"]
    expect(tokens[1]).toEqual value: '\\n', scopes: ["source.janet", "string.quoted.double.janet", "constant.character.escape.janet"]
    expect(tokens[2]).toEqual value: '"', scopes: ["source.janet", "string.quoted.double.janet", "punctuation.definition.string.end.janet"]

  it "tokenizes regexes", ->
    {tokens} = grammar.tokenizeLine '"foo"'
    expect(tokens[0]).toEqual value: '"', scopes: ["source.janet", "string.regexp.janet", "punctuation.definition.regexp.begin.janet"]
    expect(tokens[1]).toEqual value: 'foo', scopes: ["source.janet", "string.regexp.janet"]
    expect(tokens[2]).toEqual value: '"', scopes: ["source.janet", "string.regexp.janet", "punctuation.definition.regexp.end.janet"]

  # it "tokenizes backslash escape character in regexes", ->
  #   {tokens} = grammar.tokenizeLine '"\\\\" "/"'
  #   expect(tokens[0]).toEqual value: '#"', scopes: ["source.janet", "string.regexp.janet", "punctuation.definition.regexp.begin.janet"]
  #   expect(tokens[1]).toEqual value: "\\\\", scopes: ['source.janet', 'string.regexp.janet', 'constant.character.escape.janet']
  #   expect(tokens[2]).toEqual value: '"', scopes: ['source.janet', 'string.regexp.janet', "punctuation.definition.regexp.end.janet"]
  #   expect(tokens[4]).toEqual value: '"', scopes: ['source.janet', 'string.quoted.double.janet', 'punctuation.definition.string.begin.janet']
  #   expect(tokens[5]).toEqual value: "/", scopes: ['source.janet', 'string.quoted.double.janet']
  #   expect(tokens[6]).toEqual value: '"', scopes: ['source.janet', 'string.quoted.double.janet', 'punctuation.definition.string.end.janet']
  #
  # it "tokenizes escaped double quote in regexes", ->
  #   {tokens} = grammar.tokenizeLine '#"\\""'
  #   expect(tokens[0]).toEqual value: '#"', scopes: ["source.janet", "string.regexp.janet", "punctuation.definition.regexp.begin.janet"]
  #   expect(tokens[1]).toEqual value: '\\"', scopes: ['source.janet', 'string.regexp.janet', 'constant.character.escape.janet']
  #   expect(tokens[2]).toEqual value: '"', scopes: ['source.janet', 'string.regexp.janet', "punctuation.definition.regexp.end.janet"]

  it "tokenizes numerics", ->
    numbers =
      # "constant.numeric.ratio.janet": ["1/2", "123/456"]
      "constant.numeric.arbitrary-radix.janet": ["2R1011", "16rDEADBEEF"]
      "constant.numeric.hexadecimal.janet": ["0xDEADBEEF", "0XDEADBEEF"]
      # "constant.numeric.octal.janet": ["0123"]
      "constant.numeric.bigdecimal.janet": ["123.456M"]
      "constant.numeric.double.janet": ["123.45", "123.45e6", "123.45E6"]
      "constant.numeric.bigint.janet": ["123N"]
      "constant.numeric.long.janet": ["123", "12321"]

    for scope, nums of numbers
      for num in nums
        {tokens} = grammar.tokenizeLine num
        expect(tokens[0]).toEqual value: num, scopes: ["source.janet", scope]

  it "tokenizes booleans", ->
    booleans =
      "constant.language.boolean.janet": ["true", "false"]

    for scope, bools of booleans
      for bool in bools
        {tokens} = grammar.tokenizeLine bool
        expect(tokens[0]).toEqual value: bool, scopes: ["source.janet", scope]

  it "tokenizes nil", ->
    {tokens} = grammar.tokenizeLine "nil"
    expect(tokens[0]).toEqual value: "nil", scopes: ["source.janet", "constant.language.nil.janet"]

  it "tokenizes keywords", ->
    tests =
      "meta.expression.janet": ["(:foo)"]
      "meta.map.janet": ["{:foo}"]
      "meta.vector.janet": ["[:foo]"]
      "meta.quoted-expression.janet": ["'(:foo)", "`(:foo)"]

    for metaScope, lines of tests
      for line in lines
        {tokens} = grammar.tokenizeLine line
        expect(tokens[1]).toEqual value: ":foo", scopes: ["source.janet", metaScope, "constant.keyword.janet"]

    {tokens} = grammar.tokenizeLine "(def foo :bar)"
    expect(tokens[5]).toEqual value: ":bar", scopes: ["source.janet", "meta.expression.janet", "meta.definition.global.janet", "constant.keyword.janet"]

  it "tokenizes keyfns (keyword control)", ->
    keyfns = ["import", "require", "def", "def-", "defglobal", "var", "varglobal", "defn", "defn-", "defmacro", "defmacro-" "use"]

    for keyfn in keyfns
      {tokens} = grammar.tokenizeLine "(#{keyfn})"
      expect(tokens[1]).toEqual value: keyfn, scopes: ["source.janet", "meta.expression.janet", "keyword.control.janet"]

  it "tokenizes keyfns (storage control)", ->
    keyfns = ["if", "when", "unless", "for", "cond", "do", "let", "set", "binding", "loop", "fn", "throw", "try", "catch", "for", "while", "break"]

    for keyfn in keyfns
      {tokens} = grammar.tokenizeLine "(#{keyfn})"
      expect(tokens[1]).toEqual value: keyfn, scopes: ["source.janet", "meta.expression.janet", "storage.control.janet"]

  it "tokenizes global definitions", ->
    macros = ["def", "defn", "defn-", "var", "do", "quote", "if", "splice", "while", "set", "quasiquote", "unquote", "break"]

    for macro in macros
      {tokens} = grammar.tokenizeLine "(#{macro} foo 'bar)"
      expect(tokens[1]).toEqual value: macro, scopes: ["source.janet", "meta.expression.janet", "meta.definition.global.janet", "keyword.control.janet"]
      expect(tokens[3]).toEqual value: "foo", scopes: ["source.janet", "meta.expression.janet", "meta.definition.global.janet", "entity.global.janet"]

  it "tokenizes dynamic variables", ->
    mutables = ["@ns", "@foo-bar"]

    for mutable in mutables
      {tokens} = grammar.tokenizeLine mutable
      expect(tokens[0]).toEqual value: mutable, scopes: ["source.janet", "meta.symbol.dynamic.janet"]

  it "tokenizes metadata", ->
    {tokens} = grammar.tokenizeLine "^Foo"
    expect(tokens[0]).toEqual value: "^", scopes: ["source.janet", "meta.metadata.simple.janet"]
    expect(tokens[1]).toEqual value: "Foo", scopes: ["source.janet", "meta.metadata.simple.janet", "meta.symbol.janet"]

    {tokens} = grammar.tokenizeLine "^{:foo true}"
    expect(tokens[0]).toEqual value: "^{", scopes: ["source.janet", "meta.metadata.map.janet", "punctuation.section.metadata.map.begin.janet"]
    expect(tokens[1]).toEqual value: ":foo", scopes: ["source.janet", "meta.metadata.map.janet", "constant.keyword.janet"]
    expect(tokens[2]).toEqual value: " ", scopes: ["source.janet", "meta.metadata.map.janet"]
    expect(tokens[3]).toEqual value: "true", scopes: ["source.janet", "meta.metadata.map.janet", "constant.language.boolean.janet"]
    expect(tokens[4]).toEqual value: "}", scopes: ["source.janet", "meta.metadata.map.janet", "punctuation.section.metadata.map.end.trailing.janet"]

  it "tokenizes functions", ->
    expressions = ["(foo)", "(foo 1 10)"]

    for expr in expressions
      {tokens} = grammar.tokenizeLine expr
      expect(tokens[1]).toEqual value: "foo", scopes: ["source.janet", "meta.expression.janet", "entity.name.function.janet"]

  it "tokenizes vars", ->
    {tokens} = grammar.tokenizeLine "(func #'foo)"
    expect(tokens[2]).toEqual value: " #", scopes: ["source.janet", "meta.expression.janet"]
    expect(tokens[3]).toEqual value: "'foo", scopes: ["source.janet", "meta.expression.janet", "meta.var.janet"]

  it "tokenizes symbols", ->
    {tokens} = grammar.tokenizeLine "foo/bar"
    expect(tokens[0]).toEqual value: "foo", scopes: ["source.janet", "meta.symbol.namespace.janet"]
    expect(tokens[1]).toEqual value: "/", scopes: ["source.janet"]
    expect(tokens[2]).toEqual value: "bar", scopes: ["source.janet", "meta.symbol.janet"]

    {tokens} = grammar.tokenizeLine "x"
    expect(tokens[0]).toEqual value: "x", scopes: ["source.janet", "meta.symbol.janet"]

    # Should not be tokenized as a symbol
    {tokens} = grammar.tokenizeLine "1foobar"
    expect(tokens[0]).toEqual value: "1", scopes: ["source.janet", "constant.numeric.long.janet"]

  testMetaSection = (metaScope, puncScope, startsWith, endsWith) ->
    # Entire expression on one line.
    {tokens} = grammar.tokenizeLine "#{startsWith}foo, bar#{endsWith}"

    [start, mid..., end] = tokens

    expect(start).toEqual value: startsWith, scopes: ["source.janet", "meta.#{metaScope}.janet", "punctuation.section.#{puncScope}.begin.janet"]
    expect(end).toEqual value: endsWith, scopes: ["source.janet", "meta.#{metaScope}.janet", "punctuation.section.#{puncScope}.end.trailing.janet"]

    for token in mid
      expect(token.scopes.slice(0, 2)).toEqual ["source.janet", "meta.#{metaScope}.janet"]

    # Expression broken over multiple lines.
    tokens = grammar.tokenizeLines("#{startsWith}foo\n bar#{endsWith}")

    [start, mid..., after] = tokens[0]

    expect(start).toEqual value: startsWith, scopes: ["source.janet", "meta.#{metaScope}.janet", "punctuation.section.#{puncScope}.begin.janet"]

    for token in mid
      expect(token.scopes.slice(0, 2)).toEqual ["source.janet", "meta.#{metaScope}.janet"]

    [mid..., end] = tokens[1]

    expect(end).toEqual value: endsWith, scopes: ["source.janet", "meta.#{metaScope}.janet", "punctuation.section.#{puncScope}.end.trailing.janet"]

    for token in mid
      expect(token.scopes.slice(0, 2)).toEqual ["source.janet", "meta.#{metaScope}.janet"]

  it "tokenizes expressions", ->
    testMetaSection "expression", "expression", "(", ")"

  it "tokenizes quoted expressions", ->
    testMetaSection "quoted-expression", "expression", "'(", ")"
    testMetaSection "quoted-expression", "expression", "`(", ")"

  it "tokenizes arrays", ->
    testMetaSection "arrays", "arrays", "@[", "]"

  it "tokenizes vectors", ->
    testMetaSection "vector", "vector", "[", "]"

  it "tokenizes tables", ->
    testMetaSection "table", "table", "@{", "}"

  it "tokenizes structs", ->
    testMetaSection "struct", "struct", "{", "}"

  it "tokenizes buffer", ->
    testMetaSection "buffer", "buffer", "@\"", "\""

  # it "tokenizes sets", ->
  #   testMetaSection "set", "set", "\#{", "}"

  it "tokenizes functions in nested sexp", ->
    {tokens} = grammar.tokenizeLine "((foo bar) baz)"
    expect(tokens[0]).toEqual value: "(", scopes: ["source.janet", "meta.expression.janet", "punctuation.section.expression.begin.janet"]
    expect(tokens[1]).toEqual value: "(", scopes: ["source.janet", "meta.expression.janet", "meta.expression.janet", "punctuation.section.expression.begin.janet"]
    expect(tokens[2]).toEqual value: "foo", scopes: ["source.janet", "meta.expression.janet", "meta.expression.janet", "entity.name.function.janet"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.janet", "meta.expression.janet", "meta.expression.janet"]
    expect(tokens[4]).toEqual value: "bar", scopes: ["source.janet", "meta.expression.janet", "meta.expression.janet", "meta.symbol.janet"]
    expect(tokens[5]).toEqual value: ")", scopes: ["source.janet", "meta.expression.janet", "meta.expression.janet", "punctuation.section.expression.end.janet"]
    expect(tokens[6]).toEqual value: " ", scopes: ["source.janet", "meta.expression.janet"]
    expect(tokens[7]).toEqual value: "baz", scopes: ["source.janet", "meta.expression.janet", "meta.symbol.janet"]
    expect(tokens[8]).toEqual value: ")", scopes: ["source.janet", "meta.expression.janet", "punctuation.section.expression.end.trailing.janet"]

  it "tokenizes maps used as functions", ->
    {tokens} = grammar.tokenizeLine "({:foo bar} :foo)"
    expect(tokens[0]).toEqual value: "(", scopes: ["source.janet", "meta.expression.janet", "punctuation.section.expression.begin.janet"]
    expect(tokens[1]).toEqual value: "{", scopes: ["source.janet", "meta.expression.janet", "meta.map.janet", "punctuation.section.map.begin.janet"]
    expect(tokens[2]).toEqual value: ":foo", scopes: ["source.janet", "meta.expression.janet", "meta.map.janet", "constant.keyword.janet"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.janet", "meta.expression.janet", "meta.map.janet"]
    expect(tokens[4]).toEqual value: "bar", scopes: ["source.janet", "meta.expression.janet", "meta.map.janet", "meta.symbol.janet"]
    expect(tokens[5]).toEqual value: "}", scopes: ["source.janet", "meta.expression.janet", "meta.map.janet", "punctuation.section.map.end.janet"]
    expect(tokens[6]).toEqual value: " ", scopes: ["source.janet", "meta.expression.janet"]
    expect(tokens[7]).toEqual value: ":foo", scopes: ["source.janet", "meta.expression.janet", "constant.keyword.janet"]
    expect(tokens[8]).toEqual value: ")", scopes: ["source.janet", "meta.expression.janet", "punctuation.section.expression.end.trailing.janet"]

  it "tokenizes sets used in functions", ->
    {tokens} = grammar.tokenizeLine "(\#{:foo :bar})"
    expect(tokens[0]).toEqual value: "(", scopes: ["source.janet", "meta.expression.janet", "punctuation.section.expression.begin.janet"]
    expect(tokens[1]).toEqual value: "\#{", scopes: ["source.janet", "meta.expression.janet", "meta.set.janet", "punctuation.section.set.begin.janet"]
    expect(tokens[2]).toEqual value: ":foo", scopes: ["source.janet", "meta.expression.janet", "meta.set.janet", "constant.keyword.janet"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.janet", "meta.expression.janet", "meta.set.janet"]
    expect(tokens[4]).toEqual value: ":bar", scopes: ["source.janet", "meta.expression.janet", "meta.set.janet", "constant.keyword.janet"]
    expect(tokens[5]).toEqual value: "}", scopes: ["source.janet", "meta.expression.janet", "meta.set.janet", "punctuation.section.set.end.trailing.janet"]
    expect(tokens[6]).toEqual value: ")", scopes: ["source.janet", "meta.expression.janet", "punctuation.section.expression.end.trailing.janet"]

  describe "firstLineMatch", ->
    it "recognises interpreter directives", ->
      valid = """
        #!/usr/sbin/boot foo
        #!/usr/bin/boot foo=bar/
        #!/usr/sbin/boot
        #!/usr/sbin/boot foo bar baz
        #!/usr/bin/boot perl
        #!/usr/bin/boot bin/perl
        #!/usr/bin/boot
        #!/bin/boot
        #!/usr/bin/boot --script=usr/bin
        #! /usr/bin/env A=003 B=149 C=150 D=xzd E=base64 F=tar G=gz H=head I=tail boot
        #!\t/usr/bin/env --foo=bar boot --quu=quux
        #! /usr/bin/boot
        #!/usr/bin/env boot
      """
      for line in valid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).not.toBeNull()

      invalid = """
        \x20#!/usr/sbin/boot
        \t#!/usr/sbin/boot
        #!/usr/bin/env-boot/node-env/
        #!/usr/bin/das-boot
        #! /usr/binboot
        #!\t/usr/bin/env --boot=bar
      """
      for line in invalid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()

    it "recognises Emacs modelines", ->
      valid = """
        #-*- Janet -*-
        #-*- mode: JanetScript -*-
        /* -*-janetScript-*- */
        // -*- Janet -*-
        /* -*- mode:Janet -*- */
        // -*- font:bar;mode:Janet -*-
        // -*- font:bar;mode:Janet;foo:bar; -*-
        // -*-font:mode;mode:Janet-*-
        // -*- foo:bar mode: janetSCRIPT bar:baz -*-
        " -*-foo:bar;mode:janet;bar:foo-*- ";
        " -*-font-mode:foo;mode:janet;foo-bar:quux-*-"
        "-*-font:x;foo:bar; mode : janet; bar:foo;foooooo:baaaaar;fo:ba;-*-";
        "-*- font:x;foo : bar ; mode : JanetScript ; bar : foo ; foooooo:baaaaar;fo:ba-*-";
      """
      for line in valid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).not.toBeNull()

      invalid = """
        /* --*janet-*- */
        /* -*-- janet -*-
        /* -*- -- Janet -*-
        /* -*- Janet -;- -*-
        // -*- iJanet -*-
        // -*- Janet; -*-
        // -*- janet-door -*-
        /* -*- model:janet -*-
        /* -*- indent-mode:janet -*-
        // -*- font:mode;Janet -*-
        // -*- mode: -*- Janet
        // -*- mode: das-janet -*-
        // -*-font:mode;mode:janet--*-
      """
      for line in invalid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()

    it "recognises Vim modelines", ->
      valid = """
        vim: se filetype=janet:
        # vim: se ft=janet:
        # vim: set ft=Janet:
        # vim: set filetype=Janet:
        # vim: ft=Janet
        # vim: syntax=Janet
        # vim: se syntax=Janet:
        # ex: syntax=Janet
        # vim:ft=janet
        # vim600: ft=janet
        # vim>600: set ft=janet:
        # vi:noai:sw=3 ts=6 ft=janet
        # vi::::::::::noai:::::::::::: ft=janet
        # vim:ts=4:sts=4:sw=4:noexpandtab:ft=janet
        # vi:: noai : : : : sw   =3 ts   =6 ft  =janet
        # vim: ts=4: pi sts=4: ft=janet: noexpandtab: sw=4:
        # vim: ts=4 sts=4: ft=janet noexpandtab:
        # vim:noexpandtab sts=4 ft=janet ts=4
        # vim:noexpandtab:ft=janet
        # vim:ts=4:sts=4 ft=janet:noexpandtab:\x20
        # vim:noexpandtab titlestring=hi\|there\\\\ ft=janet ts=4
      """
      for line in valid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).not.toBeNull()

      invalid = """
        ex: se filetype=janet:
        _vi: se filetype=janet:
         vi: se filetype=janet
        # vim set ft=klojure
        # vim: soft=janet
        # vim: clean-syntax=janet:
        # vim set ft=janet:
        # vim: setft=janet:
        # vim: se ft=janet backupdir=tmp
        # vim: set ft=janet set cmdheight=1
        # vim:noexpandtab sts:4 ft:janet ts:4
        # vim:noexpandtab titlestring=hi\\|there\\ ft=janet ts=4
        # vim:noexpandtab titlestring=hi\\|there\\\\\\ ft=janet ts=4
      """
      for line in invalid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()
