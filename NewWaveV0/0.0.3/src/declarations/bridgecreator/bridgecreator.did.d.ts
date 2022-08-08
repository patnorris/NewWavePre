import type { Principal } from '@dfinity/principal';
export interface BridgeEntity {
  'internalId' : string,
  'toEntityId' : string,
  'creator' : Principal,
  'fromEntityId' : string,
  'owner' : Principal,
  'externalId' : [] | [string],
  'creationTimestamp' : bigint,
  'name' : [] | [string],
  'description' : [] | [string],
  'keywords' : [] | [Array<string>],
  'state' : BridgeState,
  'settings' : EntitySettings,
  'listOfEntitySpecificFieldKeys' : Array<string>,
  'entityType' : EntityType,
  'bridgeType' : BridgeType,
  'entitySpecificFields' : [] | [string],
}
export interface BridgeEntityInitiationObject {
  '_externalId' : [] | [string],
  '_fromEntityId' : string,
  '_owner' : [] | [Principal],
  '_creator' : [] | [Principal],
  '_entitySpecificFields' : [] | [string],
  '_state' : [] | [BridgeState],
  '_entityType' : EntityType,
  '_bridgeType' : BridgeType,
  '_description' : [] | [string],
  '_keywords' : [] | [Array<string>],
  '_settings' : [] | [EntitySettings],
  '_internalId' : [] | [string],
  '_toEntityId' : string,
  '_name' : [] | [string],
}
export type BridgeState = { 'Confirmed' : null } |
  { 'Rejected' : null } |
  { 'Pending' : null };
export type BridgeType = { 'OwnerCreated' : null };
export type EntitySettings = {};
export type EntityType = { 'Webasset' : null } |
  { 'BridgeEntity' : null } |
  { 'Person' : null } |
  { 'Location' : null };
export interface _SERVICE {
  'create_bridge' : (arg_0: BridgeEntityInitiationObject) => Promise<
      BridgeEntity
    >,
}