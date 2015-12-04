name "etcdmaster"
description "The role for the etcd kv store master"
run_list 'recipe[etcd2]','recipe[docker]'
default_attributes "etcd" => { "deffile" => "etcddef.master"}
