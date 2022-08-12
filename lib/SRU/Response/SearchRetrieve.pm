package SRU::Response::SearchRetrieve;
#ABSTRACT: A class for representing SRU searchRetrieve responses

use strict;
use warnings;
use base qw( Class::Accessor SRU::Response );
use SRU::Utils::XML qw( element );
use SRU::Utils qw( error );
use SRU::Response::Record;

=head1 SYNOPSIS

    ## create response from the request object
    my $response = SRU::Response::SearchRetrieve->new( $request );

    ## add records to the response
    foreach my $record ( @records ) { $response->addRecord( $record ); }

    ## print out the response as XML
    print $response->asXML();

=head1 DESCRIPTION

SRU::Response::SearchRetrieve provides a framework for bundling up
the response to a searchRetrieve request. You are responsible for
generating the XML representation of the records, and the rest
should be taken care of.

=head1 METHODS

=head2 new()

=cut

sub new {
    my ($class,$request) = @_;
    return error( 'must pass in a SRU::Request::SearchRetrieve object' )
        if ! ref($request) or ! $request->isa( 'SRU::Request::SearchRetrieve' );

    my $self =  $class->SUPER::new( {
        version                         => $request->version(),
        numberOfRecords                 => 0,
        records                         => [],
        resultSetId                     => undef,
        resultSetIdleTime               => undef,
        nextRecordPosition              => undef,
        diagnostics                     => [],
        extraResponseData               => '',
        echoedSearchRetrieveRequest     => $request->asXML(),
        stylesheet                      => $request->stylesheet(),
    } );

    $self->addDiagnostic( SRU::Response::Diagnostic->newFromCode(7,'version') )
        if ! $self->version();

    $self->addDiagnostic( SRU::Response::Diagnostic->newFromCode(7, 'query') )
        if ! $request->query();

    {
        no warnings 'numeric';
        if ( defined $request->startRecord and int($request->startRecord) < 1 ) {
            $self->addDiagnostic( SRU::Response::Diagnostic->newFromCode(6,'startRecord') );
        }
        if ( defined $request->startRecord and int($request->startRecord) > 10_000_000 ) {
            $self->addDiagnostic( SRU::Response::Diagnostic->newFromCode(61, 'startRecord') );
        }
    }
    if ( defined $request->maximumRecords and $request->maximumRecords !~ /^[0-9]+$/ ) {
        $self->addDiagnostic( SRU::Response::Diagnostic->newFromCode(6, 'maximumRecords') );
    }
    if ( defined $request->recordXMLEscaping and $request->recordXMLEscaping !~ /^(?:string|xml)$/ ) {
        $self->addDiagnostic( SRU::Response::Diagnostic->newFromCode(71, 'recordXMLEscaping') );
    }
    if ( defined $request->recordPacking and $request->recordPacking !~ /^(un?)packed$/ ) {
        $self->addDiagnostic( SRU::Response::Diagnostic->newFromCode(71, 'recordPacking') );
    }

    return $self;
}

=head2 numberOfRecords()

Returns the number of results associated with the object.

=cut

sub numberOfRecords {
    my ($self,$num) = @_;
    if ( $num ) { $self->{numberOfRecords} = $num; }
    return $self->{numberOfRecords};
}

=head2 addRecord()

Add a SRU::Response::Record object to the response.

    $response->addRecord( $r );

If you don't pass in the right sort of object you'll get back
undef and $SRU::Error will be populated appropriately.

=cut

sub addRecord {
    my ($self,$r) = @_;
    return if ! $r->isa( 'SRU::Response::Record' );
    ## set recordPosition if necessary
    if ( ! $r->recordPosition() ) { 
        $r->recordPosition( $self->numberOfRecords() + 1 );
    }
    $self->{numberOfRecords}++;
    push( @{ $self->{records} }, $r );
}

=head2 records()

Gets or sets all the records associated with the object. Be careful
with this one :) You must pass in an array ref, and expect an
array ref back.

=cut

=head2 resultSetId()

=head2 resultSetIdleTime()

=head2 nextRecordPosition()

=head2 diagnostics()

=head2 extraResponseData()

=head2 echoedSearchRetrieveRequest()

=cut

SRU::Response::SearchRetrieve->mk_accessors( qw(
    version 
    records                     
    resultSetId                 
    resultSetIdleTime           
    nextRecordPosition          
    diagnostics                 
    extraResponseData           
    echoedSearchRetrieveRequest 
    stylesheet
) );

=head2 asXML()

    asXML(encoding=>"ISO-8859-1")

Returns the object serialized as XML. UTF-8 and UTF-16 are default encodings if you don't pass the encoding parameter. You can define different encoding in order to parse you XML document correctly.

=cut

sub asXML {
    my $self     = shift;
    my %args     = @_;
    my $encoding = $args{ encoding };

    my $numberOfRecords = $self->numberOfRecords();
    my $stylesheet = $self->stylesheetXML();

    my $ns    = $self->version() eq '1.2' ? 'sru' : 'sruResponse';
    my $nsurl = $self->version() eq '1.2' ? 'http://www.loc.gov/zing/srw/' : 'http://docs.oasis-open.org/ns/search-ws/sruResponse';

    my $version = element( $ns, 'version', $self->version() );
    my $diagnostics = $self->diagnosticsXML();
    my $echoedSearchRetrieveRequest = '';
#    if ( !$diagnostics ) {
        $echoedSearchRetrieveRequest = $self->echoedSearchRetrieveRequest();
#    }
    my $resultSetIdleTime = $self->resultSetIdleTime();
    my $resultSetId = $self->resultSetId();

    my $extraResponseData = '';
    if ( $self->extraResponseData() ) {
        $extraResponseData .= '<$ns:extraResponseData>' . $self->extraResponseData() . '</$ns:extraResponseData>';
    }
    my $xmltitle;
    if( $encoding ) {
        $xmltitle = "<?xml version='1.0' encoding='$encoding'?>";
    }
    else {
        $xmltitle = "<?xml version='1.0'?>";
    }

    my $xml = 
<<SEARCHRETRIEVE_XML;
$xmltitle
$stylesheet
<$ns:searchRetrieveResponse xmlns:$ns="$nsurl">
$version
<$ns:numberOfRecords>$numberOfRecords</$ns:numberOfRecords>
SEARCHRETRIEVE_XML

    $xml .= "<$ns:resultSetId>$resultSetId</$ns:resultSetId>"
        if defined($resultSetId);
    $xml .= "<$ns:resultSetIdleTime>$resultSetIdleTime</$ns:resultSetIdleTime>\n"
        if defined($resultSetIdleTime);

    if( $numberOfRecords ) {
        $xml .= "<$ns:records>\n";

        ## now add each record
        foreach my $r ( @{ $self->{records} } ) {
            $xml .= $r->asXML()."\n";
        }

        $xml .= "</$ns:records>\n";
    }

    $xml .=
<<SEARCHRETRIEVE_XML;
$diagnostics
$extraResponseData 
$echoedSearchRetrieveRequest
</$ns:searchRetrieveResponse>
SEARCHRETRIEVE_XML

    return $xml;
}

1;
