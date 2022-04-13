export const idlFactory = ({ IDL }) => {
  const Bridge_2 = IDL.Record({
    'internalId' : IDL.Text,
    'toEntityId' : IDL.Text,
    'fromEntityId' : IDL.Text,
  });
  const Entity_2 = IDL.Record({
    'internalId' : IDL.Text,
    'externalId' : IDL.Text,
    'attachedBridgeIds' : IDL.Vec(IDL.Text),
    'name' : IDL.Text,
    'description' : IDL.Text,
    'keywords' : IDL.Vec(IDL.Text),
    'entityType' : IDL.Text,
  });
  return IDL.Service({
    'createBridge' : IDL.Func([Bridge_2], [IDL.Text], []),
    'createEntity' : IDL.Func([Entity_2], [IDL.Text], []),
    'createEntityAndBridge' : IDL.Func([IDL.Text, Entity_2], [IDL.Text], []),
    'getBridgeById' : IDL.Func([IDL.Text], [Bridge_2], ['query']),
    'getBridgedEntitiesForEntityId' : IDL.Func(
        [IDL.Text],
        [IDL.Vec(Entity_2)],
        ['query'],
      ),
    'getEntityByExternalId' : IDL.Func([IDL.Text], [Entity_2], ['query']),
    'getEntityById' : IDL.Func([IDL.Text], [Entity_2], ['query']),
    'searchEntity' : IDL.Func([IDL.Text], [IDL.Opt(Entity_2)], ['query']),
  });
};
export const init = ({ IDL }) => { return []; };
