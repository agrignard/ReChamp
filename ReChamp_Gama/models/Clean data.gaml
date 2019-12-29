/***
* Name: Cleandata
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Cleandata

global {
	
	shape_file roads_shape_file <- shape_file("../includes/GIS/roads.shp");

	osm_file paris_osm_file <- osm_file("../includes/GIS/paris.pbf", ["highway"::["primary", "secondary", "tertiary"]]);

	shape_file bike_shape_file <- shape_file("../includes/GIS/reseau-cyclable.shp");
	
	geometry shape <- envelope(roads_shape_file);
	
	init {
		//create road from: clean_network(roads_shape_file.contents, 0.0, false,true);
		list<geometry> ggs <- paris_osm_file.contents where (each.perimeter > 0 and (each overlaps world));
		create road from: ggs;
		//create bike_road from: bike_shape_file;
	}

}

species road {
	aspect default {
		draw shape color: #red;
	}
}

species bike_road {
	aspect default {
		draw shape color: #black;
	}
}

experiment Cleandata type: gui {
	output {
		display map {
			species road;
			species bike_road;
		}
	}
}
