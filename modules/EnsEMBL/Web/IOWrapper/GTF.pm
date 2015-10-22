=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::IOWrapper::GTF;

### Wrapper for Bio::EnsEMBL::IO::Parser::GTF, which builds
### simple hash features from a GFF2 or GFF file, suitable 
### for use in the drawing code 

use strict;
use warnings;
no warnings 'uninitialized';

use parent qw(EnsEMBL::Web::IOWrapper::GXF);


sub build_feature {
### Parse exons separately from other features
  my ($self, $data, $track_key, $slice) = @_;

  my $attribs       = $self->parser->get_attributes;
  my $transcript_id = $attribs->{'transcript_id'};
  my $type          = $self->parser->get_type;

  if ($transcript_id) { ## Feature is part of a transcript!
    if ($data->{$track_key}{'transcripts'}{$transcript_id}) {
      push @{$data->{$track_key}{'transcripts'}{$transcript_id}}, $self->create_hash($data->{$track_key}{'metadata'}, $slice);
    }
    else {
      $data->{$track_key}{'transcripts'}{$transcript_id} = [$self->create_hash($data->{$track_key}{'metadata'}, $slice)];
    }
  }
  else { ## Single feature - add to track as normal
    if ($data->{$track_key}{'features'}) {
      push @{$data->{$track_key}{'features'}}, $self->create_hash($data->{$track_key}{'metadata'}, $slice);
    }
    else {
      $data->{$track_key}{'features'} = [$self->create_hash($data->{$track_key}{'metadata'}, $slice)];
    }
  }
}

sub post_process {
### Reassemble sub-features back into features
  my ($self, $data) = @_;
  #use Data::Dumper;
  #warn Dumper($data);
  
  while (my ($track_key, $content) = each (%$data)) {
    next unless $content->{'transcripts'};
    while (my ($transcript_id, $segments) = each (%{$content->{'transcripts'}})) {

      my $no_of_segments = scalar(@{$segments||[]});
      next unless $no_of_segments;

      my ($hashref, %transcript);

      ## Is this a transcript plus exons, or just exons?
      my $no_separate_transcript = 0;
      if ($segments->[0]{'type'} eq 'transcript') {
        my $hashref = shift @$segments;
      }
      else {
        $no_separate_transcript = 1;
        $hashref = $segments->[0];
      }
      %transcript = %$hashref;

      $transcript{'label'}    ||= $transcript{'transcript_name'} || $transcript{'transcript_id'};
      $transcript{'structure'}  = [];

      ## Now turn exons into internal structure

      ## Sort elements: by start then by reverse name, 
      ## so we get UTRs before their corresponding exons/CDS
      my @ordered_segments = sort {
                                    $a->{'start'} <=> $b->{'start'}
                                    || lc($b->{'type'}) cmp lc($a->{'type'})
                                  } @$segments;
      my $args = {'seen' => {}, 'no_separate_transcript' => $no_separate_transcript};   
      
      foreach (@ordered_segments) {
        ($args, %transcript) = $self->add_to_transcript($_, $args, %transcript);
      }
      #warn Dumper(\%transcript);

      if ($data->{$track_key}{'features'}) {
        push @{$data->{$track_key}{'features'}}, \%transcript; 
      }
      else {
        $data->{$track_key}{'features'} = [\%transcript]; 
      }
    }
    ## Transcripts will be out of order, owing to being stored in hash
    ## Sort by start coordinate, then reverse length (i.e. longest first)
    my @sorted_features = sort {
                                $a->{'seq_region'} cmp $b->{'seq_region'}
                                || $a->{'start'} <=> $b->{'start'}
                                || $b->{'end'} <=> $a->{'end'}
                                } @{$data->{$track_key}{'features'}};
    $data->{$track_key}{'features'} = \@sorted_features;
    #delete $data->{$track_key}{'transcripts'};
  }
  #warn "###########################################################";
  #warn Dumper($data);
}

sub create_hash {
### Create a hash of feature information in a format that
### can be used by the drawing code
### @param metadata - Hashref of information about this track
### @param slice - Bio::EnsEMBL::Slice object
### @return Hashref
  my ($self, $metadata, $slice) = @_;
  $metadata ||= {};
  return unless $slice;

  ## Start and end need to be relative to slice,
  ## as that is how the API returns coordinates
  my $feature_start = $self->parser->get_start;
  my $feature_end   = $self->parser->get_end;

  ## Only set colour if we have something in metadata, otherwise
  ## we will override the default colour in the drawing code
  my $strand  = $self->parser->get_strand;
  my $score   = $self->parser->get_score;

  my $colour_params  = {
                        'metadata'  => $metadata,
                        'strand'    => $strand,
                        'score'     => $score,
                        };
  my $colour = $self->set_colour($colour_params);

  ## Try to find an ID for this feature
  my $attributes = $self->parser->get_attributes;
  my $id = $attributes->{'transcript_name'} || $attributes->{'transcript_id'} 
            || $attributes->{'gene_name'} || $attributes->{'gene_id'};

  ## Not a transcript, so just grab a likely attribute
  if (!$id) {
    while (my ($k, $v) = each (%$attributes)) {
      if ($k =~ /id$/i) {
        $id = $v;
        last;
      }
    }
  }

  return {
    'type'          => $self->parser->get_type,
    'start'         => $feature_start - $slice->start,
    'end'           => $feature_end - $slice->start,
    'seq_region'    => $self->parser->get_seqname,
    'strand'        => $strand,
    'score'         => $score,
    'colour'        => $colour, 
    'join_colour'   => $metadata->{'join_colour'} || $colour,
    'label_colour'  => $metadata->{'label_colour'} || $colour,
    'label'         => $id,
    %$attributes,
  };
}

1;
