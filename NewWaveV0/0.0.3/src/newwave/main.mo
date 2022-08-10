import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import List "mo:base/List";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

import EntityType "entity_type";
//import EntitySettings "entity_settings";
import Entity "entity";
import BridgeEntity "bridge_entity";

import HTTP "./Http";

actor {
// INTERFACE
  public shared ({ caller }) func create_entity(entityToCreate : Entity.EntityInitiationObject) : async Entity.Entity {
    let result = await createEntity(entityToCreate);
    return result;
    // return EntityCreator.create_entity(); throws error (doesn't match expected type) -> TODO: possible to return promise? Would this speed up this canister? e.g. try ... : async (async Entity.Entity)
  };

  public shared query ({ caller }) func get_entity(entityId : Text) : async ?Entity.Entity {
    let result = getEntity(entityId);
    return result;
  };

  public shared ({ caller }) func create_bridge(bridgeToCreate : BridgeEntity.BridgeEntityInitiationObject) : async BridgeEntity.BridgeEntity {
    let result = await createBridge(bridgeToCreate);
    return result;
    // return BridgeCreator.create_bridge(bridgeToCreate); TODO: possible to return promise? Would this speed up this canister?
  };

  public shared query ({ caller }) func get_bridge(entityId : Text) : async ?BridgeEntity.BridgeEntity {
    let result = getBridge(entityId);
    return result;
  };

  public shared query ({ caller }) func get_bridge_ids_by_entity_id(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async [Text] {
    let result = getBridgeIdsByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    return result;
  };

  public shared query ({ caller }) func get_bridges_by_entity_id(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async [BridgeEntity.BridgeEntity] {
    let result = getBridgesByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    return result;
  };

  public shared ({ caller }) func create_entity_and_bridge(entityToCreate : Entity.EntityInitiationObject, bridgeToCreate : BridgeEntity.BridgeEntityInitiationObject) : async (Entity.Entity, BridgeEntity.BridgeEntity) {
    let result = await createEntityAndBridge(entityToCreate, bridgeToCreate);
    return result;
  };

  public shared query ({ caller }) func get_bridged_entities_by_entity_id(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async [Entity.Entity] {
    let result = getBridgedEntitiesByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    return result;
  };

  public shared query ({ caller }) func get_entity_and_bridge_ids(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : async (?Entity.Entity, [Text]) {
    let result = getEntityAndBridgeIds(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    return result;
  };

// HELPER FUNCTIONS
  public shared ({ caller }) func createEntity(entityToCreate : Entity.EntityInitiationObject) : async (Entity.Entity) {
    // TODO: potentially update entityToCreate fields (might vary depending on EntityType)
    // TODO: potentially assign final internal_id to Entity (might vary depending on EntityType)
    let entity : Entity.Entity = Entity.Entity(entityToCreate, caller);
    // stores via entity_type_storage (abstraction over multiple entity_storage_units)
    let result = putEntity(entity.internalId, entity);
    assert(Text.equal(result, entity.internalId));
    return entity;
  };

  stable var entitiesStorageStable : [(Text, Entity.Entity)] = [];
  var entitiesStorage : HashMap.HashMap<Text, Entity.Entity> = HashMap.HashMap(0, Text.equal, Text.hash);

  func putEntity(entityId : Text, entity : Entity.Entity) : Text {
    entitiesStorage.put(entityId, entity);
    return entityId;
  };

  func getEntity(entityId : Text) : ?Entity.Entity {
    let result = entitiesStorage.get(entityId);
    return result;
  };

  public shared ({ caller }) func createBridge(bridgeToCreate : BridgeEntity.BridgeEntityInitiationObject) : async BridgeEntity.BridgeEntity {
    let bridge : BridgeEntity.BridgeEntity = BridgeEntity.BridgeEntity(bridgeToCreate, caller);
    let result = putBridge(bridge);
    return result;
  };

  stable var bridgesStorageStable : [(Text, BridgeEntity.BridgeEntity)] = [];
  var bridgesStorage : HashMap.HashMap<Text, BridgeEntity.BridgeEntity> = HashMap.HashMap(0, Text.equal, Text.hash);

  func putBridge(bridge : BridgeEntity.BridgeEntity) : BridgeEntity.BridgeEntity {
    let result = bridgesStorage.put(bridge.internalId, bridge);
    let bridgeAddedToDirectory = putEntityEntry(bridge);
    assert(Text.equal(bridge.internalId, bridgeAddedToDirectory));
    return bridge;
  };

  type BridgeCategories = { // TODO: define bridge categories, probably import from a dedicated file (BridgeType)
    ownerCreatedBridges : List.List<Text>;
    otherBridges : List.List<Text>;
  };

  stable var pendingFromBridgesStorageStable : [(Text, BridgeCategories)] = [];
  var pendingFromBridgesStorage : HashMap.HashMap<Text, BridgeCategories> = HashMap.HashMap(0, Text.equal, Text.hash);
  stable var pendingToBridgesStorageStable : [(Text, BridgeCategories)] = [];
  var pendingToBridgesStorage : HashMap.HashMap<Text, BridgeCategories> = HashMap.HashMap(0, Text.equal, Text.hash);
  stable var fromBridgesStorageStable : [(Text, BridgeCategories)] = [];
  var fromBridgesStorage : HashMap.HashMap<Text, BridgeCategories> = HashMap.HashMap(0, Text.equal, Text.hash);
  stable var toBridgesStorageStable : [(Text, BridgeCategories)] = [];
  var toBridgesStorage : HashMap.HashMap<Text, BridgeCategories> = HashMap.HashMap(0, Text.equal, Text.hash);

  func putEntityEntry(bridge : BridgeEntity.BridgeEntity) : Text {
    if (bridge.state == #Pending) { // if bridge state is Pending, store accordingly
    // store in pending from storage
      switch(pendingFromBridgesStorage.get(bridge.fromEntityId)) {
        case null {
          // first entry for entityId
          var otherBridgesList = List.nil<Text>();
          otherBridgesList := List.push<Text>(bridge.internalId, otherBridgesList);
          let newEntityEntry : BridgeCategories = {
            ownerCreatedBridges = List.nil<Text>();
            otherBridges = otherBridgesList;
          };
          pendingFromBridgesStorage.put(bridge.fromEntityId, newEntityEntry);     
        };
        case (?entityEntry) {
          // add to existing entry for entityId
          let updatedEntityEntry : BridgeCategories = {
            ownerCreatedBridges = entityEntry.ownerCreatedBridges;
            otherBridges = List.push<Text>(bridge.internalId, entityEntry.otherBridges);
          };
          pendingFromBridgesStorage.put(bridge.fromEntityId, updatedEntityEntry);    
        };
      };
    // store in pending to storage
      switch(pendingToBridgesStorage.get(bridge.toEntityId)) {
        case null {
          // first entry for entityId
          var otherBridgesList = List.nil<Text>();
          otherBridgesList := List.push<Text>(bridge.internalId, otherBridgesList);
          let newEntityEntry : BridgeCategories = {
            ownerCreatedBridges = List.nil<Text>();
            otherBridges = otherBridgesList;
          };
          pendingToBridgesStorage.put(bridge.toEntityId, newEntityEntry);     
        };
        case (?entityEntry) {
          // add to existing entry for entityId
          let updatedEntityEntry : BridgeCategories = {
            ownerCreatedBridges = entityEntry.ownerCreatedBridges;
            otherBridges = List.push<Text>(bridge.internalId, entityEntry.otherBridges);
          };
          pendingToBridgesStorage.put(bridge.toEntityId, updatedEntityEntry);    
        };
      };
    } else {
      // store bridge for entities bridged to and from
      // store in from storage
      switch(fromBridgesStorage.get(bridge.fromEntityId)) {
        case null {
          // first entry for entityId
          var otherBridgesList = List.nil<Text>();
          otherBridgesList := List.push<Text>(bridge.internalId, otherBridgesList);
          let newEntityEntry : BridgeCategories = {
            ownerCreatedBridges = List.nil<Text>();
            otherBridges = otherBridgesList;
          };
          fromBridgesStorage.put(bridge.fromEntityId, newEntityEntry);     
        };
        case (?entityEntry) {
          // add to existing entry for entityId
          let updatedEntityEntry : BridgeCategories = {
            ownerCreatedBridges = entityEntry.ownerCreatedBridges;
            otherBridges = List.push<Text>(bridge.internalId, entityEntry.otherBridges);
          };
          fromBridgesStorage.put(bridge.fromEntityId, updatedEntityEntry);    
        };
      };
    // store in to storage
      switch(toBridgesStorage.get(bridge.toEntityId)) {
        case null {
          // first entry for entityId
          var otherBridgesList = List.nil<Text>();
          otherBridgesList := List.push<Text>(bridge.internalId, otherBridgesList);
          let newEntityEntry : BridgeCategories = {
            ownerCreatedBridges = List.nil<Text>();
            otherBridges = otherBridgesList;
          };
          toBridgesStorage.put(bridge.toEntityId, newEntityEntry);     
        };
        case (?entityEntry) {
          // add to existing entry for entityId
          let updatedEntityEntry : BridgeCategories = {
            ownerCreatedBridges = entityEntry.ownerCreatedBridges;
            otherBridges = List.push<Text>(bridge.internalId, entityEntry.otherBridges);
          };
          toBridgesStorage.put(bridge.toEntityId, updatedEntityEntry);    
        };
      };
    };
    return bridge.internalId;
  };

  func getBridge(entityId : Text) : ?BridgeEntity.BridgeEntity {
    let bridgeToReturn : ?BridgeEntity.BridgeEntity = bridgesStorage.get(entityId);
    return bridgeToReturn;
  };

  func getBridgeIdsByEntityId(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : [Text] {
    var bridgeIdsToReturn = List.nil<Text>();
    if (includeBridgesFromEntity) {
      switch(fromBridgesStorage.get(entityId)) {
        case null {};
        case (?entityEntry) {
          bridgeIdsToReturn := List.append<Text>(bridgeIdsToReturn, entityEntry.otherBridges); // TODO: determine which category's list/categories' lists in entry to return
        };
      };
    };
    if (includeBridgesToEntity) {
      switch(toBridgesStorage.get(entityId)) {
        case null {};
        case (?entityEntry) {
          bridgeIdsToReturn := List.append<Text>(bridgeIdsToReturn, entityEntry.otherBridges); // TODO: determine which category's list/categories' lists in entry to return
        };
      };
    };
    if (includeBridgesPendingForEntity) {
      switch(pendingFromBridgesStorage.get(entityId)) {
        case null {};
        case (?entityEntry) {
          bridgeIdsToReturn := List.append<Text>(bridgeIdsToReturn, entityEntry.otherBridges); // TODO: determine which category's list/categories' lists in entry to return
        };
      };
      switch(pendingToBridgesStorage.get(entityId)) {
        case null {};
        case (?entityEntry) {
          bridgeIdsToReturn := List.append<Text>(bridgeIdsToReturn, entityEntry.otherBridges); // TODO: determine which category's list/categories' lists in entry to return
        };
      };
    };
    return List.toArray<Text>(bridgeIdsToReturn);
  };

  func getBridgesByEntityId(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : [BridgeEntity.BridgeEntity] {
    let bridgeIdsToRetrieve = getBridgeIdsByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    // adapted from https://forum.dfinity.org/t/motoko-sharable-generics/9021/3
    let executingFunctionsBuffer = Buffer.Buffer<?BridgeEntity.BridgeEntity>(bridgeIdsToRetrieve.size());
    for (bridgeId in bridgeIdsToRetrieve.vals()) { 
      executingFunctionsBuffer.add(getBridge(bridgeId)); 
    };
    let collectingResultsBuffer = Buffer.Buffer<BridgeEntity.BridgeEntity>(bridgeIdsToRetrieve.size());
    var i = 0;
    for (bridgeId in bridgeIdsToRetrieve.vals()) {
      switch(executingFunctionsBuffer.get(i)) {
        case null {};
        case (?bridge) { collectingResultsBuffer.add(bridge); };
      };      
      i += 1;
    };
    return collectingResultsBuffer.toArray();
  };

  public shared ({ caller }) func createEntityAndBridge(entityToCreate : Entity.EntityInitiationObject, bridgeToCreate : BridgeEntity.BridgeEntityInitiationObject) : async (Entity.Entity, BridgeEntity.BridgeEntity) {  
    let createdEntity : Entity.Entity = await createEntity(entityToCreate);
    var updatedBridgeToCreate = bridgeToCreate;
    switch(bridgeToCreate._fromEntityId) {
      case ("") {
        updatedBridgeToCreate := {
          _internalId = bridgeToCreate._internalId;
          _creator = bridgeToCreate._creator;
          _owner = bridgeToCreate._owner;
          _settings = bridgeToCreate._settings;
          _entityType = bridgeToCreate._entityType;
          _name = bridgeToCreate._name;
          _description = bridgeToCreate._description;
          _keywords = bridgeToCreate._keywords;
          _externalId = bridgeToCreate._externalId;
          _entitySpecificFields = bridgeToCreate._entitySpecificFields;
          _bridgeType = bridgeToCreate._bridgeType;
          _fromEntityId = createdEntity.internalId; // only field that needs update, rest is peasantry
          _toEntityId = bridgeToCreate._toEntityId;
          _state = bridgeToCreate._state;
        }; 
      };
      case (_) {
        updatedBridgeToCreate := {
          _internalId = bridgeToCreate._internalId;
          _creator = bridgeToCreate._creator;
          _owner = bridgeToCreate._owner;
          _settings = bridgeToCreate._settings;
          _entityType = bridgeToCreate._entityType;
          _name = bridgeToCreate._name;
          _description = bridgeToCreate._description;
          _keywords = bridgeToCreate._keywords;
          _externalId = bridgeToCreate._externalId;
          _entitySpecificFields = bridgeToCreate._entitySpecificFields;
          _bridgeType = bridgeToCreate._bridgeType;
          _fromEntityId = bridgeToCreate._fromEntityId;
          _toEntityId = createdEntity.internalId; // only field that needs update, rest is peasantry
          _state = bridgeToCreate._state;
        };
      };
    };
    let bridgeEntity : BridgeEntity.BridgeEntity = await createBridge(updatedBridgeToCreate);
    return (createdEntity, bridgeEntity);
  };

  func getBridgedEntitiesByEntityId(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : [Entity.Entity] {
    let entityBridges : [BridgeEntity.BridgeEntity] = getBridgesByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
    if (entityBridges.size() == 0) {
      return [];
    };
    let bridgedEntityIds : [var Text] = Array.init<Text>(entityBridges.size(), "");
    var i = 0;
    for (entityBridge in entityBridges.vals()) {
      if (entityBridge.fromEntityId == entityId) {
        bridgedEntityIds[i] := entityBridge.toEntityId;
      } else {
        bridgedEntityIds[i] := entityBridge.fromEntityId;
      };
      i += 1;
    };
    let executingFunctionsBuffer = Buffer.Buffer<?Entity.Entity>(bridgedEntityIds.size());
    for (entityId in bridgedEntityIds.vals()) { 
      executingFunctionsBuffer.add(getEntity(entityId)); 
    };
    let collectingResultsBuffer = Buffer.Buffer<Entity.Entity>(bridgedEntityIds.size());
    i := 0;
    for (entityId in bridgedEntityIds.vals()) {
      switch(executingFunctionsBuffer.get(i)) {
        case null {};
        case (?entity) { collectingResultsBuffer.add(entity); };
      };      
      i += 1;
    };
    let bridgedEntities : [Entity.Entity] = collectingResultsBuffer.toArray();
    return bridgedEntities;
  };

  func getEntityAndBridgeIds(entityId : Text, includeBridgesFromEntity : Bool, includeBridgesToEntity : Bool, includeBridgesPendingForEntity : Bool) : (?Entity.Entity, [Text]) {
    switch(getEntity(entityId)) {
      case null {
        return (null, []);
      };
      case (?entity) { 
        let bridgeIds : [Text] = getBridgeIdsByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
        return (?entity, bridgeIds);
      };
    };
  };

// HTTP interface
  public query func http_request(request : HTTP.Request) : async HTTP.Response {
  // TODO: probably format response bodies to JSON
    //Debug.print(debug_show("http_request test"));
    //Debug.print(debug_show(request));
    if (request.url == "/getEntity") {
      let entityIdInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "entityid") {
          return true;
        } else {
          return false;
        };
      });
      let entityId : Text = switch(entityIdInput) {
        case (?v) { v.1 };
        case null {
          let response = {
            body = Text.encodeUtf8("No EntityId header provided");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
      switch (getEntity(entityId)) {
        case (null) {
          let response = {
            body = Text.encodeUtf8("Invalid EntityId");
            headers = [];
            status_code = 404 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
        case (?entity) {
          let body = Text.encodeUtf8(debug_show(entity));
          let response = {
            body = body;
            headers = [("Content-Type", "text/html; charset=UTF-8"), ("Content-Length", Nat.toText(body.size()))];
            status_code = 200 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
    } else if (request.url == "/getBridge") {
      let bridgeIdInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "bridgeid") {
          return true;
        } else {
          return false;
        };
      });
      let bridgeId : Text = switch(bridgeIdInput) {
        case (?v) { v.1 };
        case null {
          let response = {
            body = Text.encodeUtf8("No BridgeId header provided");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
      switch (getBridge(bridgeId)) {
        case (null) {
          let response = {
            body = Text.encodeUtf8("Invalid BridgeId");
            headers = [];
            status_code = 404 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
        case (?bridge) {
          let body = Text.encodeUtf8(debug_show(bridge));
          let response = {
            body = body;
            headers = [("Content-Type", "text/html; charset=UTF-8"), ("Content-Length", Nat.toText(body.size()))];
            status_code = 200 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
    } else if (request.url == "/getBridgeIdsByEntityId") {
      let entityIdInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "entityid") {
          return true;
        } else {
          return false;
        };
      });
      let entityId : Text = switch(entityIdInput) {
        case (?v) { v.1 };
        case null {
          let response = {
            body = Text.encodeUtf8("No EntityId header provided");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
      // fill variables from corresponding headers
      var includeBridgesFromEntity : Bool = false;
      var includeBridgesToEntity : Bool = false;
      var includeBridgesPendingForEntity : Bool = false;
      for (header in request.headers.vals()) {
        //Debug.print(debug_show("header"));
        //Debug.print(debug_show(header));
        if (header.0 == "includebridgesfromentity") {
          if (header.1 == "true") {
            includeBridgesFromEntity := true;
          }
        } else if (header.0 == "includebridgestoentity") {
          if (header.1 == "true") {
            includeBridgesToEntity := true;
          }
        } else if (header.0 == "includebridgespendingforentity") {
          if (header.1 == "true") {
            includeBridgesPendingForEntity := true;
          }
        }
      };
      let bridgeIds : [Text] = getBridgeIdsByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
      let body = Text.encodeUtf8(debug_show(bridgeIds));
      let response = {
        body = body;
        headers = [("Content-Type", "text/html; charset=UTF-8"), ("Content-Length", Nat.toText(body.size()))];
        status_code = 200 : Nat16;
        streaming_strategy = null;
        upgrade = false;
      };
      return(response);
    } else if (request.url == "/getBridgesByEntityId") {
      let entityIdInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "entityid") {
          return true;
        } else {
          return false;
        };
      });
      let entityId : Text = switch(entityIdInput) {
        case (?v) { v.1 };
        case null {
          let response = {
            body = Text.encodeUtf8("No EntityId header provided");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
      // fill variables from corresponding headers
      var includeBridgesFromEntity : Bool = false;
      var includeBridgesToEntity : Bool = false;
      var includeBridgesPendingForEntity : Bool = false;
      for (header in request.headers.vals()) {
        //Debug.print(debug_show("header"));
        //Debug.print(debug_show(header));
        if (header.0 == "includebridgesfromentity") {
          if (header.1 == "true") {
            includeBridgesFromEntity := true;
          }
        } else if (header.0 == "includebridgestoentity") {
          if (header.1 == "true") {
            includeBridgesToEntity := true;
          }
        } else if (header.0 == "includebridgespendingforentity") {
          if (header.1 == "true") {
            includeBridgesPendingForEntity := true;
          }
        }
      };
      let bridges : [BridgeEntity.BridgeEntity] = getBridgesByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
      let body = Text.encodeUtf8(debug_show(bridges));
      let response = {
        body = body;
        headers = [("Content-Type", "text/html; charset=UTF-8"), ("Content-Length", Nat.toText(body.size()))];
        status_code = 200 : Nat16;
        streaming_strategy = null;
        upgrade = false;
      };
      return(response);
    } else if (request.url == "/getBridgedEntitiesByEntityId") {
      let entityIdInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "entityid") {
          return true;
        } else {
          return false;
        };
      });
      let entityId : Text = switch(entityIdInput) {
        case (?v) { v.1 };
        case null {
          let response = {
            body = Text.encodeUtf8("No EntityId header provided");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
      // fill variables from corresponding headers
      var includeBridgesFromEntity : Bool = false;
      var includeBridgesToEntity : Bool = false;
      var includeBridgesPendingForEntity : Bool = false;
      for (header in request.headers.vals()) {
        //Debug.print(debug_show("header"));
        //Debug.print(debug_show(header));
        if (header.0 == "includebridgesfromentity") {
          if (header.1 == "true") {
            includeBridgesFromEntity := true;
          }
        } else if (header.0 == "includebridgestoentity") {
          if (header.1 == "true") {
            includeBridgesToEntity := true;
          }
        } else if (header.0 == "includebridgespendingforentity") {
          if (header.1 == "true") {
            includeBridgesPendingForEntity := true;
          }
        }
      };
      let bridgedEntities : [Entity.Entity] = getBridgedEntitiesByEntityId(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
      let body = Text.encodeUtf8(debug_show(bridgedEntities));
      let response = {
        body = body;
        headers = [("Content-Type", "text/html; charset=UTF-8"), ("Content-Length", Nat.toText(body.size()))];
        status_code = 200 : Nat16;
        streaming_strategy = null;
        upgrade = false;
      };
      return(response);
    } else if (request.url == "/getEntityAndBridgeIds") {
      let entityIdInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "entityid") {
          return true;
        } else {
          return false;
        };
      });
      let entityId : Text = switch(entityIdInput) {
        case (?v) { v.1 };
        case null {
          let response = {
            body = Text.encodeUtf8("No EntityId header provided");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
      // fill variables from corresponding headers
      var includeBridgesFromEntity : Bool = false;
      var includeBridgesToEntity : Bool = false;
      var includeBridgesPendingForEntity : Bool = false;
      for (header in request.headers.vals()) {
        //Debug.print(debug_show("header"));
        //Debug.print(debug_show(header));
        if (header.0 == "includebridgesfromentity") {
          if (header.1 == "true") {
            includeBridgesFromEntity := true;
          }
        } else if (header.0 == "includebridgestoentity") {
          if (header.1 == "true") {
            includeBridgesToEntity := true;
          }
        } else if (header.0 == "includebridgespendingforentity") {
          if (header.1 == "true") {
            includeBridgesPendingForEntity := true;
          }
        }
      };
      let entityAndBridgeIds : (?Entity.Entity, [Text]) = getEntityAndBridgeIds(entityId, includeBridgesFromEntity, includeBridgesToEntity, includeBridgesPendingForEntity);
      let body = Text.encodeUtf8(debug_show(entityAndBridgeIds));
      let response = {
        body = body;
        headers = [("Content-Type", "text/html; charset=UTF-8"), ("Content-Length", Nat.toText(body.size()))];
        status_code = 200 : Nat16;
        streaming_strategy = null;
        upgrade = false;
      };
      return(response);
    } else {
      return {
        upgrade = true; // ← If this is set, the request will be sent to http_request_update()
        status_code = 200;
        headers = [ ("content-type", "text/plain") ];
        body = "It does not work";
        streaming_strategy = null;
      };
    }
  };

  public shared func http_request_update(request : HTTP.Request) : async HTTP.Response {
    Debug.print(debug_show("http_request_update"));
    Debug.print(debug_show(request));
    if (request.url == "/createEntity") {
      var inputCreator : ?Principal = null;
      var inputOwner : ?Principal = null;
      var inputEntityType : EntityType.EntityType = #Webasset; // must be updated
      var inputName : ?Text = null;
      var inputDescription : ?Text = null;
      var inputKeywords : ?[Text] = null;
      var inputExternalId : ?Text = null;

      let entityTypeInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "entitytype") {
          return true;
        } else {
          return false;
        };
      });
      let entityType : Text = switch(entityTypeInput) {
        case (?v) { v.1 };
        case null {
          let response = {
            body = Text.encodeUtf8("No EntityType header provided");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
      // TODO: text input to EntityType enum must be done better and more scalable
      if (entityType == "webasset") {
        inputEntityType := #Webasset;
      } else if (entityType == "person") {
        inputEntityType := #Person;
      } else if (entityType == "location") {
        inputEntityType := #Location;
      } else {
        let response = {
            body = Text.encodeUtf8("EntityType not supported");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
      };
      for (header in request.headers.vals()) {
        //Debug.print(debug_show("header"));
        //Debug.print(debug_show(header));
        if (header.0 == "creator") {
          inputCreator := ?Principal.fromText(header.1);
        } else if (header.0 == "owner") {
          inputOwner := ?Principal.fromText(header.1);
        } else if (header.0 == "name") {
          inputName := ?header.1;
        } else if (header.0 == "description") {
          inputDescription := ?header.1;
        } else if (header.0 == "keywords") {
          inputKeywords := ?[header.1]; // TODO: each keyword in input string should be one entry in array
        } else if (header.0 == "externalid") {
          inputExternalId := ?header.1;
        }
      };
      let entityInitiationObject : Entity.EntityInitiationObject = {
        _internalId = null; // random id will be assigned
        _creator = inputCreator;
        _owner = inputOwner;
        _settings = null; // TODO: allow specification
        _entityType = inputEntityType;
        _name = inputName;
        _description = inputDescription;
        _keywords = inputKeywords;
        _externalId = inputExternalId;
        _entitySpecificFields = null; // TODO: fill correctly
      };
      let entity : Entity.Entity = await create_entity(entityInitiationObject);
      let body = Text.encodeUtf8(debug_show(entity));
      let response = {
        body = body;
        headers = [("Content-Type", "text/html; charset=UTF-8"), ("Content-Length", Nat.toText(body.size()))];
        status_code = 200 : Nat16;
        streaming_strategy = null;
        upgrade = false;
      };
      return(response);
    } else if (request.url == "/createBridge") {
      var inputCreator : ?Principal = null;
      var inputOwner : ?Principal = null;
      var inputName : ?Text = null;
      var inputDescription : ?Text = null;
      var inputKeywords : ?[Text] = null;
      var inputExternalId : ?Text = null;
      var inputFromEntityId : Text = "";
      var inputToEntityId : Text = "";

      let fromEntityIdInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "fromentityid") {
          return true;
        } else {
          return false;
        };
      });
      inputFromEntityId := switch(fromEntityIdInput) {
        case (?v) {
          switch(getEntity(v.1)) {
            case null {
              let response = {
                body = Text.encodeUtf8("Invalid FromEntityId header provided");
                headers = [];
                status_code = 400 : Nat16;
                streaming_strategy = null;
                upgrade = false;
              };
              return(response);
            };
            case (?entity) { v.1 };
          };
        };
        case null {
          let response = {
            body = Text.encodeUtf8("No FromEntityId header provided");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
      let toEntityIdInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "toentityid") {
          return true;
        } else {
          return false;
        };
      });
      inputToEntityId := switch(toEntityIdInput) {
        case (?v) {
          switch(getEntity(v.1)) {
            case null {
              let response = {
                body = Text.encodeUtf8("Invalid ToEntityId header provided");
                headers = [];
                status_code = 400 : Nat16;
                streaming_strategy = null;
                upgrade = false;
              };
              return(response);
            };
            case (?entity) { v.1 };
          };
        };
        case null {
          let response = {
            body = Text.encodeUtf8("No ToEntityId header provided");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
      for (header in request.headers.vals()) {
        //Debug.print(debug_show("header"));
        //Debug.print(debug_show(header));
        if (header.0 == "creator") {
          inputCreator := ?Principal.fromText(header.1);
        } else if (header.0 == "owner") {
          inputOwner := ?Principal.fromText(header.1);
        } else if (header.0 == "name") {
          inputName := ?header.1;
        } else if (header.0 == "description") {
          inputDescription := ?header.1;
        } else if (header.0 == "keywords") {
          inputKeywords := ?[header.1]; // TODO: each keyword in input string should be one entry in array
        } else if (header.0 == "externalid") {
          inputExternalId := ?header.1;
        }
      };
      let entityInitiationObject : BridgeEntity.BridgeEntityInitiationObject = {
        _internalId = null; // random id will be assigned
        _creator = inputCreator;
        _owner = inputOwner;
        _settings = null; // TODO: allow specification
        _entityType = #BridgeEntity;
        _name = inputName;
        _description = inputDescription;
        _keywords = inputKeywords;
        _externalId = inputExternalId;
        _entitySpecificFields = null; // TODO: fill correctly
        _bridgeType = #OwnerCreated; // TODO: fill appropriately
        _fromEntityId = inputFromEntityId;
        _toEntityId = inputToEntityId;
        _state = ?#Pending; // TODO: fill appropriately
      };
      let entity : BridgeEntity.BridgeEntity = await create_bridge(entityInitiationObject);
      let body = Text.encodeUtf8(debug_show(entity));
      let response = {
        body = body;
        headers = [("Content-Type", "text/html; charset=UTF-8"), ("Content-Length", Nat.toText(body.size()))];
        status_code = 200 : Nat16;
        streaming_strategy = null;
        upgrade = false;
      };
      return(response);
    } else if (request.url == "/createEntityAndBridge") {
      var inputCreator : ?Principal = null;
      var inputOwner : ?Principal = null;
      var inputEntityType : EntityType.EntityType = #Webasset; // must be updated
      var inputName : ?Text = null;
      var inputDescription : ?Text = null;
      var inputKeywords : ?[Text] = null;
      var inputExternalId : ?Text = null;

      let entityTypeInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "entitytype") {
          return true;
        } else {
          return false;
        };
      });
      let entityType : Text = switch(entityTypeInput) {
        case (?v) { v.1 };
        case null {
          let response = {
            body = Text.encodeUtf8("No EntityType header provided");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
      // TODO: text input to EntityType enum must be done better and more scalable
      if (entityType == "webasset") {
        inputEntityType := #Webasset;
      } else if (entityType == "person") {
        inputEntityType := #Person;
      } else if (entityType == "location") {
        inputEntityType := #Location;
      } else {
        let response = {
            body = Text.encodeUtf8("EntityType not supported");
            headers = [];
            status_code = 400 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
      };
      for (header in request.headers.vals()) {
        //Debug.print(debug_show("header"));
        //Debug.print(debug_show(header));
        if (header.0 == "creator") {
          inputCreator := ?Principal.fromText(header.1);
        } else if (header.0 == "owner") {
          inputOwner := ?Principal.fromText(header.1);
        } else if (header.0 == "name") {
          inputName := ?header.1;
        } else if (header.0 == "description") {
          inputDescription := ?header.1;
        } else if (header.0 == "keywords") {
          inputKeywords := ?[header.1]; // TODO: each keyword in input string should be one entry in array
        } else if (header.0 == "externalid") {
          inputExternalId := ?header.1;
        }
      };
      let entityInitiationObject : Entity.EntityInitiationObject = {
        _internalId = null; // random id will be assigned
        _creator = inputCreator;
        _owner = inputOwner;
        _settings = null; // TODO: allow specification
        _entityType = inputEntityType;
        _name = inputName;
        _description = inputDescription;
        _keywords = inputKeywords;
        _externalId = inputExternalId;
        _entitySpecificFields = null; // TODO: fill correctly
      };

      // Bridge initiation object
      var inputBridgeName : ?Text = null;
      var inputBridgeDescription : ?Text = null;
      var inputBridgeKeywords : ?[Text] = null;
      var inputBridgeExternalId : ?Text = null;
      var inputFromEntityId : Text = "";
      var inputToEntityId : Text = "";

      let fromEntityIdInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "fromentityid") {
          return true;
        } else {
          return false;
        };
      });
      let toEntityIdInput : ?HTTP.HeaderField = Array.find<HTTP.HeaderField>(request.headers, func (header) {
        if (header.0 == "toentityid") {
          return true;
        } else {
          return false;
        };
      });
      inputFromEntityId := switch(fromEntityIdInput) {
        case (?v) {
          switch(getEntity(v.1)) {
            case null {
              let response = {
                body = Text.encodeUtf8("Invalid FromEntityId header provided");
                headers = [];
                status_code = 400 : Nat16;
                streaming_strategy = null;
                upgrade = false;
              };
              return(response);
            };
            case (?entity) { v.1 };
          };
        };
        case null {
          inputToEntityId := switch(toEntityIdInput) {
            case (?vTo) {
              switch(getEntity(vTo.1)) {
                case null {
                  let response = {
                    body = Text.encodeUtf8("Invalid ToEntityId header provided");
                    headers = [];
                    status_code = 400 : Nat16;
                    streaming_strategy = null;
                    upgrade = false;
                  };
                  return(response);
                };
                case (?entityTo) { vTo.1 };
              };
            };
            case null {
              let response = {
                body = Text.encodeUtf8("Neither FromEntityId nor ToEntityId header provided");
                headers = [];
                status_code = 400 : Nat16;
                streaming_strategy = null;
                upgrade = false;
              };
              return(response);
            };
          };
          "" // needed to be returned to inputFromEntityId (outer switch)
        };
      };

      for (header in request.headers.vals()) {
        //Debug.print(debug_show("header"));
        //Debug.print(debug_show(header));
        if (header.0 == "creator") {
          inputCreator := ?Principal.fromText(header.1);
        } else if (header.0 == "owner") {
          inputOwner := ?Principal.fromText(header.1);
        } else if (header.0 == "name") {
          inputName := ?header.1;
        } else if (header.0 == "description") {
          inputDescription := ?header.1;
        } else if (header.0 == "keywords") {
          inputKeywords := ?[header.1]; // TODO: each keyword in input string should be one entry in array
        } else if (header.0 == "externalid") {
          inputExternalId := ?header.1;
        }
      };
      let bridgeInitiationObject : BridgeEntity.BridgeEntityInitiationObject = {
        _internalId = null; // random id will be assigned
        _creator = inputCreator; // potentially allow for different, bridge-specific input
        _owner = inputOwner; // potentially allow for different, bridge-specific input
        _settings = null; // TODO: allow specification
        _entityType = #BridgeEntity;
        _name = inputBridgeName;
        _description = inputBridgeDescription;
        _keywords = inputBridgeKeywords;
        _externalId = inputBridgeExternalId;
        _entitySpecificFields = null; // TODO: fill correctly
        _bridgeType = #OwnerCreated; // TODO: fill appropriately
        _fromEntityId = inputFromEntityId;
        _toEntityId = inputToEntityId;
        _state = ?#Pending; // TODO: fill appropriately
      };

      let entityAndBridge : (Entity.Entity, BridgeEntity.BridgeEntity) = await create_entity_and_bridge(entityInitiationObject, bridgeInitiationObject);
      let body = Text.encodeUtf8(debug_show(entityAndBridge));
      let response = {
        body = body;
        headers = [("Content-Type", "text/html; charset=UTF-8"), ("Content-Length", Nat.toText(body.size()))];
        status_code = 200 : Nat16;
        streaming_strategy = null;
        upgrade = false;
      };
      return(response);      
    } else {
      let response = {
        body = Text.encodeUtf8("Not supported");
        headers = [];
        status_code = 404 : Nat16;
        streaming_strategy = null;
        upgrade = false;
      };
      return(response);
    }
  };

// Upgrade Hooks
  system func preupgrade() {
    entitiesStorageStable := Iter.toArray(entitiesStorage.entries());
    bridgesStorageStable := Iter.toArray(bridgesStorage.entries());
    pendingFromBridgesStorageStable := Iter.toArray(pendingFromBridgesStorage.entries());
    pendingToBridgesStorageStable := Iter.toArray(pendingToBridgesStorage.entries());
    fromBridgesStorageStable := Iter.toArray(fromBridgesStorage.entries());
    toBridgesStorageStable := Iter.toArray(toBridgesStorage.entries());
  };

  system func postupgrade() {
    entitiesStorage := HashMap.fromIter(Iter.fromArray(entitiesStorageStable), entitiesStorageStable.size(), Text.equal, Text.hash);
    entitiesStorageStable := [];
    bridgesStorage := HashMap.fromIter(Iter.fromArray(bridgesStorageStable), bridgesStorageStable.size(), Text.equal, Text.hash);
    bridgesStorageStable := [];
    pendingFromBridgesStorage := HashMap.fromIter(Iter.fromArray(pendingFromBridgesStorageStable), pendingFromBridgesStorageStable.size(), Text.equal, Text.hash);
    pendingFromBridgesStorageStable := [];
    pendingToBridgesStorage := HashMap.fromIter(Iter.fromArray(pendingToBridgesStorageStable), pendingToBridgesStorageStable.size(), Text.equal, Text.hash);
    pendingToBridgesStorageStable := [];
    fromBridgesStorage := HashMap.fromIter(Iter.fromArray(fromBridgesStorageStable), fromBridgesStorageStable.size(), Text.equal, Text.hash);
    fromBridgesStorageStable := [];
    toBridgesStorage := HashMap.fromIter(Iter.fromArray(toBridgesStorageStable), toBridgesStorageStable.size(), Text.equal, Text.hash);
    toBridgesStorageStable := [];
  };
};
