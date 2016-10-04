#!/bin/sh


printhelp () {
   echo "$0 [<option> <value>].  The 4 options are mandatory: -p -s -i -l"
   echo "    -p <NUM_LOGGING_PODS>: the number of logging pods containers to start per node, during each interval"
   echo "    -s <LOG_STRING_SIZE>: the size in number of characters, of the logger string"
   echo "    -i <SLEEP_INTERVAL_SECS>: sleep interval in seconds, between incremental steps"
   echo "    -l <LOOP_COUNT>: the numbe of incremental steps"
   echo "    -h : print help"
   echo -e "\nExample: $0 -p 100 -s 128 -i 600 -l 4; will launch 100 pods per node, of 128 char strings, wait 600 secs between each launch, and loop for 4 times"
   exit 1
}

echo "Argument list: '$@'"
echo "Total number of arguments: '$#'"

# Note: the leading colon before the p, ":p" " nullifies getting default error messages from system,
#       so we can control error handling with our while getops loop and printhelp function 
# If the very first character of the option-string is a : (colon), which would normally be nonsense 
# because there's no option letter preceding it, getopts switches to "silent error reporting mode".
#  In productive scripts, this is usually what you want because it allows you to handle errors 
# yourself without being disturbed by annoying messages. 

while getopts ":p:s:i:l:h:" option;
do
 case $option in
   p)
      NUM_LOGGING_PODS="$OPTARG";;
   s)
      LOG_STRING_SIZE="$OPTARG";;
   i)
      SLEEP_INTERVAL_SECS="$OPTARG";;
   l)
      LOOP_COUNT="$OPTARG";;
   h)
      printhelp
      exit 1;;
   \?) 
      echo -e "Invalid option: -$OPTARG" >&2
      printhelp
      exit 1;;
   :)
      echo "Option -$OPTARG requires an argument." >&2
      printhelp
      exit 1;;
   *) 
      echo "Unimplemented option: -$OPTARG" >&2 
      exit 1;;
  esac
done

# making sure we got the required arguments from the options above
#  test to see if they gave the -p option
#
if [ "x" == "x$NUM_LOGGING_PODS" ]; then
  echo "-p [option] is required"
  printhelp
  exit 1
fi

if [ "x" == "x$LOG_STRING_SIZE" ]; then
  echo "-s [option] is required"
  printhelp
  exit 1
fi

if [ "x" == "x$SLEEP_INTERVAL_SECS" ]; then
  echo "-i [option] is required"
  printhelp
  exit 1
fi

if [ "x" == "x$LOOP_COUNT" ]; then
  echo "-l [option] is required"
  printhelp
  exit 1
fi

## Return code for future use
rc=0

# collected command line arguments from options:
echo -e "\nNUM_LOGGING_PODS is: '${NUM_LOGGING_PODS}'"
echo "LOG_STRING_SIZE is: '${LOG_STRING_SIZE}'"
echo "SLEEP_INTERVAL_SECS is: '${SLEEP_INTERVAL_SECS}'"
echo "LOOP_COUNT is: '${LOOP_COUNT}'"


############## remove later:
#### exit 0

# collect number of logs from kibana
POD=`oc get pods | grep kibana | cut -d' ' -f 1`

function report() {
  echo -e "\nCall to function report to collect count of all operations form Easlticsearch:"
  date
  oc exec $POD -- curl --connect-timeout 2 -s -k --cert /etc/kibana/keys/cert --key /etc/kibana/keys/key https://logging-es:9200/.operations*/_count | python -mjson.tool | grep count | cut -d':' -f 2-10

  #  | python -c 'import json, sys; print json.loads(sys.stdin.read())["count"]'
}


##### start test
date
echo -e "\nStarting Logging test.  Calling erpot function before creating logging pods"
report
date

TOTAL_LOGGING_PODS=0
COUNTER=0
## NUM_LOGGING_PODS=50
## LOG_STRING_SIZE=128
## SLEEP_INTERVAL_SECS=600
## LOOP_COUNT=4
## SLEEP_INTERVAL_SECS=60
# loop 4 times
# for (( c=1; c<=4; c++ ))
for (( c=1; c<=$LOOP_COUNT; c++ ))
do

  echo "\nStart of iteration $c"
  ## print current date
  date
  ## Run this on master node
  echo "Starting $NUM_LOGGING_PODS new busybox logging containers on all nodes in cluster"
  echo "Total logging pods so far: $(($c * $NUM_LOGGING_PODS))"
  # Runs 3 busybox containers per each node. 
  # export TIMES=25; export MODE=1; ./manage_pods.sh -r 128
  export TIMES=$NUM_LOGGING_PODS; export MODE=1; ./manage_pods.sh -r $LOG_STRING_SIZE
  echo "Checking logging pod status across all nodes"
  export MODE=1; ./manage_pods.sh -c 1

  echo "Sleeping for $SLEEP_INTERVAL_SECS seconds"
  ## sleep 10 mins
  sleep $SLEEP_INTERVAL_SECS

  # call report function to grab count
  echo "Collecting stats from Elasticsearch DB ...."
  report

done 


############## after for loop, kill pods

### kill all pods
echo "Killing all logging pods"
## Kill pods in every node.
export MODE=1; ./manage_pods.sh -k 1

# Check pods.
echo "Checking Final logging pod status ... should be all killed"
export MODE=1; ./manage_pods.sh -c 1

date
report

exit 0


