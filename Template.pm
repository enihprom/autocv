package Template;
#TODO Template_DE
use strict;
use Data::Dumper;
use feature 'say';
use warnings;
use Mail::File;
use Glib;
use Glib qw( TRUE FALSE );
use Gtk2 '-init';

my $id_url_entry;
my $email_entry;
my $pregenerated_entry;
my $job_entry;
my $window;
my $generate_button;
my $discard_button;
my $openidurl_button;
my $name_label;
my $vbox;
my $buttonbox;

my $blockhash;
my $odir;
my $blockname;
my $block_ref;

sub _initialize {
	$id_url_entry = Gtk2::Entry->new();
	$email_entry = Gtk2::Entry->new();
	my $buffer = &create_buffer;
	$pregenerated_entry = Gtk2::TextView->new_with_buffer($buffer);
	my $iter = $buffer->get_start_iter;
	$buffer->insert($iter, $$block_ref{'default_text'} || "...");
	$job_entry = Gtk2::Entry->new();

	$window = Gtk2::Window->new();

	$generate_button = Gtk2::Button->new('Bewerbung erzeugen');
	$discard_button = Gtk2::Button->new('Ergebnisse verwerfen');
	$openidurl_button = Gtk2::Button->new('Im Browser öffnen');
	$name_label = Gtk2::Label->new();

	$vbox = Gtk2::VBox->new();
	$buttonbox = Gtk2::HBox->new();
}

sub new {
	my $class = shift;
	my $self = {};
	bless $self, $class;
	$self->_initialize();
	return $self;
}

sub close_form
{
	Gtk2->main_quit();
	#exit (0);
}

sub discard {
	# TODO delete block snippet file
	#unlink $_->filename
	close_form();
}

sub openidurl {
	my $url = $id_url_entry->get_text();
	print "opening '$url' ...\n";
	system "luakit $url &";
}

sub array2nsv {
	my $v = shift;
	if (ref($v) ne 'ARRAY') {
		print "no array\n";
		return $v;
	} else {
		print "array\n";
		my $s="";
		map { $s="$_\n"; } @{$v};
		return $s;
	}
}

sub create_buffer {
	my $buffer = Gtk2::TextBuffer->new();
	# space for more features
}

sub generate {
	my $this = shift;
	#$blockhash = shift;
	#$odir = shift;
	#$blockname = shift || "_unknown_";
	#$block_ref = $blockhash->vars();
	print "based on this data\n";
	map { print "$_ => $$block_ref{$_}\n" } keys %$block_ref; #FIXME remove
	print "generating ...\n";

	my $job = $job_entry->get_text();
	my $prolog = $$block_ref{'default.default_prolog'} || "";
	my $start = $pregenerated_entry->get_buffer->get_start_iter;
	my $end = $pregenerated_entry->get_buffer->get_end_iter;
	my $text = $pregenerated_entry->get_buffer->get_text($start, $end, FALSE);
	my $epilog = $$block_ref{'default.default_epilog'} || "";
	my $greez =  $$block_ref{'default.default_greeting'} || "";
	my $signature = $$block_ref{'default.signature_name'} || "";

	my $bcc = $$block_ref{'default.default_bcc'} || "";
	my $subject = sprintf($$block_ref{'default.default_subject'}, $job) || "";

	my $common_body = "\n\n$prolog,\n\n$text\n\n$epilog\n\n\n$greez\n\n$signature\n";

	if (!$$block_ref{'default.email'}) {
		$$block_ref{'default.email'} = $email_entry->get_text();
	} 
	if ($$block_ref{'default.email'}) {
		print "generating e-mail $odir/$blockname-????.eml\n";
		my $mail = Mail::File->new(template => "$odir/$blockname-XXXX.eml");
		$mail->From($$block_ref{'default.principal_email'});
		$mail->To($$block_ref{'default.email'});
		$mail->Bcc($bcc);
		$mail->Subject($subject);
		$mail->Body($common_body);
		$mail->send() and print "email generation successful\n" or die $@;

	} else {
       	print "no email-address - ";
	 	if($$block_ref{'default.employer_address'}) {
           print "generating latex output\"";
           print " - - - TODO  - - -\n";
        } else {
            print "nothing to do\n";
		}
	}
}


sub view_form {
	my $this = shift;
	$blockhash = shift;
	$odir = shift;
	$blockname = shift || "_unknown_";
	$block_ref = $blockhash->vars();
	print "blockname: $blockname\n";
	map { print "$_ => $$block_ref{$_}\n" } keys %$block_ref; #FIXME remove
	print "\n";

	$name_label->set_markup("Datensatz <b>$blockname</b>");
	$id_url_entry->set_text($$block_ref{'default.id_url'} || "");
	$email_entry->set_text($$block_ref{'default.email'} || "");
	$job_entry->set_text($$block_ref{'default.job'} || "");
	$buttonbox->add($openidurl_button);
	$buttonbox->add($discard_button);
	$buttonbox->add($generate_button);

	$vbox->pack_start($name_label, FALSE, FALSE, 0);
	$vbox->pack_start(Gtk2::HSeparator->new, FALSE, FALSE, 0);
	$vbox->pack_start(Gtk2::Label->new('Identifikations URL'), FALSE, FALSE, 0);
	$vbox->pack_start($id_url_entry, FALSE, FALSE, 0);

	$vbox->pack_start(Gtk2::Label->new('E-Mail Addresse'), FALSE, FALSE, 0);
	$vbox->pack_start($email_entry, FALSE, FALSE, 0);
	$vbox->pack_start(Gtk2::HSeparator->new, FALSE, FALSE, 0);
	
	$vbox->pack_start(Gtk2::Label->new('Berufsbezeichnung'), FALSE, FALSE, 0);
	$vbox->pack_start($job_entry, FALSE, FALSE, 0);
	$vbox->pack_start(Gtk2::HSeparator->new, FALSE, FALSE, 0);

	$vbox->pack_start(Gtk2::Label->new('erzeugte Inhaltsvorlage'), FALSE, FALSE, 0);
	$vbox->pack_start($pregenerated_entry, TRUE, TRUE, 0);

	$vbox->pack_start(Gtk2::HSeparator->new, FALSE, FALSE, 0);
	$vbox->pack_start($buttonbox, FALSE, FALSE, 0);

	$window->add($vbox);

	#my $call_discard = sub { discard($odir, $blockname); };
	$window->signal_connect(destroy => \&discard);
	$discard_button->signal_connect(clicked => \&discard);
	#my $call_generate = sub { generate($blockhash, $odir, $blockname); };
	$generate_button->signal_connect(clicked => \&generate);
	#my $call_openidurl = sub { openidurl($id_url_entry->get_text()); };
	$openidurl_button->signal_connect(clicked => \&openidurl);

	$window->set_border_width(20);
	$window->set_title("AutoCV Vorlage");
	$window->set_default_size(250,450);
	$window->show_all();
	Gtk2->main();
}

1;
