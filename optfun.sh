#!/bin/bash

apath="/r2/maintain_scripts/ops/source"
elvesDir="/r2/maintain_scripts/ops"

function installReModule()
{
	local package=$1
	if [[ "${package}" =~ .zip$ ]];then
		echo "$(date +'%Y-%m-%d %H:%M:%S') 开始解压..."
		unzip -q ${package} -d . && echo "$(date +'%Y-%m-%d %H:%M:%S') ${package}解压成功.$(echo_success)" || echo "$(date +'%Y-%m-%d %H:%M:%S') ${package}解压失败.$(echo_failure)"
		cd ${package%.*} && python setup.py install &> /dev/null
		if [ "$?" = "0" ];then
			cd -
			echo "$(date +'%Y-%m-%d %H:%M:%S') ${package%-*}安装成功"
			rm -rf ${package%.*}
		fi
	elif [[ "${package}" =~ .tar.gz$ ]];then
		echo "$(date +'%Y-%m-%d %H:%M:%S') 开始解压..."
		tar xf ${package} && echo "$(date +'%Y-%m-%d %H:%M:%S') ${package}解压成功.$(echo_success)" || echo "$(date +'%Y-%m-%d %H:%M:%S') ${package}解压失败.$(echo_failure)"
		cd ${package%.*.*} && python setup.py install &> /dev/null
		if [ "$?" = "0" ];then
			cd -
			echo "$(date +'%Y-%m-%d %H:%M:%S') ${package%-*}安装成功"
			rm -rf ${package%.*.*}
		fi
	fi

}

function installBasicModule()
{
	local pypi="pypiserver-1.2.1.zip"
	local setuptools="setuptools-38.2.4.zip"
	local pip="pip-9.0.3.tar.gz"
	local sgit="setuptools-git-1.2.tar.gz"
	
	if [ -d "${setuptools%.*}" ] || [ -d "${pypi%.*}" ] || [ -d "${pip%.*.*}" ];then
		rm -rf ${setuptools%.*}
		rm -rf ${pypi%.*}
		rm -rf ${pip%.*.*}
	fi
	for pkgs in ${setuptools} ${sgit} ${pip} ${pypi}
	do
		if [[ -e "${pkgs}" ]];then
			installReModule ${pkgs}
 		fi
	done
}

function startPypiServer()
{
	
	netstat -antlp | grep tcp.*:60000.*LISTEN &> /dev/null
	if [ $? = "0" ];then
		echo "$(date +'%Y-%m-%d %H:%M:%S') 60000端口已经被占用，请修改后重新运行."
	else
		echo "$(date +'%Y-%m-%d %H:%M:%S') ${PWD}"
		pypi-server -p 60000 . &
		if [ $(ps -ef | egrep -v grep | grep pypi | wc -l) -gt 0 ];then
			echo "$(date +'%Y-%m-%d %H:%M:%S') pypi启动成功...$(echo_success)"
		else
			echo "$(date +'%Y-%m-%d %H:%M:%S') pypi启动失败.$(echo_failure)"
			exit 1
		fi
	fi
}

function stopPypiServer()
{
	pid=$(netstat -atnlp | egrep "tcp.*:60000.*LISTEN" | awk '{print $7}' | cut -d'/' -f1)
	if [ "${pid}" != "" ];then
		kill -9 $pid &> /dev/null
		if [ $(netstat -atnlp | egrep "tcp.*:60000.*LISTEN") ];then
			echo "$(date +'%Y-%m-%d %H:%M:%S') pypi进程没有杀死."
		else
			echo "$(date +'%Y-%m-%d %H:%M:%S') pypi进程已经杀死."
		fi
	fi
}

function installRequire()
{
	startPypiServer
	pip install --extra-index-url http://127.0.0.1:60000 -r requirements.txt
	stopPypiServer
}

function installOtherModule()
{
	local otherModule="django uwsgi djangorestframework"
	
	startPypiServer
	for pkg in ${otherModule}
	do
		pn=$(echo "${pkg%%-*}" | tr 'A-Z' 'a-z')
		pip install --extra-index-url http://127.0.0.1:60000 ${pn} &> /dev/null
		tmp=$(pip freeze | awk -F'=' '{print $1}' | grep -iE "^${pn}$" | tr 'A-Z' 'a-z')
		if [[ ${tmp} =~ ^${pn}$ ]];then
			echo "$(date +'%Y-%m-%d %H:%M:%S') ${pn}安装成功.$(echo_success)"
		else
			echo "$(date +'%Y-%m-%d %H:%M:%S') ${pn}安装失败.$(echo_failure)"
			if [[ ${pkg} =~ ^uwsgi ]];then
				echo "$(date +'%Y-%m-%d %H:%M:%S') 必须先安装gcc\gcc-c++\python-devel等C编译的相关工具或者库."
			fi
			stopPypiServer
			exit 1
		fi
	done
	stopPypiServer
}

