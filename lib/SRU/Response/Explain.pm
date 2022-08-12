package SRU::Response::Explain;
#ABSTRACT: A class for representing SRU explain responses

use strict;
use warnings;
use base qw( Class::Accessor SRU::Response );
use SRU::Response::Diagnostic;
use SRU::Utils qw( error );
use SRU::Utils::XML qw( element );
use Carp qw( croak );

=head1 SYNOPSIS
    
    use SRU::Response;
    my $response = SRU::Response::Explain->new( $request );

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

The constructor which requires that you pass in a SRU::Request::Explain
object.

=cut

sub new {
    my ($class,$request) = @_;
    return error( 'must pass in a SRU::Request::Explain object' )
        if ! ref($request) or ! $request->isa( 'SRU::Request::Explain' );

   my $self =  $class->SUPER::new( {
        version                 => $request->version(),
        record                  => '',
        diagnostics             => [],
        extraResponseData       => '',
        echoedExplainRequest    => $request->asXML(),
        stylesheet              => $request->stylesheet(),
    } );

    if ( $self->version ne '1.2' and $self->version ne '2.0' ) {
        $self->version('2.0');
        $self->addDiagnostic( SRU::Response::Diagnostic->newFromCode(5, 'version', 'sruResponse') );
    }

    return $self;
}

=head2 version()

=head2 record()

=head2 addDiagnostic()

Add a SRU::Response::Diagnostic object to the response.

=head2 diagnostics()

Returns an array ref of SRU::Response::Diagnostic objects relevant
for the response.

=head2 extraResponseData()

=head2 echoedExplainRequest()

=cut

SRU::Response::Explain->mk_accessors( qw(
    version 
    diagnostics
    extraResponseData
    echoedExplainRequest
    stylesheet
) );

sub record {
    my ( $self, $record ) = @_;
    if ( $record ) {
        croak( "must pass in a SRU::Response::Record object" )
            if ref($record) ne 'SRU::Response::Record';
        $self->{record} = $record;
    }
    return $self->{record};
}

=head2 asXML()

=cut

sub asXML {
    my $self = shift;
    my $stylesheet = $self->stylesheetXML();
    my $version = $self->version();
    my $echoedExplainRequest = $self->echoedExplainRequest();
    my $extraResponseData = $self->extraResponseData();
    my $diagnostics = $self->diagnosticsXML();
    my $record = $self->record() ? $self->record()->asXML() : '';

    my $ns    = $self->version() eq '1.2' ? 'sru' : 'sruResponse';
    my $nsurl = $self->version() eq '1.2' ? 'http://www.loc.gov/zing/srw/' : 'http://docs.oasis-open.org/ns/search-ws/sruResponse';

    my $xml = 
<<"EXPLAIN_XML";
<?xml version="1.0" encoding="utf-8"?>
$stylesheet
<$ns:explainResponse xmlns:$ns="$nsurl">
  <$ns:version>$version</$ns:version>
$record
$echoedExplainRequest
$extraResponseData
$diagnostics
</$ns:explainResponse>
EXPLAIN_XML
    return $xml;
}

1;
