#!/usr/bin/env perl

# extract the text for the given story

use strict;
use warnings;

use Modern::Perl "2015";
use MediaWords::CommonLibs;

use Data::Dumper;

use MediaWords::DB;
use MediaWords::DBI::Downloads;
use MediaWords::Util::HTML;

sub get_extractor_results_for_story
{
    my ( $db, $story ) = @_;

    my $downloads =
      $db->query( "select * from downloads where stories_id = ? order by downloads_id", $story->{ stories_id } )->hashes;

    my $download_results = {};
    for my $download ( @{ $downloads } )
    {
        INFO "extracting: " . Dumper( $download );
        my $res = MediaWords::DBI::Downloads::extract( $db, $download );

        INFO "extractor result: " . Dumper( $res );

    }
}

sub main
{
    my ( $stories_id ) = @ARGV;

    die( "$0 < stories_id >" ) unless ( $stories_id );

    my $db = MediaWords::DB::connect_to_db;

    my $story = $db->find_by_id( 'stories', $stories_id );

    my $res = get_extractor_results_for_story( $db, $story );
}

main();
