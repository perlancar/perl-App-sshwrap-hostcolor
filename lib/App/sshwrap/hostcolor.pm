package App::sshwrap::hostcolor;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Fcntl ':DEFAULT';
use File::Flock::Retry;

use Exporter qw(import);
our @EXPORT_OK = qw(get_history_entry add_history_entry read_history_file);

my $histname = ".sshwrap-hostcolor.history";

sub _history_path {
    require PERLANCAR::File::HomeDir;

    my $homedir = PERLANCAR::File::HomeDir::get_my_home_dir()
        or die "Couldn't get current user's homedir";
    return "$homedir/$histname";
}

sub read_history_file {
    my $key = shift;

    my $histpath = _history_path();

    open my $fh, "<", $histpath or do {
        log_trace "Cannot open history file $histpath: $!";
        return {};
    };

    my $history = {};
    while (<$fh>) {
        /\S/ or next;
        /^\s*#/ and next;
        chomp;
        my @f = split /\s+/, $_, 2;
        $history->{$f[0]} = $f[1];
    }
    $history;
}

sub get_history_entry {
    my $key = shift;

    my $histpath = _history_path();

    log_trace "Opening history file $histpath ...";
    my $lock = File::Flock::Retry->lock($histpath);
    my $fh = $lock->handle;
    seek $fh, 0, 0;

    while (<$fh>) {
        /\S/ or next;
        /^\s*#/ and next;
        chomp;
        my @f = split /\s+/, $_, 2;
        if ($f[0] eq $key) {
            log_trace "Found entry for '%s' in history file: %s",
                $key, $f[1];
            return $f[1];
        }
    }
    log_trace "No entry found for '%s' in history file", $key;
    undef;
}

sub add_history_entry {
    my ($key, $val) = @_;

    my $histpath = _history_path();

    log_trace "Opening history file $histpath ...";
    my $lock = File::Flock::Retry->lock($histpath);
    my $fh = $lock->handle;
    seek $fh, 0, 0;

    my @lines;
    my $found;
    while (<$fh>) {
        /\S/ or next;
        /^\s*#/ and next;
        chomp;
        my @f = split /\s+/, $_, 2;
        if ($f[0] eq $key) {
            if ($found) {
                log_trace "Duplicate entry '' in history file, removing";
                next;
            }
            log_trace "Replacing entry for '%s' in history file: %s -> %s",
                $key, $f[1], $val;
            $f[1] = $val;
            $found++;
        }
        push @lines, "$f[0]\t$f[1]\n";
    }
    unless ($found) {
        log_trace "Adding entry for '%s' in history file: %s", $key, $val;
        push @lines, "$key\t$val\n";
    }

    seek $fh, 0, 0;
    print $fh @lines;
    truncate $fh, tell($fh);
}

1;
#ABSTRACT: SSH wrapper script to remember the terminal background you use for each host

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

See the included script L<sshwrap-hostcolor>.
