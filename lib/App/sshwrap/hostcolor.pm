package App::sshwrap::hostcolor;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

my $histname = ".sshwrap-hostcolor.history";

sub _history_path {
    require PERLANCAR::File::HomeDir;

    my $homedir = PERLANCAR::File::HomeDir::get_my_home_dir() or do {
        log_info "Couldn't get current user's homedir, bailing out";
        return;
    };
    return "$homedir/$histname";
}

sub read_history_file {
    my $histpath = _history_path or return {};

    log_trace "Reading history file $histpath ...";
    open my $fh, "<", $histpath or do {
        log_info "Couldn't read $histpath ($!), bailing out";
        return {};
    };
    my $hist = {};
    while (<$fh>) {
        /\S/ or next;
        /^\s*#/ and next;
        chomp;
        my @f = split /\s+/, $_;
        $hist->{$f[0]} = $f[1];
    }
    $hist;
}

sub write_history_file {
    my $hist = shift;

    my $histpath = _history_path or return;

    log_trace "Writing history file $histpath ...";
    open my $fh, ">", $histpath or do {
        log_info "Couldn't write $histpath ($!), bailing out";
        return;
    };

    for (sort keys %$hist) {
        print $fh "$_\t$hist->{$_}\n";
    }
    close $fh;
}

1;
#ABSTRACT: SSH wrapper script to remember the terminal background you use for each host

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

See the included script L<sshwrap-hostcolor>.
