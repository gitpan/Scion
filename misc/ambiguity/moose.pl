#!perl
use strict;
use warnings;

BEGIN{
	package A;
	use Moose;

	has xyz => (
		is => 'rw',
		default => 'A::xyz',
	);

	package B;
	use Moose;

	has xyz => (
		is => 'rw',
		default => 'B::xyz',
	);

	package C;
	use Moose;
	extends 'A', 'B';
}

my $x = C->new();

print 'xyz: ', $x->xyz, "\n"; # => A::xyz
