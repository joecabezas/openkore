sub getLocationFromText {
	my ($text) = @_;
	$text =~ /(\S+ \d+ \d+)/;
	return $1;
}

sub getDestinationMapFromTextEnd {
	my ($text) = @_;
	$text =~ /(\S+)$/;
	return $1;
}

sub getMapFromLocation {
	my ($location) = @_;
	$location =~ /^(\S*) (\d+) (\d+)$/;
	return $1;
}

sub getPosXFromLocation {
	my ($location) = @_;
	$location =~ /^(\S*) (\d+) (\d+)$/;
	return $2;
}

sub getPosYFromLocation {
	my ($location) = @_;
	$location =~ /^(\S*) (\d+) (\d+)$/;
	return $3;
}