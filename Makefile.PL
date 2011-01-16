#!/usr/bin/perl -w

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'WWW::Craigslist',
    VERSION_FROM   => 'lib/WWW/Craigslist.pm',
    PREREQ_PM      => {
        #'Qpsmtpd'         => 0,
        'WWW::Mechanize'   => 0,
        'Data::Dumper' => 0,
    },
    ABSTRACT_FROM  => 'README',
    AUTHOR         => 'Fred Moyer <fred@redhotpenguin.com>',
);
