import Time "mo:base/Time";
import Int "mo:base/Int";
import Nat64 "mo:base/Nat64";
import Debug "mo:base/Debug";

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
import Text "mo:base/Text";
import Char "mo:base/Char";
import Random "mo:base/Random";
import Blob "mo:base/Blob";
import List "mo:base/List";

//import EntityType "entity_type";
import EntitySettings "entity_settings";
import Entity "entity";
import BridgeEntity "bridge_entity";

import BridgesDirectoryStorageUnit "bridges_directory_storage_unit";

actor BridgesPendingDirectory {
  let bridgesFromDirectoryStorageUnits = HashMap.HashMap<Text, BridgesDirectoryStorageUnit.BridgesDirectoryStorageUnit>(0, Text.equal, Text.hash);
  let bridgesToDirectoryStorageUnits = HashMap.HashMap<Text, BridgesDirectoryStorageUnit.BridgesDirectoryStorageUnit>(0, Text.equal, Text.hash);
  let entityIdSubstringForStorageUnitIndexStart = 0;
  let entityIdSubstringForStorageUnitIndexEnd = 2;

  public shared ({ caller }) func putEntityEntry(bridgeId : Text, bridgedFromEntityId : Text, bridgedToEntityId : Text) : async Text {
    Debug.print("hello BridgesPendingDirectory");
    // get correct storageUnitIndex as initial characters from entityId
    let storageUnitIndexFromEntity : Text = extract(bridgedFromEntityId, entityIdSubstringForStorageUnitIndexStart, entityIdSubstringForStorageUnitIndexEnd);
    let storageUnitIndexToEntity : Text = extract(bridgedToEntityId, entityIdSubstringForStorageUnitIndexStart, entityIdSubstringForStorageUnitIndexEnd);
    // stores in correct bridge_directory_storage_unit (according to id)
    let bridgesFromDirectoryStorageUnit : BridgesDirectoryStorageUnit.BridgesDirectoryStorageUnit = switch(bridgesFromDirectoryStorageUnits.get(storageUnitIndexFromEntity)) {
      case null {
        let newBridgesFromDirectoryStorageUnit : BridgesDirectoryStorageUnit.BridgesDirectoryStorageUnit = await BridgesDirectoryStorageUnit.BridgesDirectoryStorageUnit(storageUnitIndexFromEntity);
        bridgesFromDirectoryStorageUnits.put(storageUnitIndexFromEntity, newBridgesFromDirectoryStorageUnit);
        newBridgesFromDirectoryStorageUnit          
      };
      case (?bridgesFromDirectoryStorageUnit) { bridgesFromDirectoryStorageUnit };
    };
    Debug.print("hello BridgesPendingDirectory bridgesFromDirectoryStorageUnit");
    let resultFrom = await bridgesFromDirectoryStorageUnit.putEntityEntry(bridgedFromEntityId, bridgeId);
    let bridgesToDirectoryStorageUnit : BridgesDirectoryStorageUnit.BridgesDirectoryStorageUnit = switch(bridgesToDirectoryStorageUnits.get(storageUnitIndexToEntity)) {
      case null {
        let newBridgesToDirectoryStorageUnit : BridgesDirectoryStorageUnit.BridgesDirectoryStorageUnit = await BridgesDirectoryStorageUnit.BridgesDirectoryStorageUnit(storageUnitIndexToEntity);
        bridgesToDirectoryStorageUnits.put(storageUnitIndexToEntity, newBridgesToDirectoryStorageUnit);
        newBridgesToDirectoryStorageUnit          
      };
      case (?bridgesToDirectoryStorageUnit) { bridgesToDirectoryStorageUnit };
    };
    Debug.print("hello BridgesPendingDirectory bridgesToDirectoryStorageUnit");
    let resultTo = await bridgesToDirectoryStorageUnit.putEntityEntry(bridgedToEntityId, bridgeId);
    Debug.print("hello BridgesPendingDirectory result");
    return resultTo;
  };

  public func getEntityEntries(entityId : Text) : async List.List<Text> {
    let storageUnitIndex : Text = extract(entityId, entityIdSubstringForStorageUnitIndexStart, entityIdSubstringForStorageUnitIndexEnd);
    var bridgeIdsToReturn = switch(bridgesFromDirectoryStorageUnits.get(storageUnitIndex)) {
      case null { List.nil<Text>() };
      case (?bridgesDirectoryStorageUnit) {        
        switch(await bridgesDirectoryStorageUnit.getEntityEntry(entityId)) {
          case null { List.nil<Text>() };
          case (?entityEntry) {
            entityEntry.otherBridges // TODO: determine which category's list/categories' lists in entry to return
          };
        }; 
      };
    };
    bridgeIdsToReturn := List.append<Text>(bridgeIdsToReturn, switch(bridgesToDirectoryStorageUnits.get(storageUnitIndex)) {
      case null { List.nil<Text>() };
      case (?bridgesDirectoryStorageUnit) {        
        switch(await bridgesDirectoryStorageUnit.getEntityEntry(entityId)) {
          case null { List.nil<Text>() };
          case (?entityEntry) {
            entityEntry.otherBridges // TODO: determine which category's list/categories' lists in entry to return
          };
        }; 
      };
    });
    return bridgeIdsToReturn;
  };

  // helper function to extract Substring from String (copied from Text base library)
  private func extract(t : Text, i : Nat, j : Nat) : Text {
    let size = t.size();
    if (i == 0 and j == size) return t;
    assert (j <= size);
    let cs = t.chars();
    var r = "";
    var n = i;
    while (n > 0) {
      ignore cs.next();
      n -= 1;
    };
    n := j;
    while (n > 0) {
      switch (cs.next()) {
        case null { assert false };
        case (?c) { r #= Char.toText(c) }
      };
      n -= 1;
    };
    return r;
  };

};
