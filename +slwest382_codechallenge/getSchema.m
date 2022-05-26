function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'slwest382_codechallenge', 'slwest382_codechallenge');
end
obj = schemaObject;
end
