package Slim::Schema::Image;

use strict;

use File::Basename;
use Slim::Schema;
use Slim::Utils::Misc;

# XXX DBIx::Class stuff needed?

sub updateOrCreateFromResult {
	my ( $class, $result ) = @_;
	
	my $id;
	my $url = Slim::Utils::Misc::fileURLFromPath($result->path);
	
	# Create title from path
	my $title = basename($result->path);
	$title =~ s/\.\w+$//;
	
	my $sort = Slim::Utils::Text::ignoreCaseArticles($title);
	my $search = Slim::Utils::Text::ignoreCaseArticles($title, 1);
	my $now = time();
	
	my $hash = {
		hash         => $result->hash,
		url          => $url,
		title        => $title,
		titlesearch  => $search,
		titlesort    => $sort,
		image_codec  => $result->codec,
		mime_type    => $result->mime_type,
		dlna_profile => $result->dlna_profile,
		width        => $result->width,
		height       => $result->height,
		mtime        => $result->mtime,
		added_time   => $now,
		updated_time => $now,
		filesize     => $result->size,
	};
	
	my $sth = Slim::Schema->dbh->prepare_cached('SELECT id FROM images WHERE url = ?');
	$sth->execute($url);
	($id) = $sth->fetchrow_array;
	$sth->finish;
	
	if ( !$id ) {
	    $id = Slim::Schema->_insertHash( images => $hash );
	}
	else {
		$hash->{id} = $id;
		
		# Don't overwrite the original add time
		delete $hash->{added_time};
		
		Slim::Schema->_updateHash( images => $hash, 'id' );
	}
	
	return $id;
}

sub findhash {
	my ( $class, $id ) = @_;
	
	my $sth = Slim::Schema->dbh->prepare_cached( qq{
		SELECT * FROM images WHERE hash = ?
	} );
	
	$sth->execute($id);
	my $hash = $sth->fetchrow_hashref;
	$sth->finish;
	
	return $hash || {};
}

1;
