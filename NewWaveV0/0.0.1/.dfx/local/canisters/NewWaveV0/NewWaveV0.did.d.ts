import type { Principal } from '@dfinity/principal';
export type Bridge = Bridge_2;
export interface Bridge_2 {
  'internalId' : string,
  'toEntityId' : string,
  'fromEntityId' : string,
}
export type Entity = Entity_2;
export interface Entity_2 {
  'internalId' : string,
  'externalId' : string,
  'attachedBridgeIds' : Array<string>,
  'name' : string,
  'description' : string,
  'keywords' : Array<string>,
  'entityType' : string,
}
export interface _SERVICE {
  'createBridge' : (arg_0: Bridge_2) => Promise<string>,
  'createEntity' : (arg_0: Entity_2) => Promise<string>,
  'createEntityAndBridge' : (arg_0: string, arg_1: Entity_2) => Promise<string>,
  'getBridgeById' : (arg_0: string) => Promise<Bridge_2>,
  'getBridgedEntitiesForEntityId' : (arg_0: string) => Promise<Array<Entity_2>>,
  'getEntityByExternalId' : (arg_0: string) => Promise<Entity_2>,
  'getEntityById' : (arg_0: string) => Promise<Entity_2>,
  'searchEntity' : (arg_0: string) => Promise<[] | [Entity_2]>,
}
