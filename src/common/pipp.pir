#!./parrot

# $Id$

=head1 NAME

pipp.pir - three variants of PHP on Parrot

=head1 SYNOPSIS

   ./parrot languages/pipp/pipp.pbc t.php

   ./parrot languages/pipp/pipp.pbc --variant=pct   t.php

   ./parrot languages/pipp/pipp.pbc --variant=phc   t.php

   ./parrot languages/pipp/pipp.pbc --variant=antlr t.php

   ./parrot languages/pipp/pipp.pbc --run-nqp       t.nqp

=head1 DESCRIPTION

pipp.pbc is the driver for the three variants of PHP on Parrot.
It can alse be used for running the NQP code generated by the variants B<phc>
and <antlr>.

=head1 Variants

=head2 Pipp pct

Parse PHP with the Parrot compiler toolkit. This is the default variant.

=head2 Pipp phc

Take XML from phc and transform it with XSLT to PIR setting up PAST.
Run the PAST with the help of PCT.

=head2 Pipp antlr

Parse PHP with Java based parser and tree parser, generated from ANTLR3 grammars.

=head1 SEE ALSO

F<languages/pipp/docs>

=head1 AUTHOR

Bernhard Schmalhofer - L<Bernhard.Schmalhofer@gmx.de>

=cut


.namespace [ 'PAST::Compiler' ]

.sub '__onload' :anon :load :init
    load_bytecode 'PCT.pbc'

    ##  %valflags specifies when PAST::Val nodes are allowed to
    ##  be used as a constant.  The 'e' flag indicates that the
    ##  value must be quoted+escaped in PIR code.
    .local pmc valflags
    valflags = get_global '%valflags'
    valflags['PhpString']   = 's~*e'
.end

.namespace [ 'Pipp' ]

.const string VERSION = "0.0.1"

.sub '__onload' :load :init

    load_bytecode 'PGE.pbc'
    load_bytecode 'PGE/Text.pbc'
    load_bytecode 'PGE/Util.pbc'
    load_bytecode 'PGE/Dumper.pbc'

    load_bytecode 'languages/pipp/src/common/pipplib.pbc'
    load_bytecode 'languages/pipp/src/common/php_ctype.pbc'
    # load_bytecode 'languages/pipp/src/common/php_pcre.pbc'

    load_bytecode 'CGI/QueryHash.pbc'
    load_bytecode 'dumper.pbc'
    load_bytecode 'Getopt/Obj.pbc'

    # import PGE::Util::die into Pipp::Grammar
    $P0 = get_hll_global ['PGE::Util'], 'die'
    set_hll_global ['Pipp::Grammar'], 'die', $P0

    # register and set up the the HLLCompiler
    $P1 = new [ 'PCT::HLLCompiler' ]
    $P1.'language'('Pipp')
    $P1.'parsegrammar'('Pipp::Grammar')
    $P1.'parseactions'('Pipp::Grammar::Actions')

.end

.sub pipp :main
    .param pmc argv

    .local string rest
    .local pmc    opt
    ( opt, rest ) = parse_options(argv)

    .local string source_fn
    source_fn = opt['f']
    if source_fn goto GOT_PHP_SOURCE_FN
        source_fn = rest
GOT_PHP_SOURCE_FN:

    set_superglobals()

    .local string target
    target = opt['target']

    # look at commandline and decide what to do
    .local string cmd, err_msg, variant
    .local int ret
    variant = opt['variant']
    if variant == 'antlr3'    goto VARIANT_ANTLR3
    if variant == 'pct'       goto VARIANT_PCT
    if variant == 'phc'       goto VARIANT_PHC
    $I0 = defined opt['run-nqp']
    if  $I0                   goto RUN_NQP

VARIANT_PCT:
    # use the Parrot Compiler Toolkit by default
    .local pmc pipp_compiler
    pipp_compiler = compreg 'Pipp'

    .return pipp_compiler.'evalfiles'( source_fn, 'target' => target )

VARIANT_PHC:
    # work with the XML generated by PHC, the PHP Compiler
    err_msg = 'Creating XML-AST with phc failed'
    cmd = 'phc --dump-ast-xml '
    concat cmd, source_fn
    concat cmd, '> pipp_phc_ast.xml'
    ret = spawnw cmd
    if ret goto ERROR

    err_msg = 'Creating XML-PAST with xsltproc failed'
    cmd = 'xsltproc languages/pipp/src/phc/phc_xml_to_past_xml.xsl pipp_phc_ast.xml > pipp_phc_past.xml'
    ret = spawnw cmd
    if ret goto ERROR

    err_msg = 'Creating NQP with xsltproc failed'
    cmd = 'xsltproc languages/pipp/src/phc/past_xml_to_past_nqp.xsl  pipp_phc_past.xml  > pipp_phc_past.nqp'
    ret = spawnw cmd
    if ret goto ERROR

    .return run_nqp( 'pipp_phc_past.nqp', target )


