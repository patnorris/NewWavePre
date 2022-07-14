export const idlFactory = ({ IDL }) => {
  const BridgeState = IDL.Variant({
    'Confirmed' : IDL.Null,
    'Rejected' : IDL.Null,
    'Pending' : IDL.Null,
  });
  const EntitySettings = IDL.Record({});
  const EntityType = IDL.Variant({
    'Webasset' : IDL.Null,
    'BridgeEntity' : IDL.Null,
    'Person' : IDL.Null,
    'Location' : IDL.Null,
  });
  const BridgeType = IDL.Variant({ 'OwnerCreated' : IDL.Null });
  const BridgeEntity = IDL.Record({
    'internalId' : IDL.Text,
    'toEntityId' : IDL.Text,
    'creator' : IDL.Principal,
    'fromEntityId' : IDL.Text,
    'owner' : IDL.Principal,
    'externalId' : IDL.Opt(IDL.Text),
    'creationTimestamp' : IDL.Nat64,
    'name' : IDL.Opt(IDL.Text),
    'description' : IDL.Opt(IDL.Text),
    'keywords' : IDL.Opt(IDL.Vec(IDL.Text)),
    'state' : BridgeState,
    'settings' : EntitySettings,
    'listOfEntitySpecificFieldKeys' : IDL.Vec(IDL.Text),
    'entityType' : EntityType,
    'bridgeType' : BridgeType,
    'entitySpecificFields' : IDL.Opt(IDL.Text),
  });
  return IDL.Service({
    'getEntities' : IDL.Func([IDL.Vec(IDL.Text)], [IDL.Vec(BridgeEntity)], []),
    'getEntity' : IDL.Func([IDL.Text], [IDL.Opt(BridgeEntity)], []),
    'putEntity' : IDL.Func([BridgeEntity], [BridgeEntity], []),
  });
};
export const init = ({ IDL }) => { return []; };