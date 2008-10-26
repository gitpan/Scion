#!perl -w

use strict;

use FindBin qw($Bin);
use lib $Bin;

use CD::Music;

sub say{ print @_, "\n" }

say 'count: ', CD::Music->count;

{
	my $a = CD::Music->new(name => 'Scion',         artist => 'GFUJI');
	my $b = CD::Music->new(name => 'Scion::Object', artist => 'GFUJI');
	my $c = CD::Music->new(name => 'Scion::Sugar',  artist => 'GFUJI');

	say 'count: ', CD::Music->count;

	say 'A - '. $a;
	say 'B - ', $b;
	say 'C - ', $c;
}

say 'count: ', CD::Music->count;

