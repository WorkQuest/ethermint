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

ACTUAL_VAL_STATE=actual_priv_validator_state.json
cp $PRIV_VAL_STATE ./$ACTUAL_VAL_STATE

rm -rf $DATAPATH
mkdir $DATAPATH

cp $ACTUAL_VAL_STATE $PRIV_VAL_STATE

rm -rf $ACTUAL_VAL_STATE
rm -rf $ADDR_BOOK

ls $DATAPATH