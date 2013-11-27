package AssignGroup::Plugin;
use MT;
use MT::Group;
use strict;
use MT::Association;

sub author_post_save {
	my ($cb, $author) = @_;
	
	my $plugin = MT->component("AssignGroup");
	my $groupname = $plugin->get_config_value('group','system');
	my $logging = $plugin->get_config_value('logging','system');
	my $defaultgroupnames = $plugin->get_config_value('defaultgroups','system');
	my @fields = split(/,\s*/, $plugin->get_config_value('fields','system'));
	
	if ($groupname){
		my $group = MT::Group->load({'name' => $groupname});
		
		my $addtogroup = 1;
		
		foreach my $field (@fields){
			unless ($author->meta('field.'.$field)){$addtogroup=0} 
		}
		
		if ($addtogroup){
			$group->add_user($author);
		}
		else{
			$group->remove_user($author);
		}
	}
	
	if ($defaultgroupnames){		
		my @defaultgroups = split(/,\s*/, $defaultgroupnames);
		foreach my $defaultgroupname (@defaultgroups){
			my $defaultgroup = MT::Group->load({'name' => $defaultgroupname});
			if ($defaultgroup){
				$defaultgroup->add_user($author);
				if ($logging){
					MT->log("Default group ".$defaultgroupname." added user ".$author->nickname." to it");
				}
			}
			else {
				if ($logging){
					MT->log("Default group ".$defaultgroupname." not found while trying to add user ".$author->nickname." to it");
				}
			}
		}
	}
	
	#    my $perm = MT::Permission->load($author->id);
	#    $perm->rebuild();
}

sub add_to_default_groups {
	(my $second, my $minute, my $hour, my $dayOfMonth, my $month, my $yearOffset, my $dayOfWeek, my $dayOfYear, my $daylightSavings) = localtime();
	my $plugin = MT->component("AssignGroup");
	my $defaultgroupnames = $plugin->get_config_value('defaultgroups','system');
	my $logging = $plugin->get_config_value('logging','system');
	my @defaultgroups;
	my $defaultgroupname;
	
	if ($defaultgroupnames){		
		my @defaultgroupnames = split(/,\s*/, $defaultgroupnames);
		foreach $defaultgroupname (@defaultgroupnames){
			my $defaultgroup = MT::Group->load({'name' => $defaultgroupname});
			push @defaultgroups, $defaultgroup;
		}
	}
	
	my $iter = MT::Author->load_iter();
	while (my $author = $iter->()) {
		foreach my $group (@defaultgroups){
			my $association = MT::Association->load({group_id => $group->id, author_id => $author->id});
			if ($association){
				if ($logging){
					MT->log("Group ".$group->name." already has user ".$author->nickname." in it");
				}
				next;
			}
			$group->add_user($author);
			if ($logging){
				MT->log("Default group ".$group->name." added user ".$author->nickname." to it");
			}
		}
	}	
	
}

1; # Every module must return true

