#!perl -w

use strict;

use Test::More tests => 2;

my @builded;
my @demolished;

BEGIN{
	package A;
	use Scion::Object -base;
	sub BUILD{
		push @builded, 'A::BUILD';
	}
	sub DEMOLISH{
		push @demolished, 'A::DEMOLISH';
	}

	package B;
	use Scion::Object -base => qw(A);
	sub BUILD{
		push @builded, 'B::BUILD';
	}
	sub DEMOLISH{
		push @demolished, 'B::DEMOLISH';
	}

	package C;
	use Scion::Object -base => qw(A);
	sub BUILD{
		push @builded, 'C::BUILD';
	}
	sub DEMOLISH{
		push @demolished, 'C::DEMOLISH';
	}

	package D;
	use Scion::Object -base => qw(B C);
	sub BUILD{
		push @builded, 'D::BUILD';
	}
	sub DEMOLISH{
		push @demolished, 'D::DEMOLISH';
	}
};

D->new();

is_deeply \@builded,
	[qw(A::BUILD B::BUILD C::BUILD D::BUILD)],
	'BUILD()';

is_deeply \@demolished,
	[qw(D::DEMOLISH C::DEMOLISH B::DEMOLISH A::DEMOLISH)],
	'DEMOLISH()';

#use Smart::Comments;

### builded order: @builded
### demolished order: @demolished
