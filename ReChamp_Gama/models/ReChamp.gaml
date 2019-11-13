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
	
	bool showRoad parameter: 'Show Road' category: "Parameters" <-false;
	bool showBuilding parameter: 'Show Building' category: "Parameters" <-true;
	bool showTrace parameter: 'Show Trace' category: "Parameters" <-false;
	bool simOn<-false;
	
	float angle<-26.5;
	
	//FRENCH FLAG
	list<geometry> flag <-[rectangle(shape.width/3,shape.height) at_location {shape.width/6,shape.height/2} rotated_by angle,
		rectangle(shape.width/3,shape.height) at_location {shape.width/3+shape.width/6,shape.height/2} rotated_by angle,
		rectangle(shape.width/3,shape.height) at_location {2*shape.width/3+shape.width/6,shape.height/2} rotated_by angle	
	];
	
	init {
		create greenSpace from: green_spaces_shapefile ;
		create building from: buildings_shapefile with: [depth:float(read ("H_MOY")),date_of_creation:int(read ("AN_CONST"))];
		create ilots from: ilots_shapefile ;
		create water from: water_shapefile ;
		if(realData){
			create road from: roads_count_shapefile with: [capacity:float(read ("assig_lveh"))];
			float maxCap<- max(road collect each.capacity);
			float minCap<- min((road where (each.capacity >0) )collect each.capacity);
			ask road {
				color<-blend(#red, #yellow,(minCap+capacity)/(maxCap-minCap));
				create people number:self.capacity/200{
					location<-any_location_in(myself);
					color<-blend(#red, #yellow,(minCap+myself.capacity)/(maxCap-minCap));
					nationality <- flip(0.3) ? "french" :"foreigner"; 	
				}
			}
		}else{
		  create road from: roads_shapefile {
		  	color<-#white;
		  }	
		  create people number:2000{
			color<-flip (0.33) ? #blue : (flip(0.33) ? #white : #red);
			location<-any_location_in(one_of(road));
			nationality <- flip(0.3) ? "french" :"foreigner"; 	
		}	
		}
		
		the_graph <- as_edge_graph(road);
	}
}

species building {
	string type; 
	int date_of_creation;
	float depth;
	rgb color <- #white  ;
	
	aspect base {
		if(showBuilding){
		  draw shape color: color border:rgb(125,125,125);	
		}
	}
	
	aspect depth {
		draw shape color: color border:rgb(125,125,125) depth:depth;
	}
	
	
	aspect timelaspe{
		if(cycle>date_of_creation and date_of_creation!=0){
		  draw shape color: color border:rgb(125,125,125) depth:depth;	
		}	
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
	rgb color <- #darkgreen  ;
	
	aspect base {
		draw shape color: rgb(75,75,75) ;
	}
	aspect green {
		draw shape color: #darkgreen ;
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
		if(showRoad){
		  draw shape color: color width:3;	
		}
		
	}
}

species people skills:[moving]{	
	rgb color;
	point target;
	string nationality;
	string profile;
	
	reflex move when:simOn{
		do wander on:the_graph speed:10.0;
	}
	aspect base {
		draw circle(4#m) color:#blue  ;
	}
	aspect congestion {
		draw circle(4#m) color:color  ;
	}
	aspect nationality{
		draw circle(4#m) color:(nationality=("french")) ? #blue : #orange  ;
	}	
	aspect french{
		draw circle(4#m) color:self intersects flag[0] ?  #blue : (self intersects flag[1] ? #white : #red) ;
	}
}

experiment ReChamp type: gui autorun:false{
	float minimum_cycle_duration<-0.025;	
	output {
		display city_display type:opengl background:#black draw_env:false rotate:angle fullscreen:true toolbar:false {	
			//species ilots aspect: base ;
			species building aspect: base transparency:0.5;
			species greenSpace aspect: base ;
			species water aspect: base;
			species road aspect: base;
			species people aspect:base trace:showTrace ? 200 :0 fading:true;
			
			graphics 'modelbackground'{
				//draw shape_file_bounds color:#gray;
			}
			
			graphics 'tablebackground'{
				draw geometry(shape_file_bounds)*1.25 color:#white empty:true;
			}
			event["t"] action: {showTrace<-!showTrace;};
			event[" "] action: {simOn<-!simOn;};
			event["b"] action: {showBuilding<-!showBuilding;};
			event["r"] action: {showRoad<-!showRoad;};
		}
	}
}