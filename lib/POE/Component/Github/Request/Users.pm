package POE::Component::Github::Request::Users;

use strict;
use warnings;
use HTTP::Request::Common;
use vars qw($VERSION);

$VERSION = '0.02';

use Moose;
use Moose::Util::TypeConstraints;

use URI::Escape;

with 'POE::Component::Github::Request::Role';

has cmd => (
  is       => 'ro',
  isa      => enum([qw(
		search 
		show 
		followers 
		following 
		update 
		follow 
		unfollow 
		pub_keys 
		add_key 
		remove_key 
		emails 
		add_email 
		remove_email
              )]),
  required => 1,
);

has user => (
  is       => 'ro',
  default  => '',
);

#Users
#  - public ->
#       - search - user/search/:search
#       - show   - user/show/:username
#       - followers - user/show/:user/followers
#       - following - user/show/:user/following
#  - authenticated ->
#       - show - user/show/:username
#       - update - user/show/:username
#       - follow - user/follow/:user
#       - unfollow - user/unfollow/:user
#       - pub_keys - user/keys
#       - add_key - user/key/add
#       - remove_key - user/key/remove
#       - emails - user/emails
#       - add_email - user/email/add
#       - remove_email - user/email/remove

sub request {
  my $self = shift;
  # Work out if authenticated is required or not
  AUTHENTICATED: {
    if ( $self->login and $self->token ) { # Okay authenticated required.
       if ( grep { $_ eq $self->cmd } qw(search followers following) ) {
          last AUTHENTICATED;
       }
       # Simple stuff no values required.
       my $data = [ login => $self->login, token => $self->token ];
       if ( $self->cmd =~ /^(show|follow|unfollow|pub_keys|emails)$/ ) {
	  my $url = 'https://' . join '/', $self->api_url, 'user';
	  return POST( join('/', $url, 'keys'), $data ) if $self->cmd eq 'pub_keys';
	  return POST( join('/', $url, 'emails' ), $data ) if $self->cmd eq 'emails';
	  return POST( join('/', $url, $self->cmd, $self->user ) );
       }
       # These have values to pass
       if ( $self->cmd =~ /^(update|add_key|remove_key|add_email|remove_email)$/ ) {
	  my $url = 'https://' . join '/', $self->api_url, 'user';
	  push @{ $data }, %{ $self->values };
	  return POST( join('/', $url, 'show', $self->user), $data ) if $self->cmd eq 'update';
	  my ($action,$cmd) = split /\_/, $self->cmd;
	  return POST( join('/', $url, $cmd, $action ), $data );
       }
    }
  }
  if ( $self->cmd =~ /^follow(ers|ing)$/ ) {
     return GET( $self->scheme . join '/', $self->api_url, 'user', 'show', $self->user, $self->cmd );
  }
  if ( $self->cmd =~ /^(show|search)$/ ) {
     return GET( $self->scheme . join '/', $self->api_url, 'user', $self->cmd, $self->user );
  }
  return;
}

no Moose;

1;
__END__