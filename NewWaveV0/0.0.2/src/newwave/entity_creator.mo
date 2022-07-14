import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";

import EntityType "entity_type";
import EntitySettings "entity_settings";
import Entity "entity";
import BridgeEntity "bridge_entity";

import EntityTypeCreator "entity_type_creator";

actor EntityCreator {
  let entityTypeCreators = HashMap.HashMap<Text, EntityTypeCreator.EntityTypeCreator>(0, Text.equal, Text.hash);
  
  public shared ({ caller }) func create_entity(entityToCreate : Entity.EntityInitiationObject) : async (Entity.Entity) {
    Debug.print("hello EntityCreator");
    //Debug.print(entityToCreate._internalId);
    let entityTypeCreator : EntityTypeCreator.EntityTypeCreator = switch(entityTypeCreators.get(debug_show(entityToCreate._entityType))) {
      case null {
        let newEntityTypeCreator : EntityTypeCreator.EntityTypeCreator = await EntityTypeCreator.EntityTypeCreator(entityToCreate._entityType);
        ignore await newEntityTypeCreator.init();
        entityTypeCreators.put(debug_show(entityToCreate._entityType), newEntityTypeCreator);
        newEntityTypeCreator          
      };
      case (?entityTypeCreator) { entityTypeCreator };
    };
    Debug.print("EntityCreator after entityTypeCreator");
    let result = await entityTypeCreator.create_entity(entityToCreate);
    Debug.print("EntityCreator after result");
    return result;
  };
};
