#!/usr/bin/env bash
timestamp=$(date "+%m-%d-%y+%H:%M:%S")
if [ -f "$HOME"/logs/ssb-server.log ]; then
    echo "Archiving Scuttlebot logs"
    mkdir -p "$HOME"/logs/archives/"$timestamp"
    cp "$HOME"/logs/ssb-server.log "$HOME"/logs/archives/"$timestamp"/ssb-server.log
fi
PID_SCUT=$(ps aux | grep ssb-server/bin.js | grep -v grep | awk '{print $2}')
if ! [[ -z $PID_SCUT ]]; then
    echo "Scuttlebot is still running, killing existing instance"
    kill $PID_SCUT
    while $(kill -0 $PID_SCUT 2>/dev/null); do
        sleep 1
    done
fi
echo "Launching Scuttlebot Server..."
nohup "$HOME"/ssb-server/bin.js server >"$HOME"/logs/ssb-server.log 2>&1 &

sleep 2
if [ -f "$HOME"/logs/omnia.log ]; then
    echo "Archiving Omnia logs"
    mkdir -p "$HOME"/logs/archives/"$timestamp"
    cp "$HOME"/logs/omnia.log "$HOME"/logs/archives/"$timestamp"/omnia.log
fi
PIDS_OMNIA=$(ps aux | grep omnia/omnia.sh | grep -v grep | awk '{print $2}')
if ! [[ -z $PIDS_OMNIA ]]; then
    echo "Omnia is still running, killing existing instance"
    for PID in "${PIDS_OMNIA[@]}"; do
        kill $PID
        while $(kill -0 $PID 2>/dev/null); do
            sleep 1
        done
    done
fi
echo "Launching Omnia..."
nohup "$HOME"/oracles-v2/omnia/omnia.sh >"$HOME"/logs/omnia.log 2>&1 &
