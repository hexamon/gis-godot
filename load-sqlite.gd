extends Node

#License: MIT
#Author: Anton Westholm

#This script constructs meshes from MultiPolygonZ geometries stored as JSON.
#It probably wont work on arbitrary data without some tinkering.

#We need to translate between the spatial coordinate system and Godot's internal.
#Use this origin variable to define where in your CRS the center of your data is.
export var origin : Vector3 = Vector3(0,0,0)

#Load SQLite addon
const SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")

var db

var db_name := "res://byggnader_Anton"

#Executes at start
func _ready():
	
	#Prepare a variable to hold our JSON-geometry
	var jsonGeom : JSONParseResult
	
	#Initialize SQLite addon
	db = SQLite.new()
	
	#Point SQLite addon yo your database. The addon is hard coded to the file extension .db
	db.path = db_name
	
	#Connect to your database.
	db.open_db()

	#Select query to fetch your data
	db.query('SELECT geom_array FROM "byggnader_v2"')
	
	#Read the JSON geometry data.
	jsonGeom = JSON.parse(db.query_result[0]["geom_array"])
	
	#Handle the fetched features.
	parseResults()
	
	#Done!
	db.close_db()

#Iterate through all features to parse the JSON geometry.
func parseResults():
	
	#Populate this with arrays of triangles.
	var features = []
	
	#For every feature
	for r in db.query_result:
		
		#Parse the JSON containing the coordinates
		var jsonCoords = JSON.parse(r["geom_array"])
		
		#Hand off the geometry of this feature to the geometry constructor.
		constructFeature(jsonCoords.result["coords"])

#Geometry constructor function.
func constructFeature(f):
	
	# Initialize the SurfaceTool used to construct the feature geometry.
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#For each polygon in the feature
	for p in f:
		
		#Create an array to hold the vertices of this polygon.
		var vertices = PoolVector3Array()
		
		#For each vertex in the polygon
		for v in p:
			
			#Create a Vector3 from the supplied coordinates
			#Note that Y (v[2]) is vertical!
			var vert = Vector3(v[0],v[2],v[1])
			
			#Translate the coordinate based on the local origin
			vert = vert - origin
			
			#Push the vertex into the vertex array
			vertices.push_back(vert)
		
		st.add_triangle_fan(vertices)
	
	st.generate_normals()
	
	# Create the Mesh.
	var mesh = st.commit()
		
	var m = MeshInstance.new()
	m.mesh = mesh
	m.create_trimesh_collision()
		
	#Add the feature to the scene
	self.add_child(m)
