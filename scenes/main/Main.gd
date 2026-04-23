extends Node
@onready var map = $GridMap

func _ready():
	randomize()
	#map.CreateMapsNamesList()
	#map.CreateMap(map.GetGridValues("Section_1"))
	#map.CreateMap(map.GetGridValues("Section_2"))
	#map.CreateMap(map.GetGridValues("Base"))

func _process(delta):
	print_orphan_nodes()
	#"""
	#for i in range (0,5):	
		#start = Time.get_unix_time_from_system()
		#map.CreateMap(map.GetGridValues(map.ChooseRandomMap()))
		#map.CreateMap(map.GetGridValues("Section_1"))
		#time_executing = Time.get_unix_time_from_system() - start
		#times.append(time_executing)
	#"""
#22.5 0.5 -5.5(-3.5)
