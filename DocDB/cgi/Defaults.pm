#  Module Purpose:
#    Gather in one place all the routines that set the look and feel
#    of DocumentAddForm based on user selections, preferences, and defaults
#    (in that order)
#
#  Functions in this file:
#    
#    SetAuthorMode:    Selectable list or free-form text field
#    SetTopicMode:     Single or multiple selectable lists 
#    SetUploadMethod:  File upload or HTTP fetch
#    SetDateOverride:  Allows over-riding modification date  
#    SetAuthorDefault: Sets Author and Requester defaults to cookie value
#    SetFileOptions:   Sets archive mode and number of uploads

sub SetAuthorMode {
  if ($params{authormode}) {
    $AuthorMode = $params{authormode};
  } else {
    $AuthorMode = $AuthorModePref;
  }    
  if ($AuthorMode ne "list" && $AuthorMode ne "field") {
    $AuthorMode = "list";
  }
}

sub SetTopicMode {
  if ($params{topicmode}) {
    $TopicMode = $params{topicmode};
  } else {
    $TopicMode = $TopicModePref;
  }
  if ($TopicMode ne "single" && $TopicMode ne "multi") {
    $TopicMode = "multi";
  }  
}

sub SetUploadMethod {
  if ($params{upload}) {
    $Upload = $params{upload};
  } else {
    $Upload = $UploadMethodPref;
  }  
  if ($Upload ne "http" && $Upload ne "file") {
    $Upload = "file";
  }  
}

sub SetDateOverride {
  if ($params{overdate}) {
    $Overdate = $params{overdate};
  } else {
    $Overdate = $DateOverridePref;
  }  
}

sub SetAuthorDefault {
  if ($UserIDPref) {
    @AuthorDefaults = ($UserIDPref); #FIXME: Doesn't work for text field, ref thing
    $RequesterDefault = ($UserIDPref);
  }
}

sub SetFileOptions {
  my ($DocRevID) = @_;

  if ($params{archive}) {
    $Archive = $params{archive};
  } else {
    $Archive = $UploadTypePref
  }  

  if ($Archive eq "single") {$NumberUploads = 1;}  # Make sure
  if ($Archive eq "multi")  {$Archive = "single";} # No real difference
  if ($Archive ne "archive" && $Archive ne "single") {
    $Archive = "single";
  }  
  
  if ($params{numfile}) {               # User has selected
    $NumberUploads = $params{numfile};
  } elsif ($NumFilesPref && $mode ne "update") {             # User has a pref
    if ($Meeting  || $OtherMeeting) {
      if ($NumFilesPref < 3) {
        $NumberUploads = 3;
      } else {   
        $NumberUploads = $NumFilesPref;
      }  
    } else {  
      $NumberUploads = $NumFilesPref;
    }   
  } else {                              # No selection, no pref
    if ($Meeting  || $OtherMeeting) {
      $NumberUploads = 3;
    } elsif ($mode eq "update") {
      my @DocFiles = @{&FetchDocFiles($DocRevID)};
      $NumberUploads = @DocFiles;
      unless ($NumberUploads) { # Gyrations to handle docs that have 0 files
        $NumberUploads = 1;
      }  
    } else {
      $NumberUploads = 1;
    }  
  }
}


1;