sub GetSecurityGroups { # Creates/fills a hash $SecurityGroups{$GroupID}{} with all authors
  my ($GroupID,$Name,$Description,$Timestamp);
  my $group_list  = $dbh -> prepare(
     "select GroupID,Name,Description,Timestamp from SecurityGroup"); 
  $group_list -> execute;
  $group_list -> bind_columns(undef, \($GroupID,$Name,$Description,$Timestamp));
  %SecurityGroups = ();
  while ($group_list -> fetch) {
    $SecurityGroups{$GroupID}{GROUPID}     = $GroupID;
    $SecurityGroups{$GroupID}{NAME}        = $Name;
    $SecurityGroups{$GroupID}{DESCRIPTION} = $Description;
    $SecurityGroups{$GroupID}{TIMESTAMP}   = $Timestamp;
  }
  
  my ($HierarchyID,$ChildID,$ParentID);
  my $hierarchy_list  = $dbh -> prepare(
     "select HierarchyID,ChildID,ParentID,Timestamp from GroupHierarchy"); 
  $hierarchy_list -> execute;
  $hierarchy_list -> bind_columns(undef, \($HierarchyID,$ChildID,$ParentID,$Timestamp));
  %GroupsHierarchy = ();
  while ($hierarchy_list -> fetch) {
    $GroupsHierarchy{$HierarchyID}{HIERARCHY} = $HierarchyID;
    $GroupsHierarchy{$HierarchyID}{CHILD}     = $ChildID;
    $GroupsHierarchy{$HierarchyID}{PARENT}    = $ParentID;
    $GroupsHierarchy{$HierarchyID}{TIMESTAMP} = $Timestamp;
  }
}

sub ObsFetchSecurityGroup { # FIXME remove entire routine. Not used
  my ($groupID) = @_;
  my ($GroupID,$Name,$Description,$Timestamp);

  my $security_fetch  = $dbh -> prepare(
     "select GroupID,Name,Description,Timestamp ". 
     "from SecurityGroup ". 
     "where GroupID=?");
  if ($SecurityGroups{$groupID}{GROUPID}) { # We already have this one
    return $SecurityGroups{$groupID}{GROUPID};
  }
  
  $security_fetch -> execute($groupID);
  ($GroupID,$Name,$Description,$Timestamp) = $security_fetch -> fetchrow_array;
  $SecurityGroups{$GroupID}{GROUPID}     = $GroupID;
  $SecurityGroups{$GroupID}{NAME}        = $Name;
  $SecurityGroups{$GroupID}{DESCRIPTION} = $Description;
  $SecurityGroups{$GroupID}{TIMESTAMP}   = $Timestamp;
  
  return $SecurityGroups{$GroupID}{GROUPID};
}

sub GetRevisionSecurityGroups {
  my ($DocRevID) = @_;
  my @groups = ();
  my ($RevTopicID,$GroupID);
  my $group_list = $dbh->prepare(
    "select RevSecurityID,GroupID from RevisionSecurity where DocRevID=?");
  $group_list -> execute($DocRevID);
  $group_list -> bind_columns(undef, \($RevTopicID,$GroupID));
  while ($group_list -> fetch) {
    push @groups,$GroupID;
  }
  return \@groups;
}


1;