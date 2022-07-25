package keeper

import (
	"fmt"
	sdk "github.com/cosmos/cosmos-sdk/types"
	ethtypes "github.com/ethereum/go-ethereum/core/types"
	abci "github.com/tendermint/tendermint/abci/types"
	ethermint "github.com/tharsis/ethermint/types"
)

// BeginBlock sets the sdk Context and EIP155 chain id to the Keeper.
func (k *Keeper) BeginBlock(ctx sdk.Context, req abci.RequestBeginBlock) {
	/*
		Initially, we started the network with DefaultPowerReduction = 1000000, which led to delegation issues.
		When we delegated 1152921 WQT, which is not much for our network,
		we got

		[
		error="error during handshake: error on replay: commit failed for application: error changing validator set:
		to prevent clipping/overflow, voting power can't be higher than 1152921504606846975, got 1512933500008055742"
		],

		this happened because a unit of consensus power was cheap for delegates.
		To prevent this from happening again, we extended the DefaultPowerReduction to 1 * 10^18
	*/
	k.Logger(ctx).Info(fmt.Sprintf("EVM block height:%d", ctx.BlockHeight()))
	if ctx.BlockHeight() == 1348681 {
		k.Logger(ctx).Info(fmt.Sprintf("All ok"))
		validators := k.stakingKeeper.GetAllValidators(ctx)
		for _, v := range validators {
			k.Logger(ctx).Info(fmt.Sprintf("ValAddress: %s", v.OperatorAddress))
			k.stakingKeeper.DeleteValidatorByPowerIndex(ctx, v)
		}
	}

	if ctx.BlockHeight() >= 1348681 {
		sdk.DefaultPowerReduction = ethermint.PowerReduction
	}
	//

	k.WithChainID(ctx)
}

// EndBlock also retrieves the bloom filter value from the transient store and commits it to the
// KVStore. The EVM end block logic doesn't update the validator set, thus it returns
// an empty slice.
func (k *Keeper) EndBlock(ctx sdk.Context, req abci.RequestEndBlock) []abci.ValidatorUpdate {
	// Gas costs are handled within msg handler so costs should be ignored
	infCtx := ctx.WithGasMeter(sdk.NewInfiniteGasMeter())

	bloom := ethtypes.BytesToBloom(k.GetBlockBloomTransient(infCtx).Bytes())
	k.EmitBlockBloomEvent(infCtx, bloom)

	return []abci.ValidatorUpdate{}
}
