#!/bin/sh

if ! command -v jq &> /dev/null
then
    echo "jq could not be found"
    exit
fi

TOKEN_DENOM=$(jq -r '.token_denom' scripts/node_params.json)
AMOUNT=$(jq -r '.amount_to_gentx' scripts/node_params.json)$TOKEN_DENOM
WALLET_BALANCE=$(jq -r '.wallet_balance' scripts/node_params.json)$TOKEN_DENOM
CHAIN_ID=$(jq -r '.chain_id' scripts/node_params.json);

HOME_PATH=$(eval echo "~$different_user")
NODE_PARAMS="scripts/node_params.json"
BCPATH=$HOME_PATH"/.ethermintd"
OUTPUT=$BCPATH"/config/gentx/"

# Check existing genesis.json file
if [ ! -f $BCPATH/config/genesis.json ]
then
    echo "genesis file is not exists to path:" $BCPATH/config/genesis.json
    exit
fi

# Check existing node_params.json file
if [ ! -f $NODE_PARAMS ]
then
    echo "nodes params config file not exist to path:" $NODE_PARAMS
    exit
fi


# Check existing gentxs dir
if [ ! -d $OUTPUT ]
then
    mkdir $OUTPUT
fi

for (( c=0; c<$(jq '.validators | length' $NODE_PARAMS); c++ ))
do
  # Get node params
  ip=$(jq -r '.validators['$c']."ip"' $NODE_PARAMS)
  id=$(jq -r '.validators['$c']."id"' $NODE_PARAMS)
  moniker=$(jq -r '.validators['$c']."moniker"' $NODE_PARAMS)
  pubkey=$(jq -r '.validators['$c']."pubkey"' $NODE_PARAMS)

  # Add node key
  ethermintd keys add $moniker

  # Add node key on genesis
  ethermintd add-genesis-account $moniker $WALLET_BALANCE

  # Create tx for start validator
  ethermintd gentx $moniker $AMOUNT \
  --chain-id $CHAIN_ID \
  --ip $ip \
  --moniker $moniker \
  --node-id $id \
  --output-document "$OUTPUT""$moniker"".json" \
  --pubkey $pubkey
done

# Collect gentxs
ethermintd collect-gentxs

memos=()
monikers=()
# Getting memos of network nodes
for (( c=0; c<$(jq '.app_state.genutil.gen_txs | length' $BCPATH/config/genesis.json ); c++ ))
do
  moniker=$(jq -r '.app_state.genutil.gen_txs['$c'].body.messages[0].description."moniker"' $BCPATH/config/genesis.json )
  memo=$(jq -r '.app_state.genutil.gen_txs['$c'].body."memo"' $BCPATH/config/genesis.json )

  memos[$c]=$memo
  monikers[$c]=$moniker
done

# Getting memos of archive nodes
for (( c=0; c<$(jq '.archive | length' $NODE_PARAMS); c++ ))
do
  moniker=$(jq -r '.archive['$c']."moniker"' $NODE_PARAMS)
  memo=$(jq -r '.archive['$c']."id"' $NODE_PARAMS )"@"$(jq -r '.archive['$c']."ip"' $NODE_PARAMS )":26656"

  memos[${#memos[@]}]=$memo
  monikers[${#monikers[@]}]=$moniker
done

# Print memos
echo "\nAdd this memos to persistent_peers on other nodes"
for i in "${!memos[@]}"; do
  echo "The ${monikers[$i]} node has memo: ${memos[$i]}"
done

