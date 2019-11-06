/***
* Name: ReChamp
* Author: Arnaud Grignard, Nicolas Ayoub
* Description: ReChamp - 2019
* Tags: Tag1, Tag2, TagN
***/

model ReChamp

global {
	file buildings_shapefile <- file("../includes/GIS/buildings.shp");
	file roads_shapefile <- file("../includes/GIS/gksection.shp");
	file shape_file_bounds <- file("../includes/GIS/TableBounds.shp");
	geometry shape <- envelope(roads_shapefile);
	graph the_graph;

	
	init {
		create road from: roads_shapefile with: [capacity:float(read ("assig_lveh"))];
		create building from: buildings_shapefile ;
		the_graph <- as_edge_graph(road);
		float maxCap<- max(road collect each.capacity);
		float minCap<- min((road where (each.capacity >0) )collect each.capacity);
		write minCap;
		ask road {
			color<-blend(#red, #yellow,(minCap+capacity)/(maxCap-minCap));
			create people number:self.capacity/250{
				location<-any_location_in(myself);
				color<-blend(#red, #yellow,(minCap+myself.capacity)/(maxCap-minCap));	
			}
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
	rgb color;
	float capacity;
	aspect base {
		draw shape color: color width:2;
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
		display city_display type:opengl background:#white draw_env:false{
			species building aspect:base;
			species road aspect: base ;
			species people aspect:base;
		}
	}
}