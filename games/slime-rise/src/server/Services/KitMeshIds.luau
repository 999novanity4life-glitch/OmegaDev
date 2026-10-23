--!strict
-- Mesh asset ids for the Blender lab kit, filled in after the FBX is imported
-- with Studio's 3D Importer (names match KitManifest's `mesh` field).
-- Missing ids make LabKit.kit() return nil, and builders fall back to parts.

local KitMeshIds: { [string]: string } = {}

return KitMeshIds
