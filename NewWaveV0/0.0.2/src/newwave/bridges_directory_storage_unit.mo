import Time "mo:base/Time";
import Int "mo:base/Int";
import Nat64 "mo:base/Nat64";

import Error "mo:base/Error";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import P "mo:base/Prelude";
import Nat32 "mo:base/Nat32";
import Result "mo:base/Result";
import Map "mo:base/RBTree";
import Text "mo:base/Text";
import List "mo:base/List";

import Random "mo:base/Random";
import Blob "mo:base/Blob";

import EntityType "entity_type";
import EntitySettings "entity_settings";
import Entity "entity";
import BridgeEntity "bridge_entity";

// example from: https://github.com/dfinity/examples/blob/master/motoko/classes/src/map/Buckets.mo
actor class BridgesDirectoryStorageUnit(index : Text) {

  type Key = Text;
  type Value = { // TODO: define categories
    ownerCreatedBridges : List.List<Text>;
    otherBridges : List.List<Text>;
  };

  let map = Map.RBTree<Key, Value>(Text.compare);

  /* public func get(k : Key) : async ?Value {
    assert(Text.startsWith(k, #text index));
    map.get(k);
  }; */

  func get(k : Key) : ?Value {
    assert(Text.startsWith(k, #text index));
    map.get(k);
  };

  public func put(k : Key, bridgeId : Text) : async Key {
    assert(Text.startsWith(k, #text index));
    switch(get(k)) {
      case null {
        // first entry for entityId
        var otherBridgesList = List.nil<Text>();
        otherBridgesList := List.push<Text>(bridgeId, otherBridgesList);
        let newEntityEntry : Value = {
          ownerCreatedBridges = List.nil<Text>();
          otherBridges = otherBridgesList;
        };
        map.put(k, newEntityEntry);
        return bridgeId;        
      };
      case (?entityEntry) {
        // add to existing entry for entityId
        let updatedEntityEntry : Value = {
          ownerCreatedBridges = entityEntry.ownerCreatedBridges;
          otherBridges = List.push<Text>(bridgeId, entityEntry.otherBridges);
        };
        map.put(k, updatedEntityEntry);
        return bridgeId;         
      };
    }
  };

  public func getEntityEntry(entityId : Text) : async ?Value {
    let result = get(entityId);
    return result;
  };

  public func putEntityEntry(bridgedEntityId : Text, bridgeId : Text) : async Text {
    let result = await put(bridgedEntityId, bridgeId);
    return result;
  };

};
