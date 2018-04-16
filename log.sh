#!/bin/bash

# Date: 2018-04-12
# Author: Liu Yangfa
# Descrition: shell log output
# Version: 1.0

function logDebug()
{
	local datetime="$(date '+%F %T')"
	
	echo "${datetime} [DEBUG] $*"
}

function logInfo()
{
	local datetime="$(date '+%F %T')"
	
	echo "${datetime} [INFO] $*"
}

function logWarn()
{
	local datetime="$(date '+%F %T')"
	
	echo "${datetime} [WARN] $*"
}

function logError()
{
	local datetime="$(date '+%F %T')"
	
	echo "${datetime} [ERROR] $*"
}