function installMySQLdb()
{
	if [ $(rpm -qa | grep MySQL-python | wc -l) = "1" ];then
		echo "$(date +'%Y-%m-%d %H:%M:%S') MySQL-python已经安装了."
	else
		yum install MySQL-python -y &> /dev/null
		if [ $? = "0" ];then
			echo "$(date +'%Y-%m-%d %H:%M:%S') MySQL-python安装成功.$(echo_success)"
		else
			echo "$(date +'%Y-%m-%d %H:%M:%S') MySQL-python安装失败.$(echo_failure)"
			exit 1
		fi
	fi
}

function installDepackge()
{
	local package="gcc gcc-c++ python-devel MySQL-python gdb"
	local wheel="python-wheel-0.24.0-2.el7.noarch.rpm"

	for pkg in ${package}
	do
		yum install ${pkg} -y &> /dev/null
		if [ $? = "0" ];then
			echo "$(date +'%Y-%m-%d %H:%M:%S') ${pkg}安装成功.$(echo_success)"
		else
			echo "$(date +'%Y-%m-%d %H:%M:%S') ${pkg}安装失败.$(echo_success)"
			exit
		fi
	done
	
	if [ -e ${wheel} ] && [ $(rpm -qa | grep python-wheel | wc -l) = "0" ];then
		rpm -ivh ${wheel}
	else
		echo "$(date +'%Y-%m-%d %H:%M:%S') $(rpm -qa | grep python-wheel)"
	fi
}

function createVirenv()
{
	if [ ! -d "env" ];then
		LANG=C virtualenv --no-site-packages --no-setuptools --no-pip env
		source env/bin/activate && echo "$(date +'%Y-%m-%d %H:%M:%S') 虚拟环境已激活.$(echo_success)"
		installDepackge
		installBasicModule
		installOtherModule
		deactivate
	else
		source env/bin/activate && echo "$(date +'%Y-%m-%d %H:%M:%S') 虚拟环境已激活.$(echo_success)"
		installDepackge
		installBasicModule
		installOtherModule
		deactivate
	fi
}

function insVirenv()
{
	local virenv="virtualenv-15.2.0.tar.gz"
	echo "$(date +'%Y-%m-%d %H:%M:%S') 开始解压${virenv}..."
	tar xf ${virenv} && echo "$(date +'%Y-%m-%d %H:%M:%S') ${virenv}解压成功.$(echo_success)" || echo "$(date +'%Y-%m-%d %H:%M:%S') ${virenv}解压失败.$(echo_failure)"
	cd ${virenv%.*.*} && python setup.py install &> /dev/null
	if [ "$?" = "0" ];then
		cd -
		echo "$(date +'%Y-%m-%d %H:%M:%S') ${virenv%-*}安装成功"
		rm -rf ${virenv%.*.*}
		createVirenv
	else
		echo "$(date +'%Y-%m-%d %H:%M:%S') ${virenv%-*}安装失败"
		exit 1
	fi
}

#==============================================================================
#
#自动化运维平台数据库初始化
#
#==============================================================================

