use strict;
use warnings;
use inc::Module::Install;

name 'Scion';

all_from 'lib/Scion.pm';

requires 'Exporter'     => 5.57;
requires 'Data::Util'   => 0.03;
requires 'Sub::Name'    => 0.03;

requires 'MRO::Compat'  => 0.09
	if $] < 5.010;

test_requires 'Test::More'      => 0.62;
test_requires 'Test::Exception' => 0.27;

no_index directory => 'misc';

tests 't/*.t';

author_tests 'xt';

WriteMakefile(
	clean => {FILES => q(
			Scion-* *.stackdump
			cover_db
			*.out nytprof
		)},
);
