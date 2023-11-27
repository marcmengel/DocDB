#
#        Name: TopicHTML.pm
# Description: Routines to produce snippets of HTML dealing with topics
#
#    Revision: $Revision$
#    Modified: $Author$ on $Date$
#
#      Author: Eric Vaandering (ewv@fnal.gov)

# Copyright 2001-2013 Eric Vaandering, Lynn Garren, Adam Bryant

#    This file is part of DocDB.

#    DocDB is free software; you can redistribute it and/or modify
#    it under the terms of version 2 of the GNU General Public License
#    as published by the Free Software Foundation.

#    DocDB is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with DocDB; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

use FindBin qw($RealBin);
use lib $RealBin;
require "DocDBGlobals.pm";
require "HTMLUtilities.pm";

sub TopicListByID {
  my ($ArgRef) = @_;
  my @TopicIDs    = exists $ArgRef->{-topicids}    ? @{$ArgRef->{-topicids}}   : ();
  my $ListFormat  = exists $ArgRef->{-listformat}  ?   $ArgRef->{-listformat}  : "dl";
  my $ListElement = exists $ArgRef->{-listelement} ?   $ArgRef->{-listelement} : "short";
  my $LinkType    = exists $ArgRef->{-linktype}    ?   $ArgRef->{-linktype}    : "document";
  my $SortBy      = exists $ArgRef->{-sortby}      ?   $ArgRef->{-sortby}      : ""; # name or provenance

  require "TopicSQL.pm";
  require "Sorts.pm";

  my $HTML = "";

  foreach my $TopicID (@TopicIDs) {
    FetchTopic({ -topicid => $TopicID });
  }

  if ($SortBy eq "name") {
    @TopicIDs = sort TopicByAlpha      @TopicIDs;
  } elsif ($SortBy eq "provenance") {
    @TopicIDs = sort TopicByProvenance @TopicIDs;
  }

  my @TopicLinks = ();
  foreach my $TopicID (@TopicIDs) {
    my $TopicLink = TopicLink( {-topicid => $TopicID, -format => $ListElement, -type => $LinkType,} );
    if ($TopicLink) {
      push @TopicLinks,$TopicLink;
    }
  }

# Headers for different styles and handle no topics

  if ($ListFormat eq "dl") {
    $HTML .= "<div id=\"Topics\">\n";
    $HTML .= "<dl>\n";
    $HTML .= "<dt class=\"InfoHeader\"><span class=\"InfoHeader\">Topics:</span></dt>\n";
    if (@TopicLinks) {
      $HTML .= "</dl>\n";
      $HTML .= "<ul>\n";
    } else {
      $HTML .= "<dd>None</dd>\n";
      $HTML .= "</dl>\n";
    }
  } elsif ($ListFormat eq "br") {
    unless (@TopicLinks) {
      $HTML .= "None<br/>\n";
    }
  }

  foreach my $TopicLink (@TopicLinks) {
    if ($ListFormat eq "dl") {
      $HTML .= "<li>$TopicLink</li>\n";
    } elsif ($ListFormat eq "br") {
      $HTML .= "$TopicLink<br/>\n";
    }
  }

# Footers for different styles

  if ($ListFormat eq "dl") {
    if (@TopicLinks) {
      $HTML .= "</ul>\n";
    }
    $HTML .= "</div>\n";
  }
  return $HTML;
}

sub TopicLink ($) {
  my ($ArgRef) = @_;
  my $TopicID = exists $ArgRef->{-topicid} ? $ArgRef->{-topicid} : "";
  my $Format  = exists $ArgRef->{-format}  ? $ArgRef->{-format}  : "short";
  my $Type    = exists $ArgRef->{-type}    ? $ArgRef->{-type}    : "document";
  my $OldDocs = exists $ArgRef->{-olddocs} ? $ArgRef->{-olddocs} : "";

  my $Separator = ":";

  require "TopicSQL.pm";
  my ($URL,$Text,$Tooltip,$Script,$Link);

  FetchTopic( {-topicid => $TopicID} );

  if ($Type eq "event") {
    $Script = $ListEventsBy;
  } else {
    $Script = $ListBy;
  }

  $URL     = $Script."?topicid=".$TopicID;
  if ($OldDocs) {
    $URL .= "&amp;old=1";
  }
  $Link = "";

  if ($Format eq "short") {
    $Text    = SmartHTML( {-text => $Topics{$TopicID}{Short}, } );
    $Tooltip = TopicName({-topicid => $TopicID, -format => "withparents",} );
  } elsif ($Format eq "long") {
    $Text    = SmartHTML( {-text => $Topics{$TopicID}{Long} , } );
    $Tooltip = SmartHTML( {-text => $Topics{$TopicID}{Short}, } );
  } elsif ($Format eq "withparents") {
    $Text    = SmartHTML( {-text => $Topics{$TopicID}{Short}, } );
    $Tooltip = SmartHTML( {-text => $Topics{$TopicID}{Long}, } );
    my @ParentTopicIDs = FetchTopicParents( {-topicid => $TopicID});
    if (@ParentTopicIDs) {
      my ($ParentTopicID) = @ParentTopicIDs;
      $Link .= TopicLink({-topicid => $ParentTopicID, -format => $Format,} );
      $Link .= $Separator;
    }
  }
  $Link .= "<a href=\"$URL\" title=\"$Tooltip\">$Text</a>";

  return $Link;
}

