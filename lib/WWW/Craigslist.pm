package WWW::Craigslist;

use strict;
use warnings;

our $VERSION = 0.01;

=head1 NAME

WWW::Craigslist - An API to interface with WWW::Craigslist

=cut

use URI;
use WWW::Mechanize;

my $default_uri = "http://www.craigslist.org";
my $auth_uri = "https://accounts.craigslist.org/login?rt=P&rp=/sfo";

=head1 METHODS

=over 4

=item C<new>

Creates a new craigslist object

  $craigslist = WWW::Craigslist->new( uri => $uri, 
                                      login => $login, 
                                      password => $password );

  $craigslist = WWW::Craigslist->new( uri => $uri, 
                                      zone => $zone, 
                                      login => $login, 
                                      password => $password );

=over 4

=item opt arg: c<$uri> ( string )

The uri of the craigslist site you are using (e.g. 
http://atlanta.craigslist.org).  Defaults to http://www.craigslist.org.

=item opt arg: C<$login> ( string )

The login (also known as username) for the craigslist account.

=item opt arg: C<$password> ( string )

The password for the craigslist account.

=item opt arg: C<$zone> ( string )

The zone for the craigslist account.

=back

=cut

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    $self->_init(@_);

    return $self;
}

=item C<_init>

Initializes the craigslist object.

=cut

sub _init {
    my ($self, %args) = @_;

    $args{uri} = $default_uri unless $args{uri};
    if ( $args{uri} && $args{uri} !~ m/(.*?)craigslist.org$/ ) {
        die "Invalid uri for Craigslist specified";
    }
    
    $self->uri(URI->new($args{uri}));
    
    $self->mech(WWW::Mechanize->new);

    $self->login($args{login}) if $args{login};
    $self->pass($args{pass})   if $args{pass};
    $self->auth_uri($auth_uri);
    $self->zone($args{zone}) if $args{zone};
}

=item C<login>

The login to authenticate with for the given craigslist site.

=cut

sub login {
    my $self = shift;
    @_ and $self->{_login} = shift;
    $self->{_login};
}

=item C<password>

The password to authenticate with for craigslist account.

=cut

sub password {
    my $self = shift;
    @_ and $self->{_password} = shift;
    $self->{_password};
}

=item C<zone>

Accessor / Mutator which provides the "zone".  The zone will either be a city
or a neighborhood.

=cut

sub zone {
    my $self = shift;
    @_ and $self->{_zone} = shift;
    $self->{_zone};
}

=item C<uri>

Accessor / Mutator which provides the url of the Craigslist site.

=cut

sub uri {
    my $self = shift;
    @_ and $self->{_uri} = shift;
    $self->{_uri};
}

=item C<auth_uri>

The uri which can be used to authenticate craigslist accounts.

=cut

sub auth_uri {
    my $self = shift;
    @_ and $self->{_auth_uri} = shift;
    $self->{_auth_uri};
}

=item C<logged_in>

Returns true if logged in.

=cut

sub logged_in {
    my $self = shift;
    @_ and $self->{_logged_in} = shift;
    $self->{_logged_in};
}

=item C<mech>

Accessor / Mutator for the has_a WWW::Mechanize object.

=cut

sub mech {
    my $self = shift;
    @_ and $self->{_mech} = shift;
    $self->{_mech};
}

=item C<authenticate>

Authenticate with the specified Craigslist site.  Pass optional arguments
for login and password to override object instance attributes.

  $success = $craigslist->auth;

=over 4

=item obj: C<$craigslist> ( C<WWW::Craigslist> object )

=item ret:  C<$success> ( integer )

On successful authentication this method returns true.

=item exception:  "No login attribute set"

This exception thrown when the login is not set.

=item exception:  "No password attribute set"

This exception thrown when the password is not set.

=back

=cut

