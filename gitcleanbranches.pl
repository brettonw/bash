#! /usr/bin/env perl

use Cwd;
use JSON;
use File::Basename;
use Path::Tiny;

# set the git command
my $git = "git --no-pager";

# prune the cache of remote branches
print STDERR "Refreshing remote branch cache...\n";
system ("$git fetch -p origin");

sub conditionBranchName {
    my ($input) = @_;
    $input =~ s/^[\s\*]+//;
    $input =~ s/\s+$//;
    $input =~ s/^.*origin\///;
    return $input;
}

my $allowedPrefixes = {
    "hotfix" => 1,
    "feature" => 1,
    "release" => 1,
    "bugfix" => 1
};

sub isCompliantName {
    my ($branchName, $report) = @_;
    # check that the branch name starts with one of the approved prefixes
    my @splitName = split(/\//, $branchName, 2);
    return ($#splitName == 1) && (exists $allowedPrefixes->{$splitName[0]});
}

my $reservedBranchNames = {
    "test" => 1,
    "release" => 1,
    "development" => 1,
    "develop" => 1,
    "master" => 1,
    "main" => 1,
    "integration" => 1
};

sub buildBranchNameDictionary {
    my ($commandLine, $report) = @_;
    my @branchNames = `$commandLine`;
    chomp @branchNames;
    my $branchNameDictionary ={};
    for my $branchName (@branchNames) {
        $branchName = conditionBranchName ($branchName);
        if (exists $reservedBranchNames->{$branchName}) {
            if (defined $report) {
                #print STDERR "[$report] RESERVED: $branchName\n";
            }
        } elsif (isCompliantName ($branchName)) {
            if (defined $report) {
                #print STDERR "[$report] Branch: $branchName\n";
            }
            $branchNameDictionary->{$branchName} = $branchName;
        } else {
            if (defined $report) {
                print STDERR "[$report] Non-compliant: $branchName\n";
            }
        }
    }
    return $branchNameDictionary;
}

sub yesNo {
    my ($prompt) = @_;
    print STDERR "$prompt? (y or N) ";
    my $yesNo = lc (<STDIN>);
    chomp $yesNo;
    return ($yesNo eq "y");
}

# get the default branch
my $headBranches = `$git branch --remote --list '*/HEAD'`;
chomp($headBranches);
my $defaultBranch = (split(/\//, $headBranches))[-1];

# get the branch statuses
my $mergedRemoteBranchesDictionary = buildBranchNameDictionary ("$git branch --remote --merged $defaultBranch", "MERGED REMOTE");
my $mergedLocalBranchesDictionary = buildBranchNameDictionary ("$git branch --merged $defaultBranch", "MERGED LOCAL");
my $allRemoteBranchesDictionary = buildBranchNameDictionary ("$git branch --remote --list");
my $allLocalBranchesDictionary = buildBranchNameDictionary ("$git branch --list", "ALL LOCAL");

my $users = { "bretton wade" => "Bretton Wade" };
sub findUserMap {
    my ($dir) = @_;
    # ensure trailing slash
    if ($dir !~ /\/$/) {
        $dir = "$dir/";
    }

    # check for the usermap file
    my $userMapFile = path("$dir/usermap.json");
    if ($userMapFile->is_file) {
        #return $userMapFileName
        print STDERR "Reading users from: $userMapFile\n";
        my $userMapFileContents = $userMapFile->slurp_utf8;
        $users = decode_json($userMapFileContents);
    } else {
        $dir =~ s/[^\/]+\/$//;
        if ($dir ne "/") {
            findUserMap ($dir)
        }
    }
}
findUserMap(cwd());

# condition the users list - the encountered user names are the keys, and their canonical names
# is used to join together all branches by unique person, even if they have multiple user names
for my $user (keys %$users) {
    my $canonicalName = $users->{$user};
    if ($canonicalName !~ /,/) {
        my ($fname, $lname) = split (/ /, $canonicalName, 2);
        $users->{$user} = "$lname, $fname";
        #print STDERR "($user) -> ($lname, $fname)\n";
    }
}

# get the creator/owner of all the branches, sort them into a dictionary by user
my $byUser = {};
my $compliantByUser = {};
my $totalUserBranches = 0;
my @branchOwners = `$git for-each-ref --format='%(authorname);%(refname)'`;
chomp @branchOwners;
for my $branchOwner (@branchOwners) {
    my ($branchOwnerName, $branchName) = split (/;/, $branchOwner, 2);
    $branchName = conditionBranchName ($branchName);
    if (exists $mergedRemoteBranchesDictionary->{$branchName}) {
        $branchOwnerName = lc ($branchOwnerName);

        my $user;
        if (exists $users->{$branchOwnerName}) {
            $user = $users->{$branchOwnerName}
        } else {
            $user = $branchOwnerName;
            print "UNKNOWN USER ($branchOwnerName)\n";
        }
        $mergedRemoteBranchesDictionary->{$branchName} = $user;
        if (! exists $byUser->{$user}) {
            $byUser->{$user} = [];
        }
        my $userBranchList = $byUser->{$user};
        push (@$userBranchList, $branchName);
        $totalUserBranches++;

        if (isCompliantName ($branchName, $user)) {
            $compliantByUser->{$user}++;
        }
    }
}

# loop over all local branches
my $removedBranches = {};
for my $localBranch (keys %$allLocalBranchesDictionary) {
    print STDERR "Local branch: $localBranch";
    # check to see if this local branch has a remote backing
    if (exists $allRemoteBranchesDictionary->{$localBranch}) {
        print STDERR " (REMOTE)";
        # it does, let's check to see if it is merged
        if (exists $mergedRemoteBranchesDictionary->{$localBranch}) {
            print STDERR " (MERGED)";
            # it is, this should be removed, locally *and* remotely
            system ("$git push --delete origin $localBranch && sleep 5 && $git branch -D $localBranch");
            print STDERR " (REMOVED)";
            $removedBranches->{$localBranch} = $localBranch;
        } else {
            # it is not merged, this is an active branch
            print STDERR " (ACTIVE)";
        }
        print STDERR "\n";
    } else {
        # there is no remove backing, do we want to delete this?
        print STDERR " (LOCAL ONLY)\n";
        if (yesNo ("Remove branch with no remote backing")) {
            system ("$git branch -d $localBranch");
            $removedBranches->{$localBranch} = $localBranch;
        }
    }
}
print STDERR "\n";

# print some stats
print STDERR " COUNT   COMPLIANT   USER\n------- ----------- ------------\n";
for my $user (sort keys %$byUser) {
    my $userBranchList = $byUser->{$user};
    print STDERR sprintf (" % 5d   % 9d   %s\n", scalar (@$userBranchList), $compliantByUser->{$user}, $user);
}
print STDERR sprintf ("------- ----------- ------------\n% 5d\n\n", $totalUserBranches, $totalNonCompliantBranches);

# ask the user if they want to check remote branches
if (yesNo ("Check all remote branches")) {
    # loop over the users
    for my $user (sort keys %$byUser) {
        my $userBranchList = $byUser->{$user};
        if (yesNo ("$user (" . scalar(@$userBranchList) . ") MERGED branches, continue")) {
            for my $userBranch (@$userBranchList) {
                if (yesNo ("    Delete $userBranch (MERGED)")) {
                    system ("$git push --delete origin $userBranch");
                    $removedBranches->{$userBranch} = $userBranch;
                }
            }
        }
    }
}
