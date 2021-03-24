#!/bin/sh

HOUR_IN_UNIX=3600

set_value_at_key () {
    curl -s --request PUT "https://api.kvstore.io/collections/kv/items/$1" \
            --header "kvstoreio_api_key: ${KV_STORE_API_KEY}" \
            --header "Content-Type: text/plain" \
            --data-raw "$2"
}

get_current_time () {
    local current_time=$(curl -s https://api.keyvalue.xyz/timestamp)
    echo ${current_time}
}

get_value_at_key () {
    local value=$(curl -s --request GET "https://api.kvstore.io/collections/kv/items/$1" \
            --header "kvstoreio_api_key: ${KV_STORE_API_KEY}" | jq -r '.value')
    
    echo ${value}
}

check_is_last_exec_time () {
    local current_time=$(get_current_time)
    local diff_unix=$((HOUR_IN_UNIX * $(get_value_at_key diff)))
    local last_exec=$(get_value_at_key last_exec)

    echo $(( (current_time - last_exec) > diff_unix ))
}

if ([ $GITHUB_EVENT = "schedule" ] && [ $(get_value_at_key has_changes) = 1 ]) || [ $GITHUB_EVENT = "workflow_dispatch" ];
then
    set_value_at_key has_changes 0;
    echo "::set-output name=should_run::true"

elif [ $(check_is_last_exec_time) = 0 ] && [ ${PR_MERGED} = true ];   
then
    set_value_at_key has_changes 1;
else
    set_value_at_key has_changes 0;
    set_value_at_key last_exec $(get_current_time);
fi
