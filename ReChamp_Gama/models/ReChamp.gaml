/***
* Name: ReChamp
* Author: Arnaud Grignard, Nicolas Ayoub
* Description: ReChamp - 2019
* Tags: Tag1, Tag2, TagN
***/

model ReChamp

global {
	file buildings_shapefile <- file("../includes/GIS/buildings.shp");
	file green_spaces_shapefile <- file("../includes/GIS/green_space.shp");
	file ilots_shapefile <- file("../includes/GIS/ilots.shp");
	file water_shapefile <- file("../includes/GIS/water.shp");
	file roads_shapefile <- file("../includes/GIS/roads.shp");
	file roads_count_shapefile <- file("../includes/GIS/gksection.shp");
	file shape_file_bounds <- file("../includes/GIS/TableBounds.shp");
	geometry shape <- envelope(shape_file_bounds);
	graph the_graph;
	bool realData<-true;
	
	init {
		create greenSpace from: green_spaces_shapefile ;
		create building from: buildings_shapefile ;
		create ilots from: ilots_shapefile ;
		create water from: water_shapefile ;
		if(realData){
			create road from: roads_count_shapefile with: [capacity:float(read ("assig_lveh"))];
			float maxCap<- max(road collect each.capacity);
			float minCap<- min((road where (each.capacity >0) )collect each.capacity);
			ask road {
				color<-blend(#red, #yellow,(minCap+capacity)/(maxCap-minCap));
				create people number:self.capacity/250{
					location<-any_location_in(myself);
					color<-blend(#red, #yellow,(minCap+myself.capacity)/(maxCap-minCap));	
				}
			}
		}else{
		  create road from: roads_shapefile {
		  	color<-#gray;
		  }	
		  create people number:1000{
			color<-flip (0.33) ? #blue : (flip(0.33) ? #white : #red);
		}	
		}
		
		the_graph <- as_edge_graph(road);
	}
}

species building {
	string type; 
	rgb color <- #gray  ;
	
	aspect base {
		draw shape color: color ;
	}
}

species ilots {
	string type; 
	rgb color <- rgb(175,175,175)  ;
	
	aspect base {
		draw shape color: color ;
	}
}

species greenSpace {
	string type; 
	rgb color <- #gray  ;
	
	aspect base {
		draw shape color: rgb(75,75,75) ;
	}
}

species water {
	string type; 
	rgb color <- rgb(25,25,25)  ;
	
	aspect base {
		draw shape color:color ;
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
		draw circle(10#m) color:color  border: color-50;
	}
}

experiment ReChamp type: gui {
		
	output {
		display city_display type:opengl background:#white draw_env:false{
			species ilots aspect: base refresh:false;
			species building aspect: base refresh:false;
			species greenSpace aspect: base refresh:false;
			species water aspect: base refresh:false;
			species road aspect: base refresh:false;
			species people aspect:base;
		}
	}
}