sub TopicName ($) {
  my ($ArgRef) = @_;
  my $TopicID = exists $ArgRef->{-topicid} ? $ArgRef->{-topicid} : "";
  my $Format  = exists $ArgRef->{-format}  ? $ArgRef->{-format}  : "withparents";
  my $Escape  = exists $ArgRef->{-escape}  ? $ArgRef->{-escape}  : $TRUE;

  my $Separator = ":";

  require "TopicSQL.pm";
  my ($Text);

  FetchTopic( {-topicid => $TopicID} );

  if ($Format eq "withparents") {
    my @ParentTopicIDs = FetchTopicParents( {-topicid => $TopicID});
    if (@ParentTopicIDs) {
      my ($ParentTopicID) = @ParentTopicIDs;
      $Text .= TopicName({-topicid => $ParentTopicID, -format => $Format,} );
      $Text .= $Separator;
    }
  }
# Merge conflict. Escape can probably just be removed everywhere since SmartHTML is smart
#  if ($Escape) {
#    $Text .= CGI::escapeHTML($Topics{$TopicID}{Short});
#  } else {
#    $Text .= $Topics{$TopicID}{Short};
#  }
  $Text .= SmartHTML( {-text => $Topics{$TopicID}{Short}, } );

  return $Text;
}

sub TopicsTable {
  require "Sorts.pm";
  require "TopicUtilities.pm";

  my ($ArgRef) = @_;
  my $Depth = exists $ArgRef->{-depth} ? $ArgRef->{-depth} : 1;

  my $NCols = $Preferences{Topics}{NColumns};

  my %Lists = ();
  my $TotalSize = 0;
  my @RootTopicIDs = sort TopicByAlpha AllRootTopics();
  foreach my $TopicID (@RootTopicIDs) {
    my @SubTopicIDs = TopicAndSubTopics({ -topicid => $TopicID, -maxdepth => $Depth, });
    push @DebugStack,"Topic $TopicID has ".$#SubTopicIDs." subtopics at depth $Depth";
    my $Size = $#SubTopicIDs + 1;
    $List{$TopicID}{Size} = $Size;
    $TotalSize += $Size;
  }
  foreach my $TopicID (@RootTopicIDs) {
    my $HTML = TopicListWithChildren({ -topicids => [$TopicID], -maxdepth => $Depth, -helplink => "",
                                       -checkevent => $TRUE,    -showcount => $TRUE, });
    $List{$TopicID}{HTML} = $HTML;
  }

  # This algorithm attempts to balance the length of columns in a multi-column
  # table. It sees if things "mostly" fit and recalculates the length of the
  # columns on the fly

  my $Target = $TotalSize/$NCols;
  push @DebugStack,"Initial target column length $Target";
  print '<table class="HighPaddedTable CenteredTable">'."<tr><td>\n";
  my $Col      = 1;
  my $NThisCol = 0;
  my $NSoFar   = 0;
  foreach my $TopicID (@RootTopicIDs) {
    my $Size = $List{$TopicID}{Size};

# Insert new cell if current chunk is to large and it's not
# the first thing in a column or the last column

    push @DebugStack,"Target: $Target So far: $NThisCol Testing: $Size";
    if ($NThisCol != 0 && $Col != $NCols && $NThisCol + 0.5*$Size >= $Target) {
      push @DebugStack,"Breaking column";
      $Target = ($TotalSize - $NSoFar)/($NCols-$Col);
      print "</td><td>\n";
      ++$Col;
      $NThisCol = 0;
    }

    $NThisCol += $Size;
    $NSoFar   += $Size;
    print $List{$TopicID}{HTML};
  }
  print "</td></tr></table>";
}

