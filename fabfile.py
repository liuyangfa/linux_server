from fabric.api import *

env.user='root'
env.password='ipanel123'


def startUwsgi():
	with cd("/r2/maintain_scripts/ops/sbin"):
		run("sh uwsgi.sh start")
		
def stopUwsgi():
	with cd("/r2/maintain_scripts/ops/sbin"):
		run("sh uwsgi.sh stop")

def statusUwsgi():
	with cd("/r2/maintain_scripts/ops/sbin"):
		run("sh uwsgi.sh status")

def restartUwsgi():	
	execute(stopUwsgi)
	execute(startUwsgi)

def startKafka():
	with cd("/usr/local/operations/kafka/bin"):
		run("sh start.sh")


def stopKafka():
	with cd("/usr/local/operations/kafka/bin"):
		run("sh stop.sh")


def restartKafka():
	execute(stopUwsgi)
	execute(stUwsgi)

def startRabbit():
	with cd("/usr/local/operations/rabbitmq/sbin"):
		run("./rabbitmq-server -detached")
	
def stopRabbit():
	with cd("/usr/local/operations/rabbitmq/sbin"):
		run("./rabbitmqctl stop")

def restartRabbit():
	execute(stopRabbit)
	execute(startRabbit)
	
def startMySQL():
	run("systemctl start mysql")
	
def stopMySQL():
	run("systemctl stop mysql")

def restartMySQL():
	run("systemct restart mysql")

def reloadOpenresty():
    run("/usr/local/openresty/nginx/sbin/nginx -s reload")

def startOpenresty():
    run("/usr/local/openresty/nginx/sbin/nginx")

def stopOpenresty():
    run("/usr/local/openresty/nginx/sbin/nginx -s stop")
	
def restartOpenresty():
    execute(stopOpenresty)
    execute(startOpenresty)

def startServer():
	with cd("/r2/maintain_scripts/ops/elves/server/"):
		run("./run.sh start")

def stopServer():
	with cd("/r2/maintain_scripts/ops/elves/server/"):
		run("./run.sh stop")
		
def restartServer():
	with cd("/r2/maintain_scripts/ops/elves/server/"):
		run("./run.sh restart")
	
def statusServer():
	with cd("/r2/maintain_scripts/ops/elves/server/"):
		run("./run.sh status")

	
	