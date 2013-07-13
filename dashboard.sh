#!/usr/bin/env bash
# Cronjob for pushing UTM v9.1 health stats to leftronic
# 2013-07-13 Sam Wilson <kahn@the-mesh.org>
# TODO: Package as RPM to handle deps and setup config
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

APIKEY=Your Lefttronic access key

SENSORS=`/bin/rpm -qi sensors`
if [ $? -eq 1 ]; then
	echo "ERROR: Your system is missing the sensors package. Exiting"
	exit 1
fi
CURL=`/bin/rpm -qi curl`
if [ $? -eq 1 ]; then
	echo "ERROR: Your system is missing the curl package. Exiting"
	exit 1
fi
# Temperature
if [ -f /etc/sysconfig/lm_sensors ]; then
	CHIPSET=`sensors | grep temp1: | cut -d " " -f 9 | sed 's/°C//' | sed 's/+//'`
	curl -i -X POST -k -d '{"accessKey": "'$APIKEY'", "streamName": "chipsetTemp", "point": '$CHIPSET'}' https://www.leftronic.com/customSend/
	CPU=`sensors | grep 'Core 0:' | cut -d " " -f 9 | sed 's/°C//' | sed 's/+//'`
	curl -i -X POST -k -d '{"accessKey": "'$APIKEY'", "streamName": "cpuTemp", "point": '$CPU'}' https://www.leftronic.com/customSend/
	LA1=`uptime | cut -d ',' -f 3 | cut -d ' ' -f 5`
	curl -i -X POST -k -d '{"accessKey": "'$APIKEY'", "streamName": "loadAvg1", "point": '$LA1'}' https://www.leftronic.com/customSend/
	LA5=`uptime | cut -d ',' -f 4 | sed 's/ //'`
	curl -i -X POST -k -d '{"accessKey": "'$APIKEY'", "streamName": "loadAvg5", "point": '$LA5'}' https://www.leftronic.com/customSend/
	LA15=`uptime | cut -d ',' -f 5 | sed 's/ //'`
	curl -i -X POST -k -d '{"accessKey": "'$APIKEY'", "streamName": "loadAvg15", "point": '$LA15'}' https://www.leftronic.com/customSend/
else
	echo "No lm_sensors configuration found. You need to run sensors-detect"
	exit 1
fi
# Storage
STORAGE=`df -h /var/storage/ | grep storage | cut -d " " -f 17 | cut -d "%" -f 1`
curl -i -X POST -k -d '{"accessKey": "'$APIKEY'", "streamName": "storage", "point": '$STORAGE'}' https://www.leftronic.com/customSend/
LOG=`df -h /var/log/ | grep log | cut -d " " -f 15 | cut -d "%" -f 1`
curl -i -X POST -k -d '{"accessKey": "'$APIKEY'", "streamName": "log", "point": '$LOG'}' https://www.leftronic.com/customSend/
# Monitoring
PCAP=`ps aux | grep tcpdump | grep -v grep`
if [ $? -eq 0 ];
then
 # Green 0
 curl -i -X POST -k -d '{"accessKey": "'$APIKEY'", "streamName": "monitoring", "point": '0'}' https://www.leftronic.com/customSend/
else
 # Red 100
 curl -i -X POST -k -d '{"accessKey": "'$APIKEY'", "streamName": "monitoring", "point": '100'}' https://www.leftronic.com/customSend/
fi