sub TopicListWithChildren { # Recursive routine
  my ($ArgRef) = @_;
  my @TopicIDs   = exists $ArgRef->{-topicids}   ? @{$ArgRef->{-topicids}}  : ();
  my $Depth      = exists $ArgRef->{-depth}      ?   $ArgRef->{-depth}      : 1;
  my $MaxDepth   = exists $ArgRef->{-maxdepth}   ?   $ArgRef->{-maxdepth}   : 0;
  my $CheckEvent = exists $ArgRef->{-checkevent} ?   $ArgRef->{-checkevent} : $FALSE; # name or provenance
  my $ShowCount  = exists $ArgRef->{-showcount}  ?   $ArgRef->{-showcount}  : $FALSE;
  my $Chooser    = exists $ArgRef->{-chooser}    ?   $ArgRef->{-chooser}    : $FALSE;
  my @DefaultTopicIDs = exists $ArgRef->{-defaulttopicids}   ? @{$ArgRef->{-defaulttopicids}}  : ();
  my $HelpLink   = exists $ArgRef->{-helplink}   ?   $ArgRef->{-helplink}   : "topics";
  my $HelpText   = exists $ArgRef->{-helptext}   ?   $ArgRef->{-helptext}   : "Topics";
  my $Required   = exists $ArgRef->{-required}   ?   $ArgRef->{-required}   : $TRUE;

  require "MeetingSQL.pm";
  require "MeetingHTML.pm";
  require "TopicSQL.pm";
  require "Utilities.pm";
  require "FormElements.pm";

  my @TopicIDs = sort TopicByAlpha @TopicIDs;

  my $HTML;
  my ($Class,$Strong,$EStrong);
  if (($Chooser && $Depth == 1) || ($MaxDepth && $Depth == 2)) {
    $Class = "mktree";
    unless ($MaxDepth) {
      $HTML .= FormElementTitle(-helplink  => $HelpLink, -helptext  => $HelpText ,
                                -required  => $Required,
                                -errormsg  => 'You must choose at least one topic.');
      $HTML .= '<input id="topic_dummy" class="hidden required" type="checkbox" value="dummy" name="topics" />'."\n";
    }
  } else {
    $Class = "$Depth-deep";
  }

  if (@TopicIDs) {
    if ($Depth > 1 || $Chooser) {
      $HTML .= "<ul class=\"$Class\" id=\"TopicTree\">\n";
    }
    foreach my $TopicID (@TopicIDs) {
      my $NodeClass = "";
      if ($Chooser) {
        my @ChildTopicIDs  = TopicAndSubTopics({-topicid => $TopicID, -includetopic => $FALSE});
        my @CommonTopicIDs = Union(\@DefaultTopicIDs,@ChildTopicIDs);
        if (@CommonTopicIDs) {
          $NodeClass = "liOpen";
        } else {
          $NodeClass = "liClosed";
        }
      } else {
        if ($MaxDepth && $Depth > $MaxDepth) {
            $NodeClass = "liClosed";
        } else {
            $NodeClass = "liOpen";
        }
      }

      if ($Depth > 1 || $Chooser) {
        $HTML .= "<li";
        if ($NodeClass) {
          $HTML .= " class=\"$NodeClass\"";
        }
        $HTML .= ">";
      } else {
        $HTML .= "<strong>";
      }
      if ($Chooser) {
        my $TopicName = TopicName( {-topicid => $TopicID, -format => "short", -escape => $FALSE} );
        my $Booleans = "";
        if ($Depth < $Preferences{Topics}{MinLevel}{Document}) {
          $TopicName = '['.$TopicName.']';
          $Booleans .= "-disabled";
        }
        if (defined IndexOf($TopicID,@DefaultTopicIDs)) {
          $HTML.= $query -> checkbox(-name => "topics", -value => $TopicID, -label => $TopicName, -checked => 'checked', $Booleans);
        } else {
          $HTML.= $query -> checkbox(-name => "topics", -value => $TopicID, -label => $TopicName, $Booleans);
        }
      } else {
        $HTML .= TopicLink( {-topicid => $TopicID} );
      }
      if ($ShowCount && $TopicCounts{$TopicID}{Exact}) {
        $HTML .= " ($TopicCounts{$TopicID}{Exact})";
      }
      if ($Depth == 1 && !$Chooser) {
        $HTML .= "</strong>\n";
      }
#      if ($CheckEvent) {
#        my %Hash = GetEventHashByTopic($TopicID);
#        if (%Hash) {
#          $HTML .= ListByEventLink({ -topicid => $TopicID });
#        }
#      }
      if (@{$TopicChildren{$TopicID}}) {
        $HTML .= "\n";
        $HTML .= TopicListWithChildren({ -topicids => $TopicChildren{$TopicID}, -depth => $Depth+1,
                                         -maxdepth => $MaxDepth, -showcount => $ShowCount,
                                         -chooser  => $Chooser, -defaulttopicids => \@DefaultTopicIDs});
      } elsif ($Depth == 1 && !$Chooser) {
        $HTML .= '<br class="EmptyTopic" />';
      }
      if ($Depth > 1 || $Chooser) {
        $HTML .= "</li>\n";
      }
    }
    if ($Depth > 1 || $Chooser) {
      $HTML .= "</ul>\n";
    }
  }

  return $HTML;
}

