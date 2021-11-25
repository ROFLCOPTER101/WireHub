#!/bin/bash

app_name="dashboard.py"
app_official_name="WGDashboard"
dashes='------------------------------------------------------------'
equals='============================================================'
help () {
  printf "=================================================================================\n"
  printf "+          <WGDashboard> by Donald Zou - https://github.com/donaldzou           +\n"
  printf "=================================================================================\n"
  printf "| Usage: ./wgd.sh <option>                                                      |\n"
  printf "|                                                                               |\n"
  printf "| Available options:                                                            |\n"
  printf "|    start: To start WGDashboard.                                               |\n"
  printf "|    stop: To stop WGDashboard.                                                 |\n"
  printf "|    debug: To start WGDashboard in debug mode (i.e run in foreground).         |\n"
  printf "|    update: To update WGDashboard to the newest version from GitHub.           |\n"
  printf "|    install: To install WGDashboard.                                           |\n"
  printf "| Thank you for using! Your support is my motivation ;)                         |\n"
  printf "=================================================================================\n"
}

_check_and_set_venv(){
    # deb/ubuntu users: might need a 'apt install python3.8-venv'
    # set up the local environment
    APP_ROOT=`pwd`
    VIRTUAL_ENV="${APP_ROOT%/*}/venv"
    if [ ! -d $VIRTUAL_ENV ]; then
        python3 -m venv $VIRTUAL_ENV
    fi
    . ${VIRTUAL_ENV}/activate
}

install_wgd(){
    # Check Python3 version
    version_pass=$(python3 -c 'import sys; print("1") if (sys.version_info.major == 3 and sys.version_info.minor >= 7) else print("0");')
    if [ $version_pass == "0" ]
      then printf "| WGDashboard required Python3.7+                  |\n"
      printf "%s\n" "$dashes"
      exit 1
    fi
    rm db/hi.txt >  /dev/null 2>&1
    if [ ! -d "log" ]
      then mkdir "log"
    fi
    printf "| Installing latest Python dependencies                    |\n"
    
    # set up the local environment
    _check_and_set_venv
    
    python3 -m pip install -r requirements.txt >  /dev/null 2>&1
    printf "| WGDashboard installed successfully!              |\n"
    
    printf "| Preparing the systemctl unit file                        |\n"
    sed -i "s#{{APP_ROOT}}#${APP_ROOT}#" wg-dashboard.service
    sed -i "s#{{VIRTUAL_ENV}}#${VIRTUAL_ENV}#" wg-dashboard.service
    cat wg-dashboard.service | sudo SYSTEMD_EDITOR=tee systemctl edit --force --full wg-dashboard.service
    systemctl daemon-reload
    printf "| Consider 'systemctl enable wg-dashboard'                 |\n"
    printf "       and 'systemctl start wg-dashboard'\n"
    printf "       use '${0} stop' before starting with systemctl\n"
    echo
    
    printf "| Now starting Dashboard in background                     |\n"
    start_wgd
}


check_wgd_status(){
  if ps aux | grep '[p]ython3 '$app_name > /dev/null;
    then
      return 0
      else
        return 1
  fi
}

start_wgd () {
    _check_and_set_venv
    printf "%s\n" "$dashes"
    printf "| Starting WGDashboard in the background.          |\n"
    if [ ! -d "log" ]
      then mkdir "log"
    fi
    d=$(date '+%Y%m%d%H%M%S')
    python3 "$app_name" > log/"$d".txt 2>&1 &
    printf "| Log files is under log/                                  |\n"
    printf "%s\n" "$dashes"
}

stop_wgd() {
  kill "$(ps aux | grep "[p]ython3 $app_name" | awk '{print $2}')"
}

start_wgd_debug() {
  printf "%s\n" "$dashes"
  _check_and_set_venv
  printf "| Starting WGDashboard in the foreground.                  |\n"
  python3 "$app_name"
  printf "%s\n" "$dashes"
}

update_wgd() {
  new_ver=$(python3 -c "import json; import urllib.request; data = urllib.request.urlopen('https://api.github.com/repos/donaldzou/WGDashboard/releases/latest').read(); output = json.loads(data);print(output['tag_name'])")
  printf "%s\n" "$dashes"
  printf "| Are you sure you want to update to the %s? (Y/N): " "$new_ver"
  read up
  if [ "$up" = "Y" ]; then
    printf "| Shutting down WGDashboard...                             |\n"
    kill "$(ps aux | grep "[p]ython3 $app_name" | awk '{print $2}')"
    printf "| Downloading %s from GitHub...                            |\n" "$new_ver"
    git stash > /dev/null 2>&1
    git pull https://github.com/donaldzou/wireguard-dashboard.git $new_ver --force >  /dev/null 2>&1
    printf "| Installing latest Python dependencies                    |\n"
    _check_and_set_venv
    python3 -m pip install -r requirements.txt >  /dev/null 2>&1
    printf "| Update Successfully!                                     |\n"
    start_wgd
  else
    printf "%s\n" "$dashes"
    printf "| Update Canceled.                                         |\n"
    printf "%s\n" "$dashes"
  fi
}


if [ "$#" != 1 ];
  then
    help
  else
    if [ "$1" = "start" ]; then
        if check_wgd_status; then
          printf "%s\n" "$dashes"
          printf "| WGDashboard is already running.                          |\n"
          printf "%s\n" "$dashes"
          else
            start_wgd
        fi
      elif [ "$1" = "stop" ]; then
        if check_wgd_status; then
            printf "%s\n" "$dashes"
            stop_wgd
            printf "| WGDashboard is stopped.                                  |\n"
            printf "%s\n" "$dashes"
            else
              printf "%s\n" "$dashes"
              printf "| WGDashboard is not running.                              |\n"
              printf "%s\n" "$dashes"
        fi
      elif [ "$1" = "update" ]; then
        update_wgd
      elif [ "$1" = "install" ]; then
        install_wgd
      elif [ "$1" = "restart" ]; then
         if check_wgd_status; then
           printf "%s\n" "$dashes"
           stop_wgd
           printf "| WGDashboard is stopped.                                  |\n"
           sleep 2
           start_wgd
        else
          start_wgd
        fi
      elif [ "$1" = "debug" ]; then
        if check_wgd_status; then
          printf "| WGDashboard is already running.                          |\n"
          else
            start_wgd_debug
        fi
      else
        help
    fi
fi
