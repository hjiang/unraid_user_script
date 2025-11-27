.PHONY: deploy

HOST := root@192.168.1.10

deploy:
	rsync -rltzv --exclude=.keep config/ ${HOST}:/boot/config/
	rsync -rltzv scripts/ ${HOST}:/boot/config/plugins/user.scripts/scripts/
