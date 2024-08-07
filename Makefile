#Makefile

set_vars:
	ansible-playbook ansible/playbook.yml -i ansible/inventory.ini -t tf_vars --ask-vault-pass -vvv

init:
	ansible-playbook ansible/playbook.yml -i ansible/inventory.ini -t tf_init

setup:
	ansible-playbook ansible/playbook.yml -i ansible/inventory.ini -t setup

deploy:
	ansible-playbook ansible/playbook.yml -i ansible/inventory.ini -t deploy

destroy:
	ansible-playbook ansible/playbook.yml -i ansible/inventory.ini -t remove


#encrypt:
#	ansible-vault encrypt group_vars/webservers/vault.yml
#
#decrypt:
#	ansible-vault decrypt group_vars/webservers/vault.yml
#
#edit:
#	ansible-vault edit group_vars/webservers/vault.yml
#
#secure-deploy:
#	ansible-playbook -i inventory.ini deploy.yml --ask-vault-pass
#
install:
	ansible-galaxy install -r ansible/requirements.yml