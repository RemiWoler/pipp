# $Id$

=head1 NAME

pipp/t/strings.t - tests for Pipp

=head1 DESCRIPTION

String testing.

=cut

# pragmata
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../lib";

# core Perl modules
use Test::More     tests => 14;

# Parrot modules
use Parrot::Test;


language_output_is( 'Pipp', <<'END_CODE', <<'END_EXPECTED', '== for equal strings' );
<?php
if ( 'asdf' == 'asdf' )
{
  echo "== for equal strings\n";
}
?>
END_CODE
== for equal strings
END_EXPECTED


language_output_is( 'Pipp', <<'END_CODE', <<'END_EXPECTED', '== for unequal strings' );
<?php
if ( 'asdf' == 'jklö' )
{
  echo "wrong turn\n";
}
else
{
  echo "== for unequal strings\n";
}
?>
END_CODE
== for unequal strings
END_EXPECTED


language_output_is( 'Pipp', <<'END_CODE', <<'END_EXPECTED', '!= for equal strings' );
<?php
if ( 'asdf' != 'asdf' )
{
  echo "dummy";
}
else
{
  echo "!= for equal strings\n";
}
?>
END_CODE
!= for equal strings
END_EXPECTED


language_output_is( 'Pipp', <<'END_CODE', <<'END_EXPECTED', '!= for unequal strings' );
<?php
if ( 'asdf' != 'jklö' )
{
  echo "!= for unequal strings\n";
}
?>
END_CODE
!= for unequal strings
END_EXPECTED


language_output_is( 'Pipp', <<'END_CODE', <<'END_EXPECTED', 'var_dump()' );
<?php
var_dump( 'asdf' );
?>
END_CODE
string(4) "asdf"
END_EXPECTED


language_output_is( 'Pipp', <<'END_CODE', <<'END_EXPECTED', 'string interpolation, simple syntax' );
<?php
$var1 = "VAR1";
$var2 = "VAR2";
echo "$var1 $var2\n";
?>
END_CODE
VAR1 VAR2
END_EXPECTED

language_output_is( 'Pipp', <<'END_CODE', <<'END_EXPECTED', 'curly string interpolation, one var' );
<?php
$var1 = "VAR1";
echo "{$var1}\n";
?>
END_CODE
VAR1
END_EXPECTED

language_output_is( 'Pipp', <<'END_CODE', <<'END_EXPECTED', 'curly string interpolation, two vars', todo => 'broken' );
<?php
$var1 = "VAR1";
$var2 = "VAR2";
echo "{$var1} {$var2}\n";
?>
END_CODE
VAR1 VAR2
END_EXPECTED

language_output_is( 'Pipp', <<'END_CODE', <<'END_EXPECTED', 'print a pair of curlies' );
<?php
echo "curlies: {}\n";
?>
END_CODE
curlies: {}
END_EXPECTED


language_output_is( 'Pipp', <<'END_CODE', <<'END_EXPECTED', 'single quoted string' );
<?php

$dummy = 'INTERPOLATED';

echo 'no variable expansion: $dummy', "\n";
echo 'no variable expansion in twiddles: {$dummy}', "\n";
echo 'backslash at end: \\', "\n";
echo 'backslash not at end: \dummy', "\n";
echo 'backslash before a space: \ ', "\n";
echo 'escaped backslash before a space: \\ ', "\n";
echo 'not a newline: \n', "\n";
echo 'not a carriage return: \r', "\n";
echo 'not a tab: \t', "\n";
echo 'not a vertical tab: \v', "\n";
echo 'not a form feed: \f', "\n";
echo 'not an octal: \101', "\n";
echo 'not an hex: \x41', "\n";
echo 'single quote: \'', "\n";
echo 'double quote: "', "\n";
echo 'backslash and double quote: \"', "\n";
echo 'escaped backslash and double quote: \\"', "\n";
echo 'backslash and single quote: \\\'', "\n";
echo 'two backslashes and a single quote: \\\\\'', "\n";
echo 'backslash and a dollar: \$dummy', "\n";
echo 'backslash and twiddles: \{$dummy}', "\n";

?>
END_CODE
no variable expansion: $dummy
no variable expansion in twiddles: {$dummy}
backslash at end: \
backslash not at end: \dummy
backslash before a space: \ 
escaped backslash before a space: \ 
not a newline: \n
not a carriage return: \r
not a tab: \t
not a vertical tab: \v
not a form feed: \f
not an octal: \101
not an hex: \x41
single quote: '
double quote: "
backslash and double quote: \"
escaped backslash and double quote: \"
backslash and single quote: \'
two backslashes and a single quote: \\'
backslash and a dollar: \$dummy
backslash and twiddles: \{$dummy}
END_EXPECTED

language_output_is( 'Pipp', <<'END_CODE', <<'END_EXPECTED', 'double quoted string' );
<?php

$dummy = 'INTERPOLATED';

echo "variable expansion: $dummy", "\n";
echo "backslash at end: \\", "\n";
echo "backslash not at end: \dummy", "\n";
echo "backslash before a space: \ ", "\n";
echo "escaped backslash before a space: \\ ", "\n";
echo "a newline: \n", "\n";
echo "a tab: \t", "\n";
echo "an octal: \101", "\n";
echo "an hex: \x41", "\n";
echo "single quote: '", "\n";
echo "double quote: \"", "\n";
echo "backslash and double quote: \\\"", "\n";
echo "backslash and single quote: \\'", "\n";
echo "two backslashes and a single quote: \\\\'", "\n";
echo "backslash and a dollar: \\\$dummy", "\n";
echo "backslash and twiddles: \{$dummy}", "\n";

?>
END_CODE
variable expansion: INTERPOLATED
backslash at end: \
backslash not at end: \dummy
backslash before a space: \ 
escaped backslash before a space: \ 
a newline: 

a tab: 	
an octal: A
an hex: A
single quote: '
double quote: "
backslash and double quote: \"
backslash and single quote: \'
two backslashes and a single quote: \\'
backslash and a dollar: \$dummy
backslash and twiddles: \{INTERPOLATED}
END_EXPECTED

language_output_is( 'Pipp', <<'END_CODE', <<"END_EXPECTED", 'vertical tab, new in PHP 5.3' );
<?php

echo "a vertical tab: \v", "\n";

?>
END_CODE
a vertical tab: \013
END_EXPECTED

language_output_is( 'Pipp', <<'END_CODE', <<"END_EXPECTED", 'form feed, new in PHP 5.3' );
<?php

echo "a form feed: \f", "\n";

?>
END_CODE
a form feed: \f
END_EXPECTED

language_output_is( 'Pipp', <<'END_CODE', <<"END_EXPECTED", 'carriage return' );
<?php

echo "a carriage return: \r<--", "\n";

?>
END_CODE
a carriage return: \r<--
END_EXPECTED