VARIANT_ANTLR3:
    # parse php with antlr
    err_msg = 'Generating PAST from annotated PHP source failed'
    cmd = 'java PippAntlr3 '
    concat cmd, source_fn
    concat cmd, ' pipp_antlr_past.nqp'
    ret = spawnw cmd
    if ret goto ERROR

    .return run_nqp( 'pipp_antlr_past.nqp', target )

RUN_NQP:

    .return run_nqp( source_fn, target )


ERROR:
    printerr err_msg
    printerr "\n"
    # Clean up temporary files
    #.local pmc os
    #os = new .OS
    #os."rm"('pipp_phc_ast.xml')
    #os."rm"('pipp_phc_past.xml')
    #os."rm"('pipp_phc_past.nqp')
    #os."rm"('pipp_antlr_past.nqp')

   exit ret

.end

.sub run_nqp
    .param string nqp_source_fn
    .param string target

    # compile NQP to PIR
    .local string pir_fn, cmd
    .local int ret
    clone pir_fn, nqp_source_fn
    substr pir_fn, -3, 3, 'pir'     # change extension from '.nqp' to '.pir'
    cmd = "./parrot ./compilers/nqp/nqp.pbc --target=pir --output="
    concat cmd, pir_fn
    concat cmd, " "
    concat cmd, nqp_source_fn
    ret = spawnw cmd

    # load the generated PIR
    load_bytecode pir_fn

    .local pmc stmts
    ( stmts ) = php_entry()     # stmts contains the PAST
    if target != 'past' goto NO_PAST_DUMP
        _dumper( stmts )
        .return ()
    NO_PAST_DUMP:

    # compile and evaluate the PAST returned from scheme_entry()
    .local pmc past_compiler
    past_compiler = new [ 'PCT::HLLCompiler' ]
    $P0 = split ' ', 'post pir evalpmc'
    past_compiler.'stages'( $P0 )
    past_compiler.'eval'(stmts)

    .return ()
.end

# get commandline options
.sub parse_options
    .param pmc argv

    .local string prog
    prog = shift argv

    # Specification of command line arguments.
    # --version, --inv=nnn, --builtin=name, --nc, --help
    .local pmc getopts
    getopts = new 'Getopt::Obj'
    push getopts, 'version'
    push getopts, 'help'
    push getopts, 'f=s'                # source file
    push getopts, 'variant=s'          # switch between variants
    push getopts, 'target=s'           # relevant for 'Pipp pct'
    push getopts, 'run-nqp'            # run the nqp generated by the phc and antlr variants

    .local pmc opt
    opt = getopts."get_options"(argv)

    $I0 = defined opt['version']
    unless $I0 goto n_ver
        print prog
        print " "
        print VERSION
        print "\n"
        end
n_ver:
    $I0 = defined opt['help']
    unless $I0 goto n_help
help:
    print "usage: "
    print prog
    print " [options...] [file]\n"
    print "see\n\tperldoc -F "
    print prog
    print "\nfor more\n"
    end

n_help:

    .local int argc
    .local string rest
    argc = elements argv
    if argc < 1 goto help
    dec argc
    rest = argv[argc]

    .return (opt, rest )
.end

# Most of the superglobals are not initialized yet
.sub set_superglobals

    # the superglobals _GET and _POST need to be set up for any variant
    .local pmc parse_get_sub, superglobal_GET
    parse_get_sub       = get_hll_global [ 'CGI'; 'QueryHash' ], 'parse_get'
    ( superglobal_GET ) = parse_get_sub()
    set_hll_global '$_GET', superglobal_GET

    .local pmc parse_post_sub, superglobal_POST
    parse_post_sub       = get_hll_global [ 'CGI'; 'QueryHash' ], 'parse_post'
    ( superglobal_POST ) = parse_post_sub()
    set_hll_global '$_POST', superglobal_POST

    .local pmc superglobal_SERVER
    superglobal_SERVER = new 'PhpArray'
    set_hll_global '$_SERVER', superglobal_SERVER

    .local pmc superglobal_GLOBALS
    superglobal_GLOBALS = new 'PhpArray'
    set_hll_global '$_GLOBALS', superglobal_GLOBALS

    .local pmc superglobal_FILES
    superglobal_FILES = new 'PhpArray'
    set_hll_global '$_FILES', superglobal_FILES

    .local pmc superglobal_COOKIE
    superglobal_COOKIE = new 'PhpArray'
    set_hll_global '$_COOKIE', superglobal_COOKIE

    .local pmc superglobal_SESSION
    superglobal_SESSION = new 'PhpArray'
    set_hll_global '$_SESSION', superglobal_SESSION

    .local pmc superglobal_REQUEST
    superglobal_REQUEST = new 'PhpArray'
    set_hll_global '$_REQUEST', superglobal_REQUEST

    .local pmc superglobal_ENV
    superglobal_ENV = new 'PhpArray'
    set_hll_global '$_ENV', superglobal_ENV

.end

.namespace [ 'Pipp::Grammar' ]

.include 'src/pct/gen_grammar.pir'

.include 'src/pct/gen_actions.pir'

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir: