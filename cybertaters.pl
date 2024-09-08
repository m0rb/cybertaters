#!/usr/bin/perl -w 
#
# CyberTaters: Reborn and Refactored (Bluesky Edition)
#
# The classic Cybersecurity bot is back and raising heck
# circa 2014 style
#
# 2024-09-08 -- morb_commat_misentropic_commercial

use warnings;
use strict;

use lib ".";

use Encode;
use JSON::Parse    qw(parse_json);
use HTML::Entities;
use MyLib::ATProto qw(post_bluesky);
use AnyEvent::WebSocket::Client;

binmode( STDOUT, ":utf8" );
$| = 1;

my ($smax,$spad) = (300,int(rand(300)));
my $wss     = "wss://jetstream.atproto.tools/subscribe";
   $wss    .= "?wantedCollections=app.bsky.feed.post";

my $client  = AnyEvent::WebSocket::Client->new;
my $cv      = AE::cv;

our @prev   = qw(FF FF);

$client->connect($wss)->cb(sub {
  our $input = eval { shift->recv };
  if ($@) { warn $@; }
  $input->on(each_message => sub {
    my ($con,$message) = (@_);
    my $content = parse_json($message->{'body'});
    my $did = $content->{did};
    my $text = $content->{commit}->{record}->{text};
    if ($text && $text =~ /cyber/i) {
      $text = decode("UTF-8",$text);
      my $sleep = int(rand($smax) + ($spad));
      &zero( $did, $text, $sleep, @prev);
      pop @prev; pop @prev;
      push @prev, ($did,$text)
    }
  });
  $input->on(finish => sub { exit; });
});

$cv->recv;

sub camel($$) {
  my ($old, $new) = @_;
  my $mask = uc $old ^ $old;
  uc $new | $mask . substr($mask, -1) x (length($new) - length($old));
}

sub zero {
  my ($did, $text, $sleep, @prev) = @_;
  my %swap = ( 
  "iot" => "iop", "cybr" => "ptto", "hack" => "mash", "cloud" => "clown", 
  "cyber" => "potato", "fveys" => "fguys", "hacks" => "mashes", 
  "darkweb" => "derpweb", "fiveeyes" => "fiveguys", "five-eyes" => "five guys",
  "cloudstrike" => "clownstrike" 
  );

  my @output;
  my @input = split(/(\s+)/, $text);
  my $wc = 0;

  next if ( $did  =~ /(a3ul5q5rkrk4im4sesowx4b3|z6b4y3evxxb5ufbfn5pa65fa|\
                       mktcznqxrcy6gf3ck4rmjos4|$prev[0])/ );
  next if ( $text =~ /(CyberTaters|Bull|alt4me|OPTCRACK|$prev[1])/i );

  foreach my $wrd (@input) {
  next if ($wc == 0 && $wrd =~ /(^|[^@\w])@(\w+)\.(\w+)\b/ && \
                     ! $wrd =~ /(^http(s)?\:\/\/)/ );
    unless ($wrd =~ /(^|[^@\w])@(\w+)\.(\w+)\b/) {
      foreach(keys %swap) {
        $wrd =~ s/($_)/camel($1,"$swap{$_}")/egi; 
      }
      decode_entities($wrd);decode_entities($wrd);
      $wc++;
    }
  push @output, $wrd;
  }

  my $out = join("", @output);
  $out =~ s/(internet of things)/camel($1, "internet of potatoes")/egi;
  $out =~ s/(five eyes)/camel($1, "five guys")/egi;

  $SIG{ALRM} = sub { die; };

  eval {
    alarm(15);
    post_bluesky({account => "cybertaters", text => $out});
    printf("[+] <$did> $out :: %02d:%02d:%02d\n",(gmtime($sleep))[2,1,0]);
    alarm(0); select(undef,undef,undef,$sleep);
  } or printf("[!] <$did> $out\n");
}
