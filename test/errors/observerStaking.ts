export enum ObserverStakingErrors {
  StakeNotExpired = 'ObserverStaking__StakeNotExpired',
  CannotExtendNonExistentStake = 'ObserverStaking__CannotExtendNonExistentStake',
  ExecutionNotAuthorized = 'ObserverStaking__ExecutionNotAuthorized',
  InvalidSlashAmount = 'ObserverStaking__InvalidSlashAmount',
  TransferFailed = 'ERC20: transfer amount exceeds balance'
}
