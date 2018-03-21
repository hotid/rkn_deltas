package Zapret;
require Exporter;

@ISA    = qw/Exporter/;
@EXPORT = qw//;

use utf8;
use strict;
use SOAP::Lite;
use Data::Validate::IP qw(is_ipv4 is_ipv6);
use Network::IPv4Addr qw(ipv4_parse);

#use SOAP::Lite +trace => [qw( transport dispatch result      parameters headers    method     fault      trace      debug        )];
use SOAP::DateTime qw(ConvertDate);
use MIME::Base64;
use Data::Dumper;
use POSIX qw(strftime);

my $VERSION = '1.01';

sub new {
    my $class    = shift;
    my $url      = shift || die("URL not defined");
    my $username = shift || die("username not defined");
    my $password = shift || die("password not defined");
    $url = "http://" . $username . ":" . $password . "@" . $url;

    sub SOAP::Transport::HTTP::Client::get_basic_credentials { return ($::Config->{'API.username'} => $::Config->{'API.password'}) }

    our $dbh = dbConnect($::Config->{'DB.name'}, $::Config->{'DB.host'}, $::Config->{'DB.user'}, $::Config->{'DB.password'}),
      my $self = {
                  service       => SOAP::Lite->service($url),
                  dbh           => $dbh,
                  remove_record => $dbh->prepare("delete from records where id=?"),
                  records       => [],
                  urls          => [],
                  domains       => [],
                  ips           => [],
                  ipSubnets     => [],};


    bless $self, $class;
    return $self;
}

sub getLastDumpDate {
    my $this = shift;
    return $this->{service}->getLastDumpDate();
}

sub getDumpDeltaList {
    my $this = shift;
    my $time = shift;
    return $this->{service}->getDumpDeltaList(SOAP::Data->type('xsd:dateTime')->name('actualDate')->value($time));
}

sub _getDumpDelta {
    my $this    = shift;
    my $deltaId = shift;
    return $this->{service}->getDumpDelta(SOAP::Data->type('xsd:int')->name('deltaId')->value($deltaId));
}

sub getDumpDelta {
    my $this    = shift;
    my $delta   = shift;
    my $deltaId = $delta->{'deltaId'};

    my @delta_data = $this->_getDumpDelta($deltaId);
    $this->saveFile($delta_data[1], $deltaId . "_" . $delta_data[0]);
    my $file        = $::dir . "/" . $deltaId . "_" . $delta_data[0];
    my $destination = $::dir . "/" . $deltaId . "/";
    `unzip -o $file -d $destination`;
    $this->storeDeltaStatus($delta, 1);
}

sub getLastDumpDateEx {
    my $this = shift;
    return $this->{service}->getLastDumpDateEx();
}

sub _getResult {
    my $this = shift;
    return $this->{service}->getResult();
}

sub saveFile {
    my $this     = shift;
    my $data     = shift;
    my $filename = shift;
    $data = decode_base64($data);
    open F, '>' . $::dir . "/" . $filename || return 0;
    binmode F;
    print F $data;
    close F;
    return 1;
}

sub getResult {
    my $this = shift;
    $::logger->debug("Getting result...");

    my @result;
    eval { @result = $this->_getResult(); };

    if ($@) {
        $::logger->fatal("Error while getResult(): " . $@);
        return 0;
    }

    if (!@result) {
        $::logger->fatal("Result not defined!");
        $::logger->error(Dumper(@result));
        return 0;
    }

    if (!($result[0] eq 'true')) {
        my $comment = $result[1];
        $::logger->error("Can not get result: " . $comment);
        return 0;
    } else {
        unlink $::dir . '/dump.xml';
        unlink $::dir . '/dump.xml.sig';
        $this->saveFile($result[1], "arch.zip");
        `unzip -o $::dir/arch.zip -d $::dir/`;
        $::logger->debug("Got result, parsing dump.");
    }
    return 0;
}

sub dbConnect {
    my $db_name = shift;
    my $db_host = shift;
    my $db_user = shift;
    my $db_pass = shift;

    my $dbh = DBI->connect_cached("DBI:mysql:database=" . $db_name . ";host=" . $db_host, $db_user, $db_pass, {mysql_enable_utf8 => 1}) or die DBI->errstr;
    $dbh->do("set names utf8");
    return $dbh;
}

