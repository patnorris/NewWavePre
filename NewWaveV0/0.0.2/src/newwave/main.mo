import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";

import EntityType "entity_type";
import EntitySettings "entity_settings";
import Entity "entity";
import BridgeEntity "bridge_entity";
import EntityCreator "canister:entitycreator";
import EntityRetriever "canister:entityretriever";
import BridgeCreator "canister:bridgecreator";
import BridgeRetriever "canister:bridgeretriever";
import EntityAndBridgeCreator "canister:entityandbridgecreator";
import EntityAndBridgeRetriever "canister:entityandbridgeretriever";

// TODO: mark functions as queries (all files) --> no inter-canister queries currently, check back later
// TODO: mark variables as stable (all files)
actor {
  public func greet(name : Text) : async Text {
    return "Hello, " # name # "!";
  };

  public shared ({ caller }) func create_entity(entityToCreate : Entity.EntityInitiationObject) : async Entity.Entity {
    Debug.print("hello newwave");
    let result = await EntityCreator.create_entity(entityToCreate);
    return result;
    // return EntityCreator.create_entity(); throws error (doesn't match expected type) -> TODO: possible to return promise? Would this speed up this canister? e.g. try ... : async (async Entity.Entity)
  };

  public shared ({ caller }) func get_entity(entityId : Text) : async ?Entity.Entity {
    Debug.print("hello newwave get_entity");
    let result = await EntityRetriever.get_entity(entityId);
    return result;
  };

  public shared ({ caller }) func create_bridge(bridgeToCreate : BridgeEntity.BridgeEntityInitiationObject) : async BridgeEntity.BridgeEntity {
    Debug.print("hello newwave create_bridge");
    let result = await BridgeCreator.create_bridge(bridgeToCreate);
    return result;
    // return BridgeCreator.create_bridge(bridgeToCreate); TODO: possible to return promise? Would this speed up this canister?
  };

  public shared ({ caller }) func get_bridge(entityId : Text) : async ?BridgeEntity.BridgeEntity {
    Debug.print("hello newwave get_bridge");
    let result = await BridgeRetriever.get_bridge(entityId);
    return result;
  };

  public shared ({ caller }) func get_bridge_ids_by_entity_id(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async [Text] {
    Debug.print("hello newwave get_bridge_ids_by_entity_id");
    let result = await BridgeRetriever.get_bridge_ids_by_entity_id(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    return result;
  };

  public shared ({ caller }) func get_bridges_by_entity_id(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async [BridgeEntity.BridgeEntity] {
    Debug.print("hello newwave get_bridges_by_entity_id");
    let result = await BridgeRetriever.get_bridges_by_entity_id(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    return result;
  };

  public shared ({ caller }) func create_entity_and_bridge(entityToCreate : Entity.EntityInitiationObject, bridgeToCreate : BridgeEntity.BridgeEntityInitiationObject) : async (Entity.Entity, BridgeEntity.BridgeEntity) {
    Debug.print("hello newwave create_entity_and_bridge");
    let result = await EntityAndBridgeCreator.create_entity_and_bridge(entityToCreate, bridgeToCreate);
    return result;
  };

  public shared ({ caller }) func get_bridged_entities_by_entity_id(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async [Entity.Entity] {
    Debug.print("hello newwave get_bridged_entities_by_entity_id");
    let result = await EntityAndBridgeRetriever.get_bridged_entities_by_entity_id(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    return result;
  };

  public shared ({ caller }) func get_entity_and_bridge_ids(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async (?Entity.Entity, [Text]) {
    Debug.print("hello newwave get_entity_and_bridge_ids");
    let result = await EntityAndBridgeRetriever.get_entity_and_bridge_ids(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    return result;
  };
};
