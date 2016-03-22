#!/usr/bin/env perl

# query a random set of feeds and generate a list of feedly stories that would be added to media cloud if we were to run
# a feedly import for that feed

# usage: $0 < num_feeds >

use strict;
use warnings;

BEGIN
{
    use FindBin;
    use lib "$FindBin::Bin/../lib";
}

use Modern::Perl "2013";
use Mediawords::CommonLibs;


use Data::Dumper;
use Encode;

use MediaWords::DB;
use MediaWords::ImportStories::Feedly;
use MediaWords::Util::CSV;

sub main
{
    my ( $num_feeds ) = @ARGV;

    my $db = MediaWords::DB::connect_to_db;

    my $feeds = $db->query( <<SQL, $num_feeds )->hashes;
select * from feeds where feed_status = 'active' and feeds_id = 70853 order by random() limit ( ? * 10 )
SQL

    my $dates = [];

    my $validate_stories = [];

    my $scraped_feeds = 0;
    for my $feed( @{ $feeds } )
    {
#         my ( $earliest_date ) = $db->query( <<SQL, $feed-> { feeds_id } )->flat;
# select min( publish_date )
#     from stories s
#         on feeds_stories_map fsm on ( s.stories_id = fsm.stories_id )
#     where fsm.feeds_id = ?
# SQL

        my $import = MediaWords::ImportStories::Feedly->new(
            db => $db,
            media_id => $feed->{ media_id },
            dry_run => 1,
            feed_url => $feed->{ url }
        );

        my $new_stories;

        eval { $new_stories = $import->get_new_stories(); };
        warn( $@ ) if ( $@ );

        next unless( $new_stories && @{ $new_stories } );

        map { $_->{ _r} = rand() } @{ $new_stories };

        # splice( @{ $new_stories }, 10 );

        map {
            $_->{ feeds_id } = $feed->{ feeds_id };
            delete( $_->{ _r } );
            delete( $_->{ description } )
        } @{ $new_stories };

        push( @{ $validate_stories }, @{ $new_stories } );

        last if ( $scraped_feeds++ >= $num_feeds );
    };

    # binmode( STDOUT, 'utf8' );
    #
    # map { say $_->{ title }; } @{ $validate_stories };

    my $csv = MediaWords::Util::CSV::get_hashes_as_encoded_csv( $validate_stories );

    print $csv;
}

main();