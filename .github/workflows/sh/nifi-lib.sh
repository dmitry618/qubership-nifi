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
        res=0
        resp_code=""
        resp_code=$(curl -sS -w '%{response_code}' -o ./temp-resp.json --connect-timeout 5 --max-time 10 "$nifiUrl") || { res="$?"; echo "Failed to call NiFi API, continue waiting..."; }
        if [ "$res" == "0" ]; then
            if [ "$resp_code" != '200' ]; then
                res='$resp_code'
                echo "Got response with code = $resp_code and body: "
                cat ./temp-resp.json
            fi
        fi
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
