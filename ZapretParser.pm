package ZapretParser;
require Exporter;

@ISA    = qw/Exporter/;
@EXPORT = qw//;

use utf8;
use strict;
use Data::Dumper;

#use XML::Bare;
use XML::Fast;
use File::Slurp;

use POSIX qw(strftime);

my $VERSION = '1.01';

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    return $self;
}

sub parseDump {
    my $this     = shift;
    my $xml_file = shift;

    $::logger->debug("Parsing dump from file '$xml_file'...");

    my $xml  = read_file($xml_file);
    my $data = xml2hash $xml;
    $::zapret->{dbh}->begin_work();
    $::zapret->set($data->{'reg:register'}->{'-updateTimeUrgently'}, 'updateTimeUrgently');
    $::zapret->set($data->{'reg:register'}->{'-updateTime'},         'updateTime');
    my $ref_type = ref($data->{'reg:register'}->{content});

    $::zapret->emptyTables();
    if ($ref_type eq 'ARRAY') {
        foreach my $arr (@{$data->{'reg:register'}->{content}}) {
            $this->parseEntry($arr, 0);
        }
        $::zapret->storeEntry(0);    #final inserts
        foreach my $arr (@{$data->{'reg:register'}->{content}}) {
            $this->parseEntry($arr, 1);
        }
    } else {
        die "shit happened\n";
    }

    $::zapret->storeUrl(0);          #final inserts
    $::zapret->storeDomain(0);       #final inserts
    $::zapret->storeIp(0);           #final inserts
    $::zapret->storeIpSubnet(0);     #final inserts
    $::zapret->set($data->{'reg:register'}->{'-updateTime'}, 'updateTime');
    $::zapret->set(time(),                                   'lastDumpDate');
    $::zapret->{dbh}->commit();
    $::zapret->{dbh}->{AutoCommit} = 1;
}

sub parseDelta {
    my $this     = shift;
    my $delta    = shift;
    my $deltaId  = $delta->{'deltaId'};
    my $xml_file = $::dir . "/" . $deltaId . "/dump_delta.xml";
    $::logger->debug("Parsing delta from file '$xml_file'...");
    my $xml  = read_file($xml_file);
    my $data = xml2hash $xml;
    $::zapret->{dbh}->begin_work();

    if (defined($data->{'reg:register'}->{delete})) {
        my $ref_type = ref($data->{'reg:register'}->{delete});
        if ($ref_type eq 'ARRAY') {
            foreach my $arr (@{$data->{'reg:register'}->{delete}}) {
		$::zapret->removeEntry($arr->{'-id'});
            }
	} elsif (defined($data->{'reg:register'}->{delete}->{'-id'})) {
		$::zapret->removeEntry($data->{'reg:register'}->{delete}->{'-id'});
        } else {
            print Dumper $ref_type;
            print Dumper $data;
            die "shit happened in parseDelta - delete\n";
        }
    }
    if (defined($data->{'reg:register'}->{content})) {
    my $ref_type = ref($data->{'reg:register'}->{content});

    if ($ref_type eq 'ARRAY') {
        foreach my $arr (@{$data->{'reg:register'}->{content}}) {
            $this->parseEntry($arr, 0, 1);
        }
        $::zapret->storeEntry(0);    #final inserts
        foreach my $arr (@{$data->{'reg:register'}->{content}}) {
            $this->parseEntry($arr, 1);
        }
    } elsif ($ref_type eq 'HASH') {
        $this->parseEntry($data->{'reg:register'}->{content}, 0, 1);
        $::zapret->storeEntry(0);
        $this->parseEntry($data->{'reg:register'}->{content}, 1);
    } else {
        print Dumper $ref_type;
        print Dumper $data;
        die "shit happened in parseDelta - content\n";
    }
    }
    $::zapret->storeUrl(0);         #final inserts
    $::zapret->storeDomain(0);      #final inserts
    $::zapret->storeIp(0);          #final inserts
    $::zapret->storeIpSubnet(0);    #final inserts
    $::zapret->updateDeltaStatus($delta, 2);
    $::zapret->{dbh}->commit();
    $::zapret->{dbh}->{AutoCommit} = 1;
}

sub parseEntry {
    my $self         = shift;
    my $entry        = shift;
    my $parseContent = shift;
    my $delete       = shift || 0;
    my $entryId      = $entry->{'-id'};
    my $entryType    = $entry->{'-entryType'};
    if ($delete == 1) {
        $::zapret->removeEntry($entryId);
    }
    if ($parseContent == 0) {
        $::zapret->storeEntry($entry);
    } else {
        $::zapret->storeUrl($entryId, $entry->{'url'}) if $entry->{'url'};
        $::zapret->storeDomain($entryId, $entry->{'domain'}) if $entry->{'domain'};
        $::zapret->storeIp($entryId, $entry->{'ip'}) if $entry->{'ip'};
        $::zapret->storeIpSubnet($entryId, $entry->{'ipSubnet'}) if $entry->{'ipSubnet'};
    }
}
