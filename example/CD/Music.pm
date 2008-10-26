# demo class for Scion

package
	CD::Music;

use strict;
use warnings;

use Scion::Sugar;
use Scalar::Util qw(looks_like_number);

use overload
	q{""} => 'stringify',
;

define_properties
	name => {
		storage => \my @name_of,
		required => 1,
	},
	artist => {
		storage => \my @artist_of,
		required => 1,
	},
	tracks => {
		storage  => \my @tracks_of,
		validate => sub{ looks_like_number($_) },
		default  => 1,
	},
;

my $count = 0;
sub count{ $count }

sub BUILD{
	$count++;
}
sub DEMOLISH{
	$count--;
}

sub stringify{
	my($self) = @_;

	return qq{"$name_of[$$self]" ($artist_of[$$self])};
}

__PACKAGE__->meta->make_immutable;
__END__
