package EnsEMBL::Web::Problem;

### Object to store errors generated by web code

### Usage:  my $problem =  EnsEMBL::Web::Problem->new( $problem_type, $title, $description );
###         if ($problem->isFatal){..}
 
### Possible error types: 
###	  mapped_id, 
###	  multiple_matches, 
### 	no_match, 
###	  fatal_error

use strict;

sub new{
  ### c
  my $class = shift;       
  my ($type,$name,$description) = @_;
  my $self = { 	'type'=>$type, 
  				'name'=>$name, 
				'description'=>$description };
  bless $self,$class;
}


sub type {$_[0]->{type}} ### a
sub name {$_[0]->{name}} ### a
sub description {$_[0]->{description}} ### a

sub get_by_type       {$_[0]->{type} =~ /$_[1]/i} ### typematch
sub isFatal           {$_[0]->{type} =~ /fatal/i} ### typematch
sub isNoMatch         {$_[0]->{type} =~ 'no_match'} ### typematch
sub isMultipleMatches {$_[0]->{type} =~ 'multiple_matches'} ### typematch
sub isMappedId        {$_[0]->{type} =~ 'mapped_id'} ### typematch

sub isNonFatal        {
  ### typematch
  my $self = shift;
  my $non_fatal = 1 ;
  if( ($self->{'type'} eq 'non_fatal' || $self->isNoMatch || $self->isMultipleMatches || $self->isMappedId ) &&  !$self->isFatal){
    return $non_fatal;
  }
  return 0;
}

1;
