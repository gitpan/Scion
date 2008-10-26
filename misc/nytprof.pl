#!perl -wd:NYTProf

use strict;
use warnings;

BEGIN{
	package A;
	use Scion::Sugar -base;

	has a => (
		required => 1,
	);

	foreach my $i(1 .. 10){
		has "a$i" => (default => $i);
	}
}
BEGIN{
	package B;
	use Scion::Sugar -base => qw(A);

	has b => (
		required => 1,
	);
	foreach my $i(1 .. 10){
		has "b$i" => (default => $i);
	}
}
BEGIN{
	package C;
	use Scion::Sugar -base => qw(A);

	has c => (
		required => 1,
	);
	foreach my $i(1 .. 10){
		has "c$i" => (default => $i);
	}
}

BEGIN{
	package D;
	use Scion::Sugar -base => qw(C B);

	has d => (
		required => 1,
	);
	foreach my $i(1 .. 10){
		has "d$i" => (default => $i);
	}
}
$| = 1;
for my $i(1 .. 1000){
	my $a = A->new(a => 1);
	$a->set_a( $a->get_a + 1);

	my $b = B->new(a => 2, b => 3);
	$b->set_b( $b->get_b + 1);

	my $c = C->new(a => 4, c => 5);
	$c->set_c( $c->get_c + 1);

	my $d = D->new(a => 6, b => 7, c => 8, d => 9);
	$d->set_d( $d->get_d + 1);

	print "$i\r";
}
print "\n";
