package read_meinestadt_item;

use strict;

use LWP::UserAgent;
use JE;


sub fetch {
	my $this = shift;

	my $url = shift;
	my $odir = shift;
	my $name = shift;

	my $h={};
	
	print "i am the jobs.meinestadt.de-parser\n";
	return unless $url =~ q|jobs\.meinestadt\.de/braunschweig/standard\?id=|;
	print " and can handle $url\n";
	my $j = new JE;

	my $ua = new LWP::UserAgent;
	$ua->agent("Mozilla/5.0 (X11; U; Linux i686; de-de) AppleWebKit/531.2+ (KHTML, like Gecko) Version/5.0 Safari/531.2+ Ubuntu/10.04 LTS () Epiphany/2.30.2");
	my $req = new HTTP::Request 'GET' => "$url";
	my $res = $ua->request($req);
	my $doc = $res->is_success() ? $res->content() : "error:" . $res->code() . "  " . $res->message();

	if($doc =~ /E-Mail: <script type="text\/javascript">eval\((.*?)\)<\/script>/og) {
		my $decoded = $j->eval($1);
		my $inner = $j->eval(substr($decoded, 14, -1));
		if($inner =~ /mailto:(.*?)"/) {
			$$h{email}="$1";
			print "email: $1\n";
		}
	} else {
		if($doc =~ /Arbeitgeber(.*?)Arbeitsort/og) {
				print "TODO further extraction\n";
				$$h{snail}="TODO snailmail address";
		} else {
			print "nothing useful\n";
		}
	}
	return $h;
}

1;
