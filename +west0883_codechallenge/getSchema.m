function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'west0883_codechallenge', 'west0883_codechallenge');
end
obj = schemaObject;
end