sub set {
    my $this  = shift;
    my $param = shift;
    my $value = shift;
    my $sth   = $this->{dbh}->prepare("insert into settings (param, value) values(?, ?) on duplicate key update value = values(value)");
    $sth->bind_param(1, $value);
    $sth->bind_param(2, $param);
    $sth->execute or die DBI->errstr;
}

sub storeDeltaStatus {
    my $this    = shift;
    my $delta   = shift;
    my $status  = shift;
    my $isEmpty = 0;
    if ($delta->{'isEmpty'} eq "true") { $isEmpty = 1; }
    my $sth;
    if ($status == 0) {
        $sth = $this->{dbh}->prepare("INSERT ignore into deltas(deltaId, isEmpty, actualDate, updated, status) values(?,?,?,now(),?)");
    } else {
        $sth = $this->{dbh}->prepare("INSERT into deltas(deltaId, isEmpty, actualDate, updated, status) values(?,?,?,now(),?) on duplicate key update status=values(status), updated=now()");
    }

    $sth->bind_param(1, $delta->{'deltaId'});
    $sth->bind_param(2, $isEmpty);
    $sth->bind_param(3, $delta->{'actualDate'});
    $sth->bind_param(4, $status);
    $sth->execute or die DBI->errstr;
}

sub getDeltasByStatus {
    my $this   = shift;
    my $status = shift;
    my $sth    = $this->{dbh}->prepare("SELECT * from deltas where isEmpty=0 and status=?");
    $sth->bind_param(1, $status);
    $sth->execute or die DBI->errstr;
    my @deltas;
    while (my $row = $sth->fetchrow_hashref()) {
        push(@deltas, {'deltaId' => $row->{'deltaId'}, 'isEmpty' => $row->{'isEmpty'}, 'actualDate' => $row->{'actualDate'}});
    }
    return @deltas;
}

sub getParams {
    my $this = shift;
    my $sth  = $this->{dbh}->prepare("SELECT param,value FROM settings");
    $sth->execute or die DBI->errstr;
    my %parameters;
    while (my $ips = $sth->fetchrow_hashref()) {
        $parameters{$ips->{param}} = $ips->{value};
    }
    return %parameters;
}

sub removeEntry {
    my $this    = shift;
    my $entryId = shift;
    $this->{remove_record}->execute($entryId);
}

sub storeEntry {
    my $this  = shift;
    my $entry = shift;
    if ($entry) {
        my $blockType = $entry->{'-blockType'} || 'default';
        push @{$this->{records}}, [ $entry->{'-id'}, $entry->{'includeTime'}, $entry->{'-entryType'}, $entry->{'decision'}->{'-number'}, $entry->{'decision'}->{'-org'}, $entry->{'decision'}->{'-date'}, $blockType ];
    }
    if (scalar @{$this->{records}} > 5000 || (scalar @{$this->{records}} > 0 && !$entry)) {
        my $values = join ", ", ("( ?, ?, ?, ?, ?, ?, ?)") x @{$this->{records}};
        my $query  = "INSERT IGNORE into records(id, includeTime, entryType, decisionNumber, decisionOrg, decisionDate, blockType) values $values";
        my $sth    = $this->{dbh}->prepare($query);
        $sth->execute(map {@$_} @{$this->{records}});
        @{$this->{records}} = ();
    }
}

sub storeUrl {
    my $this    = shift;
    my $entryId = shift;
    my $urls    = shift;
    if ($entryId) {
        if (ref($urls) eq 'ARRAY') {
            foreach my $url (@$urls) {
                push @{$this->{urls}}, [ $entryId, $url ];
            }
        } elsif (ref($urls) eq 'HASH') {
            push @{$this->{urls}}, [ $entryId, $urls->{'#text'} ];
        } else {
            push @{$this->{urls}}, [ $entryId, $urls ];
        }
    }
    if (scalar @{$this->{urls}} > 5000 || (scalar @{$this->{urls}} > 0 && !$entryId)) {
        my $values = join ", ", ("( ?, ? )") x @{$this->{urls}};
        my $query  = "INSERT IGNORE into urls(recordId, url) values $values";
        my $sth    = $this->{dbh}->prepare($query);
        $sth->execute(map {@$_} @{$this->{urls}});
        @{$this->{urls}} = ();
    }
}

