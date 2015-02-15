#!/usr/bin/perl -w

use LWP::UserAgent;
use JSON qw( decode_json );
 
my $ua = LWP::UserAgent->new;


 
my $server_endpoint = "http://www.kimsufi.com/fr/js/dedicatedAvailability/availability-data.json";
 
# set custom HTTP request header fields
my $req = HTTP::Request->new(GET => $server_endpoint);
$req->header('content-type' => 'application/json');
my $avaiok;
my $type; 
my $ref;
my $sms;
my $smsformat;
 
my $resp = $ua->request($req);
if ($resp->is_success) {
    my $message = $resp->decoded_content;

	my $decoded = decode_json($message);

	my @Refs = @{ $decoded->{'availability'} };
	foreach my $f ( @Refs ) {
	if($f->{"reference"} eq "150sk10") { 
	#if($f->{"reference"} eq "150sk22") { 
		$ref = $f->{"reference"};
		#print $f->{"reference"} . "\n";
			my @Avai = @{ $f->{'zones'} };
			foreach my $p ( @Avai) {
				#print "to zone " .  $p->{"zone"} . " there is " . $p->{"availability"} . "\n";
				if($p->{'availability'} ne "unknown") { $avaiok = $p->{"zone"}; $type = $p->{"availability"}; }
			}
		}
	}

	if(-e "/tmp/sms_kimsufi") { exit; }

	if($type) {
		system("touch /tmp/sms_kimsufi");
		$sms = "Ref+:+$ref+find+in+$avaiok+:+avail:+$type";
		$smsformat = "http://playsms.*******/index.php?app=ws&u=******&h=*******&op=pv&to=06*******&msg=$sms";
		my $req2 =  HTTP::Request->new(GET => $smsformat);
		my $resp2 = $ua->request($req2);
		if($resp2->is_success) { print "sms sent\n"; }
		#print $smsformat . "\n";
	}
	
}
else {
    print "HTTP GET error code: ", $resp->code, "\n";
    print "HTTP GET error message: ", $resp->message, "\n";
}
