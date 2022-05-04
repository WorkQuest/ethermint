#!/bin/sh

BCPATH="/Users/vito/.ethermintd"
DATAPATH=$BCPATH"/data"
PRIV_VAL_STATE=$DATAPATH"/priv_validator_state.json"
ADDR_BOOK=$BCPATH"/config/addrbook.json"

if [ ! -d $DATAPATH ]
then
    echo "db_dir does not exists"
    exit
fi

rm -rf $ADDR_BOOK

rm -rf $DATAPATH
mkdir $DATAPATH

cp default_priv_validator_state.json $PRIV_VAL_STATE

ls $DATAPATH