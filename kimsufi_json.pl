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
my $refdemand = $ARGV[0];
my $phone = $ARGV[1];
my $tempfile = "/tmp/sms_kimsufi_$refdemand\_$phone";

#Ex: /kimsufi_json.pl 143sys10 06XXXXXXXXX
#Ex ref: 150sk10 . 150sk22 . 143sys10

if(!$refdemand || !$phone) { print "no ref or no phone\n"; exit; }

 
my $resp = $ua->request($req);
if ($resp->is_success) {
    my $message = $resp->decoded_content;

	my $decoded = decode_json($message);

	my @Refs = @{ $decoded->{'availability'} };
	foreach my $f ( @Refs ) {
		if($f->{"reference"} eq $refdemand) {
			$ref = $f->{"reference"};
				my @Avai = @{ $f->{'zones'} };
				foreach my $p ( @Avai) {
					if($p->{'availability'} ne "unknown" && $p->{'availability'} ne "unavailable") { $avaiok = $p->{"zone"}; $type = $p->{"availability"}; }
				}
		}
	}

	if(-e $tempfile) { exit; }

	if($type) {
		system("touch $tempfile");
		$sms = "Ref+:+$ref+find+in+$avaiok+:+avail:+$type";
		$smsformat = "http://playsms.*******/index.php?app=ws&u=******&h=*******&op=pv&to=$phone&msg=$sms";
		my $req2 =  HTTP::Request->new(GET => $smsformat);
		my $resp2 = $ua->request($req2);
		if($resp2->is_success) { print "sms sent\n"; }
	}
	
}
else {
    print "HTTP GET error code: ", $resp->code, "\n";
    print "HTTP GET error message: ", $resp->message, "\n";
}
