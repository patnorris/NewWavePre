//import Debug "mo:base/Debug";
//import Principal "mo:base/Principal";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import List "mo:base/List";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Iter "mo:base/Iter";

//import EntityType "entity_type";
//import EntitySettings "entity_settings";
import Entity "entity";
import BridgeEntity "bridge_entity";

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
  /* public query func http_request(request : HTTP.Request) : async HTTP.Response {
    //Debug.print(debug_show("http_request test"));
    //Debug.print(debug_show(request));
    if (request.url == "/getEntity") {
      // TODO
      let item = List.get(nfts, Nat32.toNat(index));
      switch (item) {
        case (null) {
          let response = {
            body = Text.encodeUtf8("Invalid tokenid");
            headers = [];
            status_code = 404 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
        case (?token) {
          let body = token.metadata[0].data;
          let response = {
            body = body;
            headers = [("Content-Type", "image/png"), ("Content-Length", Nat.toText(body.size()))];
            status_code = 200 : Nat16;
            streaming_strategy = null;
            upgrade = false;
          };
          return(response);
        };
      };
    } else if (request.url == "/getBridge") {
    } else if (request.url == "/getBridgeIdsByEntityId") {
    } else if (request.url == "/getBridgesByEntityId") {
    } else if (request.url == "/getBridgedEntitiesByEntityId") {
    } else if (request.url == "/getEntityAndBridgeIds") {
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
    //Debug.print(debug_show("http_request_update"));
    //Debug.print(debug_show(request));
    if (request.url == "/createEntity") { // http request for getOpenGenerationJobs
      // TODO
      let body = Text.encodeUtf8(debug_show(generationJobs));
      let response = {
        body = body;
        headers = [("Content-Type", "text/html; charset=UTF-8"), ("Content-Length", Nat.toText(body.size()))];
        status_code = 200 : Nat16;
        streaming_strategy = null;
        upgrade = false;
      };
      return(response);
    } else if (request.url == "/createBridge") {
    } else if (request.url == "/createEntityAndBridge") {
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
  }; */

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
