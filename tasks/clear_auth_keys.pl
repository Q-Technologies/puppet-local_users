#!/usr/bin/env perl

use strict;
use 5.10.0;

my $user=$ENV{PT_username};

my @user_def = getpwnam( $user );
my $home = @user_def[7];

unless( $home ) {
    say STDERR "Could not find the home directory of user: $user";
    exit 1;
}

my $key_file = "$home/.ssh/authorized_keys";

if( unlink $key_file ){
    say "Successfully deleted $key_file";
} else {
    say STDERR "Could not delete $key_file: $!";
    exit 1;
}
