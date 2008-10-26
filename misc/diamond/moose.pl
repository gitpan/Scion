#!perl
use strict;
use warnings;

BEGIN{
	package A;
	use Moose;

	has xyz => (
		default => __PACKAGE__ .'::xyz',
	);

	sub BUILD{
		print __PACKAGE__, "::BUILD\n";
	}
	sub DEMOLISH{
		print __PACKAGE__, "::DEMOLISH\n";
	}
}
BEGIN{
	package B;
	use Moose;
	extends 'A';

	has xyz => (
		default => __PACKAGE__ .'::xyz',
	);

	sub BUILD{
		print __PACKAGE__, "::BUILD\n";
	}
	sub DEMOLISH{
		print __PACKAGE__, "::DEMOLISH\n";
	}
}
BEGIN{
	package C;
	use Moose;
	extends 'A';

	has xyz => (
		default => __PACKAGE__ .'::xyz',
	);

	sub BUILD{
		print __PACKAGE__, "::BUILD\n";
	}
	sub DEMOLISH{
		print __PACKAGE__, "::DEMOLISH\n";
	}
}
BEGIN{
	package D;
	use Moose;

	use mro 'c3';

	extends qw(B C);

	has xyz => (
		default => __PACKAGE__ .'::xyz',
	);

	sub BUILD{
		print __PACKAGE__, "::BUILD\n";
	}
	sub DEMOLISH{
		print __PACKAGE__, "::DEMOLISH\n";
	}
}

use Data::Dumper;
print Data::Dumper->new([D->new()], ['D1'])->Sortkeys(1)->Dump;
