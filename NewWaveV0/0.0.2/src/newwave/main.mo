import Debug "mo:base/Debug";
import Principal "mo:base/Principal";

import EntityType "entity_type";
import EntitySettings "entity_settings";
import Entity "entity";
import BridgeEntity "bridge_entity";

actor {
  public func greet(name : Text) : async Text {
    return "Hello, " # name # "!";
  };

  public shared ({ caller }) func create_entity() : async Entity.Entity {
    let entity : Entity.Entity = Entity.Entity({
      _internalId = "_internalId";
      _creator = caller;
      _owner = caller;
      _settings = null;
      _entityType = #Webasset;
      _name = ?"_name";
      _description = ?"_description";
      _keywords = ?["_keywords"];
      _externalId = ?"_externalId";
    });
    Debug.print("hello newwave");
    Debug.print(entity.internalId);
    return entity;
  };

  public shared ({ caller }) func create_bridge() : async BridgeEntity.BridgeEntity {
    let bridgeEntity = BridgeEntity.BridgeEntity({
      _internalId = "_internalId";
      _creator = caller;
      _owner = caller;
      _settings = null;
      _entityType = #Webasset;
      _name = ?"_name";
      _description = ?"_description";
      _keywords = ?["_keywords"];
      _externalId = ?"_externalId";
      _bridgeType = #OwnerCreated;
      _fromEntityId = "id1";
      _toEntityId = "id2";
      _state = #Confirmed;
    });
    Debug.print("hello bridgeEntity");
    Debug.print(Principal.toText(bridgeEntity.owner));
    Debug.print(bridgeEntity.fromEntityId);
    return bridgeEntity;
  };

  public shared ({ caller }) func create_entity_and_bridge() : async (Entity.Entity, BridgeEntity.BridgeEntity) {
    let entity : Entity.Entity = await create_entity();
    let bridgeEntity : BridgeEntity.BridgeEntity = await create_bridge();
    Debug.print("create_entity_and_bridge");
    Debug.print(entity.internalId);
    Debug.print(Principal.toText(bridgeEntity.owner));
    Debug.print(bridgeEntity.fromEntityId);
    return (entity, bridgeEntity);
  };
};
