#!/usr/bin/perl -w
use strict;
use warnings;
use utf8;
use File::Basename 'dirname';
use File::Spec;
use lib join '/', File::Spec->splitdir(dirname(__FILE__));
use MIME::Base64;
use Config::Simple;
use Zapret;
use ZapretParser;
use Getopt::Long;
use DBI;
use Log::Log4perl;
use POSIX qw(strftime);
use Data::Dumper;

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

our $dir    = File::Basename::dirname($0);
our $Config = {};
my $config_file = $dir . '/zapret.conf';
my $log_file    = $dir . "/zapret_log.conf";
$dir = $dir . "/tmp/";

GetOptions("log=s" => \$log_file, "config=s" => \$config_file) or die "Error in command line arguments\n";

Config::Simple->import_from($config_file, $Config) or die "Can't open " . $config_file . " for reading!\n";
Log::Log4perl::init($log_file);
our $logger = Log::Log4perl->get_logger();

our $zapret = new Zapret($Config->{'API.url'}, $Config->{'API.username'}, $Config->{'API.password'});
our %params = $zapret->getParams();
my $parser = new ZapretParser();

my @result      = $zapret->getDumpDeltaList($params{'updateTime'});
my $return_code = shift @result;
if ($return_code == -1) {
    my $result = $zapret->getResult();
    $parser->parseDump($dir . "dump.xml");
    exit;
} elsif ($return_code == 1) {
    foreach my $delta (@result) {
        $zapret->storeDeltaStatus($delta, 0);
    }
    foreach my $delta ($zapret->getDeltasByStatus(0)) {
        $zapret->getDumpDelta($delta);
    }

    foreach my $delta ($zapret->getDeltasByStatus(1)) {
        $parser->parseDelta($delta);
    }
}

