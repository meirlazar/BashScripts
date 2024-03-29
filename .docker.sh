if ! which docker; then return; fi

function CreateDockerDB () {
unset dockerDB
readarray -t dockerDB< <(for x in $(docker ps --format '{{.Names}}'); do docker inspect ${x} | jq -r '.[0]|"\(.Config.Labels["com.docker.compose.project"]):\(.Config.Labels["com.docker.compose.project.working_dir"]):\(.Config.Labels["com.docker.compose.service"])"'; done)
}
function GREPDOCKERCOMPOSE () {
read -p "Type Path to search in": gdir
read -p "Type string to search for": STRING
read -p "Would you like to Find all docker-compose files without this string? Y/N":  INVERT
case "${INVERT^}" in
Y|y )   grep -irlv "${STRING}" ${gdir}/*/docker-compose.yml ;;
N|n )   grep -irl "${STRING}" ${gdir}/*/docker-compose.yml ;;
*   )   echo "Wrong selection" ;;
esac
}


function docker-rebuild-all-running () {
for x in $(docker ps --format '{{.Names}}'); do 
DIR=$(docker inspect --format '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}' "${x}")
docker-compose -f ${DIR}/docker-compose.yml down; 
docker-compose -f ${DIR}/docker-compose.yml up -d;
done
}

function docker-update-all-running () {
for x in $(docker ps --format '{{.Names}}'); do
DIR=$(docker inspect --format '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}' "${x}")
docker-compose -f ${DIR}/docker-compose.yml pull; 
docker-compose -f ${DIR}/docker-compose.yml up -d; 
done
}


function DOCKERPORTSUSED () {
        ALLPORTS=$(docker container ls --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}" -a)
        readarray -t PORTSINUSE< <(echo "${ALLPORTS}" | awk '{for(i=1;i<=NF;i++){if($i~/^:/){print $i}}}' | cut -d '>' -f1 | tr -d :-)
        printf "%s\n" ${PORTSINUSE[@]}
}


alias dockerports='docker container ls --format "table {{.Ports}}" | cut -d ">" -f1 | tr -d :-'
alias dockerstopall='for X in $(docker ps -q); do docker stop ${X}; done'
alias dockerports='docker container ls --format "table {{.Ports}}" | cut -d ">" -f1 | tr -d :-'
alias dockernames="docker ps --format '{{.Names}}'"
alias dockershowallinfo='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Mounts}}\t{{.Ports}}\t{{.Networks}}\t{{.State}}" | tr -s " " | column'
alias dstopall="docker stop $(docker container list -q -a)"
alias dstartalll="docker start $(docker ps -a -q -f status=exited)"
alias drestartall="docker restart $(docker ps -a -q)"
alias dports='docker container ls --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}" -a'
alias dimages='docker images'
alias dstats='docker stats'
alias dpsa='docker ps -a'
alias dps='docker ps'
function dockerstart () { docker start ${1:?"Error: Requires: container_name as argument"} ; }
function dockerstop () { docker stop ${1:?"Error: Requires: container_name as argument"} ; }


alias dcu='docker-compose up -d'
alias dcu_fr_ro='docker-compose up --force-recreate --remove-orphans -d'
alias dcdrmi='docker-compose down --rmi all'
alias dcd='docker-compose down'
alias dcr='docker-compose restart'
alias dcp='docker-compose pull'
alias dstat='docker stats'
alias dname="docker ps --format '{{.Names}}'"

function dlogs () {
unset darray ; arg=$1 ; 
readarray -t darray< <(printf " %s\n" $(docker ps --format '{{.Names}}') | grep -n "^") ;
CreateDockerDB
if [[ $# -eq 1 ]]; then 
	docker logs -f "${arg}" ;  
elif 
	grep -iw "${PWD##*/}" <<< $(printf '%s\n' "${darray[@]}"); then docker logs -f "${PWD##*/}"; 
else 
	printf '%s\n' "${darray[@]}"; 
	read -p "Choose by number": choose
	dname=$(printf '%s\n' "${darray[@]}" | grep -iw "${choose}" | cut -d":" -f2); docker logs -f "${dname}";
fi
}

function listallrunning () { 
echo "$(date +'%F_%T') - $(docker ps --format '{{.Names}}' | wc -l) - $(docker ps --format '{{.Names}}' | tr '\n' ' ')"
}

function fixunhealthy () {
for x in $(docker ps --format '{{.Names}}' | tr '\n' ' '); do docker cp /bin/curl ${x}:/bin/curl ; done
}

function dockerbash () {
unset darray ; arg=$1 ;
readarray -t darray< <(printf " %s\n" $(docker ps --format '{{.Names}}') | grep -n "^") ;
if [[ $# -eq 1 ]]; then
        docker exec -it "${arg}" /bin/bash ;
elif
        grep -iw "${PWD##*/}" <<< $(printf '%s\n' "${darray[@]}"); then docker exec -it "${PWD##*/}" /bin/bash; 
else 
        printf '%s\n' "${darray[@]}"; 
        read -p "Choose by number": choose
        dname=$(printf '%s\n' "${darray[@]}" | grep -iw "${choose}" | cut -d":" -f2);  docker exec -it "${dname}" /bin/bash;
fi
}

function dockerinspect () {
unset darray ; arg=$1 ;
readarray -t darray< <(printf " %s\n" $(docker ps --format '{{.Names}}') | grep -n "^") ;
if [[ $# -eq 1 ]]; then
        docker inspect "${arg}";
elif
        grep -iw "${PWD##*/}" <<< $(printf '%s\n' "${darray[@]}"); then docker inspect "${PWD##*/}"; 
else 
        printf '%s\n' "${darray[@]}"; 
        read -p "Choose by number": choose
        dname=$(printf '%s\n' "${darray[@]}" | grep -iw "${choose}" | cut -d":" -f2); docker inspect "${dname}";
fi
}

# function dockerbash () { docker exec -it ${1:?"Error: Requires: container_name as argument"} /bin/bash ; }
function dockerinspectenv () { docker inspect -f "{{ .Config.Env }}" ${1:?"Error: Requires: container_name as argument"} ; }

function dockercopyfromcontainer () {
read -p "Container name": cont
read -p "Container source path": srcpath
read -p "Host destination path": destpath
cont=${cont:?"Error: Requires: valid running container_name"} ;
srcpath=${srcpath:?"Error: Requires /container/src/path"} ;
destpath=${destpath:?"Error: Requires /host/dest/path"} ;
docker copy ${cont}:${srcpath} ${destpath} ;
}

function dockercopyfromhost () {
read -p "Container name": cont
read -p "Host source path": srcpath
read -p "Container destination path": destpath
cont=${cont:?"Error: Requires: valid running container_name"} ;
srcpath=${srcpath:?"Error: Requires /host/src/path"} ;
destpath=${destpath:?"Error: Requires /container/dest/path"} ;
docker copy ${srcpath} ${cont}:${destpath} ;
}
