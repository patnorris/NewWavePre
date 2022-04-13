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
  'entityType' : EntityType,
  'bridgeType' : BridgeType,
}
export type BridgeState = { 'Confirmed' : null } |
  { 'Rejected' : null } |
  { 'Pending' : null };
export type BridgeType = { 'OwnerCreated' : null };
export interface Entity {
  'internalId' : string,
  'creator' : Principal,
  'owner' : Principal,
  'externalId' : [] | [string],
  'creationTimestamp' : bigint,
  'name' : [] | [string],
  'description' : [] | [string],
  'keywords' : [] | [Array<string>],
  'settings' : EntitySettings,
  'entityType' : EntityType,
}
export type EntitySettings = {};
export type EntityType = { 'Webasset' : null } |
  { 'BridgeEntity' : null } |
  { 'Person' : null } |
  { 'Location' : null };
export interface _SERVICE {
  'create_bridge' : () => Promise<BridgeEntity>,
  'create_entity' : () => Promise<Entity>,
  'create_entity_and_bridge' : () => Promise<[Entity, BridgeEntity]>,
  'greet' : (arg_0: string) => Promise<string>,
}
