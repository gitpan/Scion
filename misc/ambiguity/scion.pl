#!perl
use strict;
use warnings;

BEGIN{
	package A;
	use Scion::Sugar;

	has _xyz => (
		is => 'rw',
		default => 'A::xyz',
	);
}
BEGIN{

	package B;
	use Scion::Sugar;

	has xyz => (
		is => 'rw',
		default => 'B::xyz',
	);
}
BEGIN{

	package C;
	use Scion::Sugar;

	extends qw(A B);
}

my $x = C->new();

print 'xyz: ', $x->get_xyz, "\n";