sub authenticate {
    my $self = shift;

    unless ($self->login and $self->password) {
        die "No login set!"    unless $self->login;
        die "No password set!" unless $self->password;
    }

    $self->mech->get($self->auth_uri);
    $self->mech->submit_form(
                             form_name => "login",
                             fields    => {
                                        inputEmailHandle => $self->login,
                                        inputPassword    => $self->password,
                                       },
                            );

    if ($self->mech->success and $self->mech->content !~ m/error/i) {
        $self->logged_in(1);
        return 1;
    }
    else {
        return;
    }
}

=item C<post_free>

Posts an item in the free section.

  $success = $self->post_free( subject => $subject, 
                               body => $body, 
                               images => [ $image, .. ] );

=over 4

=item obj: C<$self> ( C<WWW::Craigslist> object )

=item ret:  C<$success> ( integer )

On successful post this method returns true.

=item req arg: C<$subject> ( string )

The subject for the post.

=item req arg: C<$body> ( string )

The body for the post.

=item opt arg: C<$images> ( array reference )

An array reference of image files to be posted.

=item exception:  "Must be logged in to post"

Exception thrown when the craigslist object is not logged in

=item exception:  "Subject is required"

=back

=cut

sub post_free {
    my ($self, %args) = @_;

    die "Must be logged in to post" unless $self->logged_in;
    die "Subject is required" unless $args{subject};
    die "Body is required" unless $args{body};

    # Begin crawling
    $self->mech->follow_link(text_regex => qr/wanted/);
    if (!$self->mech->success) {
        die "Failed at url "
          . $self->mech->url
          . ", status "
          . $self->mech->status;
    }

    # Click on the free section
    $self->mech->follow_link(text_regex => qr/free/);
    unless ($self->mech->success) {
        die "Failed at url "
          . $self->mech->url
          . ", status "
          . $self->mech->status;
    }

    # For specific location
    if (my $zone = $self->zone) {
        $self->mech->follow_link(text_regex => qr/$zone/);
        unless ($self->mech->success) {
            die "Failed at url "
              . $self->mech->url
              . ", status "
              . $self->mech->status;
        }
    }
    else {
        $self->mech->follow_link(text_regex => qr/bypass this step/i);
        unless ($self->mech->success) {
            die "Failed at url "
              . $self->mech->url
              . ", status "
              . $self->mech->status;
        }
    }

    # Post the ad
    my %fields = (
                  PostingTitle => $args{subject},
                  PostingBody  => $args{body},
                  Ask          => 0,
                 );

    # Do we have images?
    my $button;
    if (defined $args{images}->[0]) {
        $button = "imagesForm";
    }
    else {
        $button = "previewForm";
    }

    $self->mech->submit_form(
                             form_number => 1,
                             button      => $button,
                             fields      => \%fields,
                            );
    unless ($self->mech->success) {
        die "Failed at url "
          . $self->mech->url
          . ", status "
          . $self->mech->status;
    }

    # Handle images
    if (defined $args{images}->[0]) {
        my $ok = $self->_submit_images( $args{images});
    }

    # The final page of the posting
    $self->mech->submit_form(form_number => 1,
                             button      => "finishForm",);

    unless ($self->mech->success) {
        die "Failed at url "
          . $self->mech->url
          . ", status "
          . $self->mech->status;
    }

    return 1;
}

=item C<_submit_images>

Posts the image to craigslist

=cut

sub _submit_images {
    my ($self, $images) = @_;
    
    my %fields;
    ($fields{"file$_"} = $images->[$_] ) for 0..@{$images};
    
    $self->mech->submit_form(form_number => 1,
                             fields      => \%fields);
    
    if ($self->mech->success) {
        print STDERR "Added images ", join(' ', @{$images}), "\n" if $self->debug;
    }
    else {
        die "Failed to add images, response: \n", $self->mech->status, $self->mech->response;
    }
    return 1 and unlink $_ for @{$images};
}

1;

__END__

