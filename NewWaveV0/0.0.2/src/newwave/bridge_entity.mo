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

import Random "mo:base/Random";
import Blob "mo:base/Blob";

import EntityType "entity_type";
import EntitySettings "entity_settings";
import Entity "entity";
import BridgeType "bridge_type";
import BridgeState "bridge_state";

module  {
  public type BridgeEntity = Entity.Entity and {
    bridgeType : BridgeType.BridgeType;
    fromEntityId : Text;
    toEntityId : Text;
    state : BridgeState.BridgeState;
  };

  public type BridgeEntityInitiationObject = Entity.EntityInitiationObject and {
    _bridgeType : BridgeType.BridgeType;
    _fromEntityId : Text;
    _toEntityId : Text;
    _state : BridgeState.BridgeState;
  };

  public func BridgeEntity(
    initiationObject : BridgeEntityInitiationObject,
  ) : BridgeEntity { // or Entity.Entity
    return {
      internalId : Text = initiationObject._internalId;
      creationTimestamp : Nat64 = Nat64.fromNat(Int.abs(Time.now()));
      creator : Principal = initiationObject._creator;
      owner : Principal = initiationObject._owner;
      settings : EntitySettings.EntitySettings = switch(initiationObject._settings) {
        case null { EntitySettings.EntitySettings() };
        case (?customSettings) { customSettings };
      };
      entityType : EntityType.EntityType = #BridgeEntity;
      name : ?Text = initiationObject._name;
      description : ?Text = initiationObject._description;
      keywords : ?[Text] = initiationObject._keywords;
      externalId : ?Text = initiationObject._externalId;
      bridgeType : BridgeType.BridgeType = initiationObject._bridgeType;
      fromEntityId : Text = initiationObject._fromEntityId;
      toEntityId : Text = initiationObject._toEntityId;
      state : BridgeState.BridgeState = initiationObject._state;
    }
  };
  
  // 
  /* public func animal_sleep(animal : Animal) : Animal {
    //animal.energy += 10;
    //return animal;
    return {
      specie = animal.specie;
      energy = animal.energy + 10;
    };
  }; */
};
