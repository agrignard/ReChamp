/***
* Name: ReChamp
* Author: Arnaud Grignard, Nicolas Ayoub
* Description: ReChamp - 2019
* Tags: Tag1, Tag2, TagN
***/

model ReChamp

global {
	file buildings_shapefile <- file("../includes/GIS/buildings.shp");
	file roads_shapefile <- file("../includes/GIS/roads.shp");
	file shape_file_bounds <- file("../includes/GIS/TableBounds.shp");
	geometry shape <- envelope(shape_file_bounds);
	graph the_graph;

	
	init {
		create building from: buildings_shapefile ;
		create road from: roads_shapefile ;
		the_graph <- as_edge_graph(road);
		create people number:1000{
			color<-flip (0.33) ? #blue : (flip(0.33) ? #white : #red);
		}
	}
}

species building {
	string type; 
	rgb color <- #gray  ;
	
	aspect base {
		draw shape color: color ;
	}
}

species road  {
	rgb color <- #gray ;
	aspect base {
		draw shape color: color ;
	}
}

species people skills:[moving]{
	
	rgb color;
	reflex move{
		do wander on:the_graph;
	}
	aspect base {
		draw circle(10#m) color:color  border: #black;
	}
}

experiment ReChamp type: gui {
		
	output {
		display city_display type:opengl background:#black draw_env:false{
			species building aspect: base ;
			species road aspect: base ;
			species people aspect:base;
		}
	}
}