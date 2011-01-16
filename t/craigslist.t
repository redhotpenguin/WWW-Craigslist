#!perl

use strict;
use warnings;

use Test::More qw( no_plan );

use_ok('WWW::Craigslist');

my $craigslist;

eval { $craigslist = WWW::Craigslist->new( uri => 'http://foo.org' ) };

ok( $@ =~ m/invalid uri/i, "Invalid uri throws exception");

$craigslist =  WWW::Craigslist->new;

isa_ok( $craigslist, 'WWW::Craigslist');