sub ShortDescriptionBox  (;%) {
  my (%Params) = @_;

  my $HelpLink  =   $Params{-helplink}  || "shortdescription";
  my $HelpText  =   $Params{-helptext}  || "Short Description";
  my $ExtraText =   $Params{-extratext} || "";                 # Not used
  my $Required  =   $Params{-required}  || 0;
  my $Name      =   $Params{-name}      || "short";
  my $Size      =   $Params{-size}      || 20;
  my $MaxLength =   $Params{-maxlength} || 40;
  my $Disabled  =   $Params{-disabled}  || $FALSE;
  my $Default   =   $Params{-default}   || "";

  print "<div class=\"ShortDescriptionEntry\">\n";
  TextField(-name     => $Name,     -helptext  => $HelpText,
            -helplink => $HelpLink, -required  => $Required,
            -size     => $Size,     -maxlength => $MaxLength,
            -default  => $Default,  -disabled  => $Disabled);
  print "</div>\n";
}

sub LongDescriptionBox (;%) {
  my (%Params) = @_;

  my $HelpLink  =   $Params{-helplink}  || "longdescription";
  my $HelpText  =   $Params{-helptext}  || "Long Description";
  my $ExtraText =   $Params{-extratext} || "";                 # Not used
  my $Required  =   $Params{-required}  || 0;
  my $Name      =   $Params{-name}      || "long";
  my $Size      =   $Params{-size}      || 40;
  my $MaxLength =   $Params{-maxlength} || 120;
  my $Disabled  =   $Params{-disabled}  || $FALSE;
  my $Default   =   $Params{-default}   || "";

  print "<div class=\"LongDescriptionEntry\">\n";
  TextField(-name     => $Name,     -helptext  => $HelpText,
            -helplink => $HelpLink, -required  => $Required,
            -size     => $Size,     -maxlength => $MaxLength,
            -default  => $Default,  -disabled  => $Disabled);
  print "</div>\n";
};

sub TopicScrollTable ($) {
  my ($ArgRef) = @_;

  my $NCols      = exists $ArgRef->{-ncols}      ?   $ArgRef->{-ncols}      : 4;
  my $MinLevel   = exists $ArgRef->{-minlevel}   ?   $ArgRef->{-minlevel}   : 1;
  my $HelpLink   = exists $ArgRef->{-helplink}   ?   $ArgRef->{-helplink}   : "topics";
  my $HelpText   = exists $ArgRef->{-helptext}   ?   $ArgRef->{-helptext}   : "Topics";
  my $Required   = exists $ArgRef->{-required}   ?   $ArgRef->{-required}   : 0;
  my @Defaults   = exists $ArgRef->{-default}    ? @{$ArgRef->{-default}}   : ();

  require "TopicSQL.pm";
  require "TopicUtilities.pm";
  require "FormElements.pm";

  print "<table class=\"MedPaddedTable\">\n";

  print "<tr><th colspan=\"$NCols\">\n";
  print FormElementTitle(-helplink  => $HelpLink, -helptext  => $HelpText ,
                         -required  => $Required);
  print "</th>"; # </tr> by table routine
#  print '<input id="topic_dummy" class="hidden required" type="checkbox" value="dummy" name="topics" />'."\n";

  my @RootTopicIDs = sort TopicByAlpha AllRootTopics();

  my $Col = 0;
  foreach my $TopicID (@RootTopicIDs) {
    my @TopicIDs = TopicAndSubTopics({ -topicid => $TopicID });
    unless ($Col % $NCols) {
      print "</tr><tr>\n";
    }
    print "<td>\n";
    print "<strong>$Topics{$TopicID}{Short}</strong><br/>\n";
    my $ColReq = $FALSE;
    if ($Required && $Col==0) {
      $ColReq = $TRUE;
    }

    TopicScroll({ -itemformat => "short",    -multiple => $TRUE, -helplink => "",
                  -default    => \@Defaults, -topicids => \@TopicIDs,
                  -minlevel   => $MinLevel, });
    print "</td>\n";
    ++$Col;
  }
  print "</tr></table>\n";
}