function initSql()
{
	#if [];then
	source /etc/profile
	cd ${apath}/..
	LANG=C mysql -uroot -p${password} < sql/ops_initial.sql
	if [ "${PIPESTATUS[0]}" = 0 ];then
		echo "$(date +'%Y-%m-%d %H:%M:%S') 数据库初始化成功.$(echo_success)"
	else
		echo "$(date +'%Y-%m-%d %H:%M:%S') 数据库初始化失败.$(echo_failure)"
		exit 1
	fi
	
	#Django同步数据库 (sql写入py文件)
	cd operation && python manage.py makemigrations
	if [ "$?" = 0 ];then
		echo "$(date +'%Y-%m-%d %H:%M:%S') migrations目录创建成功.$(echo_success)"
	else
		echo "$(date +'%Y-%m-%d %H:%M:%S') migrations目录创建失败.$(echo_failure)"
		exit 1
	fi
	
	#py文件同步到数据库 (model和数据库表结构已存在时，只需要将py文件中的数据migrations)
	python manage.py migrate --fake-initial && python manage.py migrate --database=elves --fake-initial
	if [ "$?" = "0" ];then
		echo "$(date +'%Y-%m-%d %H:%M:%S') Django数据库同步工程.$(echo_success)"
	else
		echo "$(date +'%Y-%m-%d %H:%M:%S') Django数据库同步失败.$(echo_failure)"
		exit 1
	fi
	
	cd ../
	LANG=C mysql -uroot -p${password} < sql/admin.sql
	if [ "$?" = "0" ];then
		echo "$(date +'%Y-%m-%d %H:%M:%S') 超级用户创建成功.$(echo_success)"
		echo "$(date +'%Y-%m-%d %H:%M:%S') 在operation目录下运行命令：python manage.py runserver 0.0.0.0:7000，进行初步体验，访问链接为http://ip:7000/maintain。默认用户名为admin，密码为admin12345"
	else
		echo "$(date +'%Y-%m-%d %H:%M:%S') 超级用户创建失败.$(echo_failure)"
		exit 1
	fi
}

