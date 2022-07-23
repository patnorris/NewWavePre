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

import Utils "Utils";

module {
  /* public class Entity(
    _internalId : Text,
    _creator : Principal,
    _owner : Principal,
    _settings : ?EntitySettings.EntitySettings,
    _entityType : EntityType.EntityType,
    _name : ?Text,
    _description : ?Text,
    _keywords : ?[Text],
    _externalId : ?Text,
  ) {
    // Base Entity fields
    var internalId : Text = _internalId; // or Principal
    var creationTimestamp : Nat64 = Nat64.fromNat(Int.abs(Time.now()));
    var creator : Principal = _creator;
    var owner : Principal = _owner;
    var settings : EntitySettings.EntitySettings = switch(_settings) {
      case null { EntitySettings.EntitySettings() };
      case (?customSettings) { customSettings };
    };
    var entityType : EntityType.EntityType = _entityType;
    var name : ?Text = _name;
    var description : ?Text = _description;
    var keywords : ?[Text] = _keywords;
    var externalId : ?Text = _externalId;

    // Base Entity functions

  }; */

  // example to include functions on type object:
  // type Counter = { inc : () -> Nat };
  /* func Counter() : { inc : () -> Nat } =
  object {
    var c = 0;
    public func inc() : Nat { c += 1; c }
  }; */

  public type Entity = {
    internalId : Text;
    creationTimestamp : Nat64;
    creator : Principal;
    owner : Principal;
    settings : EntitySettings.EntitySettings;
    entityType : EntityType.EntityType;
    name : ?Text;
    description : ?Text;
    keywords : ?[Text];
    externalId : ?Text;
    entitySpecificFields : ?Text;
    listOfEntitySpecificFieldKeys : [Text];
    // resolveRepresentedEntity : () -> T; // if possible, generic return value, otherwise probably Text
  };

  public type EntityInitiationObject = {
    _internalId : ?Text;
    _creator : ?Principal;
    _owner : ?Principal;
    _settings : ?EntitySettings.EntitySettings;
    _entityType : EntityType.EntityType;
    _name : ?Text;
    _description : ?Text;
    _keywords : ?[Text];
    _externalId : ?Text;
    _entitySpecificFields : ?Text;
  };

  public func Entity(
    initiationObject : EntityInitiationObject,
    caller : Principal,
  ) : Entity {
    return {
      internalId : Text = switch(initiationObject._internalId) {
        case null { Utils.newUniqueId() };
        case (?customId) { customId };
      };
      creationTimestamp : Nat64 = Nat64.fromNat(Int.abs(Time.now()));
      creator : Principal = switch(initiationObject._creator) {
        case null { caller };
        case (?customCreator) { customCreator };
      };
      owner : Principal = switch(initiationObject._owner) {
        case null { caller };
        case (?customOwner) { customOwner };
      };
      settings : EntitySettings.EntitySettings = switch(initiationObject._settings) {
        case null { EntitySettings.EntitySettings() };
        case (?customSettings) { customSettings };
      };
      entityType : EntityType.EntityType = initiationObject._entityType;
      name : ?Text = initiationObject._name;
      description : ?Text = initiationObject._description;
      keywords : ?[Text] = initiationObject._keywords;
      externalId : ?Text = initiationObject._externalId;
      entitySpecificFields : ?Text = initiationObject._entitySpecificFields;
      listOfEntitySpecificFieldKeys : [Text] = [];
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
