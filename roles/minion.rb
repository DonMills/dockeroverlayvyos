name "minion"
description "The role for docker minions"
run_list 'recipe[etcd2]', 'recipe[docker]'
