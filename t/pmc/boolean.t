# Copyright (C) 2008, The Perl Foundation.

=head1 NAME

t/pmc/boolean.t - Boolean PMC

=head1 SYNOPSIS

    % perl t/harness t/pmc/boolean.t

=head1 DESCRIPTION

Tests C<PhpBoolean> PMC.

=cut

.sub 'main' :main
    $P0 = loadlib "pipp_group"

    .include "test_more.pir"

    plan(4)

    truth_tests()
    type_tests()
.end

.sub truth_tests
    .local pmc true, false

    true = new 'PhpBoolean'
    true = 1

    false = new 'PhpBoolean'
    false = 0

    is(true, 1, "true PhpBoolean is 1")
    is(false, "", "false PhpBoolean is empty")
.end

.sub type_tests
    .local pmc true, false
    .local string true_type, false_type

    true = new 'PhpBoolean'
    true = 1
    true_type = typeof true
    is(true_type, "boolean", "type of true")

    false = new 'PhpBoolean'
    false = 0
    false_type = typeof false
    is(false_type, "boolean", "type of false")
.end

# Local Variables:
#   mode: pir
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
