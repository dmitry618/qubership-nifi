#!/bin/bash -e

wait_for_nifi(){
    local isTls="$1"
    local timeout="$2"
    local nifiHost="$3"
    local nifiPort="$4"
    
    if [ -z "$timeout" ]; then
        echo "Using default timeout = 180 seconds"
        timeout=180
    fi
    if [ -z "$nifiHost" ]; then
        echo "Using default nifi host = 127.0.0.1"
        nifiHost="127.0.0.1"
    fi
    if [ -z "$nifiPort" ]; then
        echo "Using default nifi port = 8080"
        nifiPort="8080"
    fi
    
    nifiUrl=""
    additionalArguments=""
    if [ "${isTls}" == "true" ]; then
        echo "Using TLS mode..."
        echo "Waiting for nifi to be available on port 8080 with timeout = $timeout"
        nifiUrl="https://$nifiHost:$nifiPort/nifi-api/controller/config"
    else
        echo "Using plain mode..."
        echo "Waiting for nifi to be available on port 8080 with timeout = $timeout"
        nifiUrl="http://$nifiHost:$nifiPort/nifi-api/controller/config"
    fi
    
    startTime=$(date +%s)
    endTime=$((startTime+timeout))
    remainingTime="$timeout"
    res=1
    while [ "$res" != "0" ]; do
        echo "Waiting for nifi to be available under URL = $nifiUrl, remaining time = $remainingTime"
        curl -sS --connect-timeout 5 --max-time 10 "$nifiUrl" || {res="1"; echo "Request failed, continue waiting..."; }
        res=$?
        echo ""
        currentTime=$(date +%s)
        remainingTime=$((endTime-currentTime))
        if ((currentTime > endTime)); then
            echo "ERROR: timeout reached; failed to wait"
            exit 1;
        fi
        sleep 0.5
    done
    echo "Wait finished successfully. NiFI is available."
}
