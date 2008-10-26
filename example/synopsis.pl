#!perl -w
use strict;

BEGIN{
	package
		StreamBase;
	use Scion::Sugar;
	use Scalar::Util qw(openhandle);

	has filehandle => (
		validate => sub{ openhandle $_ },
	);

	package
		InputStream;
	use Scion::Sugar -base => qw(StreamBase);

	sub getline{
		my $self = shift;
		return scalar readline( $self->get_filehandle );
	}

	package
		FileInputStream;
	use Scion::Sugar -base => qw(InputStream);

	has filename => (
		is => 'ro',
		storage => \my @filename_of,
	);

	sub BUILD{
		my($self) = @_;

		open my $in, '<', $filename_of[$$self] or die $!;

		$self->set_filehandle($in);
	}
}

use strict;

my $x = FileInputStream->new(filename => $0);

while(defined(my $line = $x->getline)){
	print $line;
}