function opsDep()
{
	local cmd="/usr/local/operations/rabbitmq/sbin"
	local kdir="/usr/local/operations/kafka"
	cd ${apath}/package || exit 1
	if [ "$(rpm -qa | grep otp_src)" = "" ];then
		yum localinstall -y otp_src-20.1-1.el7.centos.x86_64.rpm && echo "$(date +'%Y-%m-%d %H:%M:%S') otp_src安装成功.$(echo_success)" || echo "$(date +'%Y-%m-%d %H:%M:%S') otp_src安装失败.$(echo_failure)"
	else
		echo "$(date +'%Y-%m-%d %H:%M:%S') otp_src已经安装了."
	fi

	if [ "$(rpm -qa | grep rabbitmq)" = "" ] && [ "$(rpm -qa | grep otp_src)" != "" ];then
		yum localinstall -y rabbitmq-3.6.14-1.el7.centos.x86_64.rpm && echo "$(date +'%Y-%m-%d %H:%M:%S') RabbitMQ安装成功.$(echo_success)" || echo "$(date +'%Y-%m-%d %H:%M:%S') RabbitMQ安装失败.$(echo_failure)"
		sleep 5
		netstat -antlp | grep beam.smp && echo "$(date +'%Y-%m-%d %H:%M:%S') RabbitMQ运行中." || echo "$(date +'%Y-%m-%d %H:%M:%S') RabbitMQ没有运行."
	else
		netstat -antlp | grep beam.smp && echo "$(date +'%Y-%m-%d %H:%M:%S') RabbitMQ运行中." || echo "$(date +'%Y-%m-%d %H:%M:%S') RabbitMQ没有运行."
		echo "$(date +'%Y-%m-%d %H:%M:%S') RabbitMQ已经安装了."
	fi

	if [ ! -d '${kdir}' ];then
		mkdir -p ${kdir}
		echo "$(date +'%Y-%m-%d %H:%M:%S') kafka解压中"
		tar xf kafka-2.12.tar.gz -C ./ && echo "$(date +'%Y-%m-%d %H:%M:%S') kafka解压成功.$(echo_success)" || echo "$(date +'%Y-%m-%d %H:%M:%S') kafka解压失败.$(echo_failure)"
		if [ -d "kafka-2.12" ];then
			mv kafka-2.12/* ${kdir}/
			rm -rf kafka-2.12
			echo "$(date +'%Y-%m-%d %H:%M:%S') kafka安装成功.$(echo_success)"
		fi
		cd ${kdir}/bin
		./start.sh
		../jdk1.8.0_161/bin/jps | grep Kafka
		if [ $? -eq 0 ];then
			echo "$(date +'%Y-%m-%d %H:%M:%S') kafka启动成功.$(echo_success)"
		else
			echo "$(date +'%Y-%m-%d %H:%M:%S') kafka启动失败.$(echo_failure)"
		fi
		
	fi
}

function changRabbitUser()
{
	local cmd="/usr/local/operations/rabbitmq/sbin"
	local num=$(netstat -antlp | grep beam.smp | grep LISTEN | wc -l)
	if [  $num -ge 2 ];then
		sleep 1
		${cmd}/rabbitmqctl delete_user guest
		${cmd}/rabbitmqctl add_user elves elves
		${cmd}/rabbitmqctl set_user_tags elves administrator
		${cmd}/rabbitmqctl set_permissions -p "/" elves ".*" ".*" ".*"
		echo -e "$(date +'%Y-%m-%d %H:%M:%S') elves用户的权限设置情况如下:\n$(${cmd}/rabbitmqctl list_user_permissions elves)"
		${cmd}/rabbitmq-plugins enable rabbitmq_management
		if [ "$(netstat -antlp | grep beam.smp | grep LISTEN | grep 15672 | wc -l)" -eq 1 ];then
			echo "$(date +'%Y-%m-%d %H:%M:%S') 插件启用成功，请使用http://ip:15672来访问RabbitMQ的web管理界面。默认用户名为elves，密码为elves"
		fi
	else
		echo -e "$(date +'%Y-%m-%d %H:%M:%S') RabbitMQ没有安装或者没有运行，请检查.$(echo_warning)"
	fi
}

function addConf()
{
	cd ${apath} || exit 1
	#拷贝uwsgi.ini和ops到指定位置
	if [ -d '/usr/local/openresty/nginx/conf.d/' ];then
		cp -f ./config/openresty/conf.d/{uwsgi.ini,ops.cfg} /usr/local/openresty/nginx/conf.d/ && echo "$(date +'%Y-%m-%d %H:%M:%S') 配置文件添加成功"
		chmod 755 /usr/local/openresty/nginx/openstar/lib/kafka/*
	else
		echo "$(date +'%Y-%m-%d %H:%M:%S') '/usr/local/openresty/nginx/conf.d/'目录不存在，请处理后，将uwsgi.ini和ops.cfg手动复制到该目录下.(echo_passed)"
	fi
	
	cp -rf ./config/openresty/resty/kafka /usr/local/openresty/nginx/openstar/lib/ && echo "$(date +'%Y-%m-%d %H:%M:%S') kafka插件安装成功.$(echo_success)" || echo "$(date +'%Y-%m-%d %H:%M:%S') kafka插件安装失败.$(echo_failure)"
	
	local rs=$(grep 'ops.cfg' /usr/local/openresty/nginx/conf.d/homed.conf)
	if [ -z "${rs}" ];then
		local OPS_CONF="        include /usr/local/openresty/nginx/conf.d/ops.cfg;"
        sed -i -e "3a${OPS_CONF}" /usr/local/openresty/nginx/conf.d/homed.conf >/dev/null 2>&1
        if [ $? -ne 0 ];then
            echo "$(date +'%Y-%m-%d %H:%M:%S') 插入ops.cfg到homed.conf失败.$(echo_failure)"
            exit 1
        fi
	fi
}

function startUwsgi()
{
	if [ -f '/usr/local/openresty/nginx/conf.d/uwsgi.ini' ];then
		#local status=$(cd ${destination}/ops/sbin/;sh uwsgi.sh status | grep running)
		local status=$(cd ${destination}/ops/sbin/;sh uwsgi.sh status)
		if [[ "${status}" =~ .*stoped$ ]];then
			cd ${destination}/ops/sbin/ && sh uwsgi.sh start
			if [ $? = "0" ];then
				echo "$(date +'%Y-%m-%d %H:%M:%S') uwsgi服务启动成功.$(echo_success)"
			else
				echo "$(date +'%Y-%m-%d %H:%M:%S') uwsgi服务启动失败.$(echo_warning)"
			fi
		elif [[ "${status}" =~ .*running$ ]];then
			echo "$(date +'%Y-%m-%d %H:%M:%S') uwsgi服务运行中.$(echo_passed)"
		fi
	else
		echo "$(date +'%Y-%m-%d %H:%M:%S') uwsgi.ini不存在，请检查后，手动启动.$(echo_passed)"
	fi
}

#===========================================================================================================
#
# 安装Elves_Server
#
#===========================================================================================================

function installElvesServer()
{
	#切换目录
	cd /r2/maintain_scripts/ops || exit 1
	#软连接
	local rootDir="/homed/homedbigdata/httpdata/clusterdata"
	if [ -d "${rootDir}" ] && [ ! -L "${rootDir}/elves" ];then
		ln -s /r2/maintain_scripts/ops/elves/apps/zip ${rootDir}/elves && echo "$(date +'%Y-%m-%d %H:%M:%S') 创建软连接成功.$(echo_success)" || echo "$(date +'%Y-%m-%d %H:%M:%S') 创建软连接失败.$(echo_failure)"
	elif [ -L "${rootDir}/elves" ];then
		echo "$(date +'%Y-%m-%d %H:%M:%S') elves软连接已存在.$(echo_passed)"
	else
		echo "$(date +'%Y-%m-%d %H:%M:%S') 创建软连接异常，请手动检查.$(echo_passed)"
	fi
	
	#Server端安装
	cd elves/server && echo "$(date +'%Y-%m-%d %H:%M:%S') 开始进行Elves_Server安装."
	if [ $? -eq 0 ];then
		sed -i "s/#mysql_password#/${password}/" supervisor/conf/conf.properties
		sed -i "s/#server_ip#/${dbhost}/" supervisor/conf/conf.properties
		if [ ! -x "run.sh" ];then
			#find . -type f -name "control" -exec chmod +x {} \;
			#find . -type f -name "run.sh" -exec chmod +x {} \;
			chmod 755 -R *
			./run.sh start
			if [ $? -eq 0 ];then
				echo "$(date +'%Y-%m-%d %H:%M:%S') Elves_Server启动成功.$(echo_success)"
			else
				echo "$(date +'%Y-%m-%d %H:%M:%S') Elves_Server启动失败.$(echo_failure)"
			fi
		elif [ -x "run.sh" ];then
			chmod 755 -R *
			./run.sh start
			if [ $(/usr/local/operations/kafka/jdk1.8.0_161/bin/jps | grep elves | wc -l) = 4 ];then
				echo "$(date +'%Y-%m-%d %H:%M:%S') Elves_Server启动成功.$(echo_success)"
			else
				echo "$(date +'%Y-%m-%d %H:%M:%S') Elves_Server启动失败.$(echo_failure)"
			fi
		fi
	else
		echo "$(date +'%Y-%m-%d %H:%M:%S') Elves_Server安装异常，请检查.$(echo_failure)"
		exit 1
	fi
}



#===========================================================================================================
#
# 安装Elves_Agent
#
#===========================================================================================================

function getIps()
{
	local agentIps=""
	for host in $ipCollect
	do
		if [[ $host =~ .*-.* ]];then
			ip1=$(echo $host | awk -F'.' '{print $1"."$2"."$3"."}')
			ip2=$(echo $host | awk -F'[.|-]' '{print $4".."$5}')
			for ip in $(eval echo {"${ip2}"})
			do
				agentIps="$agentIps $ip1$ip"
			done
			agents=$agentIps
		else
			agents=$host
		fi
	done

}

#====================================
#1.创建目录
#2.同步agent
#3.修改cfg.json
#====================================

function installElvesAgent()
{
	local cfgDir="${destination}/ops/elves/agent/conf"
	local example="${cfgDir}/cfg.example.json"
	local cfg="${cfgDir}/cfg.json"
	local agentDir="/r2/maintain_scripts/ops/elves"
	local commands="if [ ! -d ${destination} ];then mkdir -p ${agentDir};fi"
	local ips=$agents
	local es=$server

	for ip in $ips
	do
		ssh $ip "${commands}"
		rsync -a ${agentDir}/agent $ip:${agentDir}
	done
	
	for ip in $ips
	do
		local name="$(ssh -q $ip hostname)"
		cp -f $example $cfg
		sed -i "s/#server_ip#/${es}/" $cfg
		sed -i "s/#hostname#/${name}/" $cfg
		sed -i "s/#agent_ip#/${ip}/" $cfg
		
		rsync -arv $cfg $ip:$cfgDir
		if [ -f $cfg ] && [ "${ip}" != "${es}" ];then
			rm -rf $cfg
		fi
	done	
}

function logInfo()
{
	local datetime="$(date '+%F %T')"
	
	echo "${datetime} [INFO] $*"
}

function logError()
{
	local datetime="$(date '+%F %T')"
	
	echo "${datetime} [ERROR] $*"
}

function logWarn()
{
	local datetime="$(date '+%F %T')"
	
	echo "${datetime} [WARN] $*"
}

function logDebug()
{
	local datetime="$(date '+%F %T')"
	
	echo "${datetime} [DEBUG] $*"
}