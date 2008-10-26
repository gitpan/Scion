#!perl
use strict;
use warnings;

BEGIN{
	package A;
	use Scion::Sugar;

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
	use Scion::Sugar;
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
	use Scion::Sugar;
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
	use Scion::Sugar;
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

D->new()->dump();