sub TopicScroll ($) {
  my ($ArgRef) = @_;
  my $ItemFormat = exists $ArgRef->{-itemformat} ?   $ArgRef->{-itemformat} : "long";
  my $MinLevel   = exists $ArgRef->{-minlevel}   ?   $ArgRef->{-minlevel}   : 1;
  my $Multiple   = exists $ArgRef->{-multiple}   ?   $ArgRef->{-multiple}   : 0;
  my $HelpLink   = exists $ArgRef->{-helplink}   ?   $ArgRef->{-helplink}   : "topics";
  my $HelpText   = exists $ArgRef->{-helptext}   ?   $ArgRef->{-helptext}   : "Topics";
  my $ExtraText  = exists $ArgRef->{-extratext}  ?   $ArgRef->{-extratext}  : "";
  my $Required   = exists $ArgRef->{-required}   ?   $ArgRef->{-required}   : 0;
  my $Name       = exists $ArgRef->{-name}       ?   $ArgRef->{-name}       : "topics";
  my $Size       = exists $ArgRef->{-size}       ?   $ArgRef->{-size}       : 10;
  my $Disabled   = exists $ArgRef->{-disabled}   ?   $ArgRef->{-disabled}   : "0";
  my @Defaults   = exists $ArgRef->{-default}    ? @{$ArgRef->{-default}}   : ();
  my @TopicIDs   = exists $ArgRef->{-topicids}   ? @{$ArgRef->{-topicids}}  : ();
  my %Options = ();

  if ($Disabled) {
    $Options{-disabled} = "disabled";
  }

  if ($Required) {
    $Options{'-class'} = "required";
  }

  require "TopicSQL.pm";
  require "TopicUtilities.pm";
  require "FormElements.pm";

  GetTopics();
  unless (@TopicIDs) {
    @TopicIDs = keys %Topics;
  }
  @TopicIDs = sort TopicByProvenance @TopicIDs;

  my %TopicLabels = ();
#  my @ActiveIDs = @TopicIDs; # Later can select single root topics, etc.

  foreach my $ID (@TopicIDs) {
    my $SafeShort = SmartHTML({-text=>$Topics{$ID}{Short}});
    my $SafeLong = SmartHTML({-text=>$Topics{$ID}{Long}});
    my $Spaces = '-'x(1*(scalar(@{$TopicProvenance{$ID}})-1));
    if ($ItemFormat eq "short") {
      $TopicLabels{$ID} = $Spaces.$SafeShort;
    } elsif ($ItemFormat eq "long") {
      $TopicLabels{$ID} = $Spaces.$SafeLong;
    } elsif ($ItemFormat eq "full") {
      $TopicLabels{$ID} = $Spaces.$SafeShort." [".$SafeLong."]";
    }

    if (($ItemFormat eq "short" or $ItemFormat eq "long") &&
         scalar(@{$TopicProvenance{$ID}}) < $MinLevel) {
      $TopicLabels{$ID} = "[".$TopicLabels{$ID}."]";
    }
  }

  print FormElementTitle(-helplink  => $HelpLink, -helptext  => $HelpText ,
                         -text      => $Text    , -extratext => $ExtraText,
                         -required  => $Required, -errormsg  => 'You must choose at least one topic.');

  print $query -> scrolling_list(-name     => $Name, -values => \@TopicIDs,
                                 -size     => $Size, -labels => \%TopicLabels,
                                 -multiple => $Multiple,
                                 -default  => \@Defaults, %Options);
}

1;
