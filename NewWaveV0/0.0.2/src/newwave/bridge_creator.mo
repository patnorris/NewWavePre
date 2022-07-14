import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";

import EntityType "entity_type";
import EntitySettings "entity_settings";
import Entity "entity";
import BridgeEntity "bridge_entity";

import BridgeRegistry "canister:bridgeregistry";

actor BridgeCreator {
  public shared ({ caller }) func create_bridge(bridgeToCreate : BridgeEntity.BridgeEntityInitiationObject) : async BridgeEntity.BridgeEntity {
    Debug.print("hello BridgeCreator");
    //Debug.print(bridgeToCreate._internalId);
    let bridge : BridgeEntity.BridgeEntity = BridgeEntity.BridgeEntity(bridgeToCreate, caller);
    Debug.print("BridgeCreator after bridge");
    let result = await BridgeRegistry.putEntity(bridge);
    Debug.print("BridgeCreator after result");
    return result;
  };
};