sub storeDomain {
    my $this    = shift;
    my $entryId = shift;
    my $domains = shift;
    if ($entryId) {
        if (ref($domains) eq 'ARRAY') {
            foreach my $url (@$domains) {
                push @{$this->{domains}}, [ $entryId, $url ];
            }
        } elsif (ref($domains) eq 'HASH') {
            push @{$this->{domains}}, [ $entryId, $domains->{'#text'} ];
        } else {
            push @{$this->{domains}}, [ $entryId, $domains ];
        }
    }
    if (scalar @{$this->{domains}} > 5000 || (scalar @{$this->{domains}} > 0 && !$entryId)) {
        my $values = join ", ", ("( ?, ? )") x @{$this->{domains}};
        my $query  = "INSERT IGNORE into domains(recordId, domain) values $values";
        my $sth    = $this->{dbh}->prepare($query);
        $sth->execute(map {@$_} @{$this->{domains}});
        @{$this->{domains}} = ();
    }
}

sub storeIp {
    my $this    = shift;
    my $entryId = shift;
    my $ips     = shift;
    if ($entryId) {
        if (ref($ips) eq 'ARRAY') {
            foreach my $ip (@$ips) {
                push @{$this->{ips}}, [ $entryId, $ip ] if (is_ipv4($ip));
            }
        } elsif (ref($ips) eq 'HASH') {
            push @{$this->{ips}}, [ $entryId, $ips->{'#text'} ] if (is_ipv4($ips->{'#text'}));
        } else {
            push @{$this->{ips}}, [ $entryId, $ips ] if (is_ipv4($ips));
        }
    }
    if (scalar @{$this->{ips}} > 5000 || (scalar @{$this->{ips}} > 0 && !$entryId)) {
        my $values = join ", ", ("( ?, inet_aton(?) )") x @{$this->{ips}};
        my $query  = "INSERT IGNORE into ips(recordId, ip) values $values";
        my $sth    = $this->{dbh}->prepare($query);
        $sth->execute(map {@$_} @{$this->{ips}});
        @{$this->{ips}} = ();
    }
}

sub storeIpSubnet {
    my $this      = shift;
    my $entryId   = shift;
    my $ipSubnets = shift;
    if ($entryId) {
        if (ref($ipSubnets) eq 'ARRAY') {
            foreach my $ipSubnet (@$ipSubnets) {
                if (my ($ip, $prefix) = ipv4_parse($ipSubnet)) {
                    push @{$this->{ipSubnets}}, [ $entryId, $ip, $prefix ];
                }
            }
        } elsif (ref($ipSubnets) eq 'HASH') {
            if (my ($ip, $prefix) = ipv4_parse($ipSubnets->{'#text'})) {
                push @{$this->{ipSubnets}}, [ $entryId, $ip, $prefix ];
            }
        } else {
            if (my ($ip, $prefix) = ipv4_parse($ipSubnets)) {
                push @{$this->{ipSubnets}}, [ $entryId, $ip, $prefix ];
            }
        }
    }
    if (scalar @{$this->{ipSubnets}} > 5000 || (scalar @{$this->{ipSubnets}} > 0 && !$entryId)) {
        my $values = join ", ", ("( ?, inet_aton(?), ? )") x @{$this->{ipSubnets}};
        my $query  = "INSERT IGNORE into ipSubnets(recordId, ip, prefix) values $values";
        my $sth    = $this->{dbh}->prepare($query);
        $sth->execute(map {@$_} @{$this->{ipSubnets}});
        @{$this->{ipSubnets}} = ();
    }
}

sub emptyTables {
    my $this = shift;
    $this->{dbh}->do('delete from records');
    $this->{dbh}->do('delete from deltas');

    #    $this->{dbh}->do('delete from urls');
    #    $this->{dbh}->do('delete from domains');
    #    $this->{dbh}->do('delete from ipSubnets');
}
1;
