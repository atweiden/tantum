use v6;
use Nightscape::Journal::Group;
class Nightscape::Journal::Groups;

our @groups;

method group_exists($group_name) returns Bool {
    if @groups».name ~~ / $group_name / {
        return True;
    } else {
        return False;
    }
}

method add($group_name) {
    push @groups, Nightscape::Journal::Group.new(name => $group_name)
    unless Nightscape::Journal::Groups.group_exists($group_name);
}

method update(:$group_name! where Nightscape::Journal::Groups.group_exists($group_name),
              :$group_pos!, :$id!) {
    my $target_group_obj = @groups.grep({ .name ~~ / $group_name / })[0];
    $target_group_obj.members[$group_pos] = $id;
}

# vim: ft=perl6
