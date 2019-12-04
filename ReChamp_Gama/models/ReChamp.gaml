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
	file bus_shapefile <- file("../includes/GIS/lignes_bus.shp");
	file metro_shapefile <- file("../includes/GIS/lignes_metro_RER.shp");
	file station_shapefile <- file("../includes/GIS/stations_metro_bus_RER.shp");
	file amenities_shapefile <- file("../includes/GIS/COMMERCE_RESTAURATION_HOTELLERIE.shp");
	file amenities_shop_shapefile <- file("../includes/GIS/COMMERCE_NON_ALIMENTAIRE.shp");
	file pedestrian_count_file <- csv_file("../includes/PCA_STREAM_KEPLER_MY_TRAFFIC.csv",",",true);
	
	geometry shape <- envelope(shape_file_bounds);
	graph the_graph;
	graph<people, people> interaction_graph;
	bool realData<-true;
	
	bool showPeople parameter: 'People' category: "Parameters" <-true;
	bool showPedestrianCount parameter: 'Pedestrian Count' category: "Parameters" <-true;
	bool showRoad parameter: 'Road' category: "Parameters" <-false;
	bool showPCA parameter: 'PCA' category: "Parameters" <-false;
	bool showBuilding parameter: 'Building' category: "Parameters" <-true;
	bool showGreen parameter: 'Green' category: "Parameters" <-true;
	bool showWater parameter: 'Water' category: "Parameters" <-true;
	bool showBus parameter: 'Bus' category: "Parameters" <-false;
	bool showMetro parameter: 'Metro' category: "Parameters" <-false;
	bool showTrace parameter: 'Trace' category: "Parameters" <-false;
	bool showStation parameter: 'Station' category: "Parameters" <-false;
	bool showAmenities parameter: 'Amenities' category: "Parameters" <-false;
	bool showInteraction <- false parameter: "Interaction:" category: "Interaction";
	bool black <- false parameter: "Black:" category: "Vizu";
	bool randomColor <- false parameter: "Random Color:" category: "Vizu";
	int distance <- 100 parameter: "Distance:" category: "Interaction" min: 1 max: 1000;
	
	map<string, rgb> metro_colors <- ["1"::rgb("#FFCD00"), "2"::rgb("#003CA6"),"3"::rgb("#837902"), "6"::rgb("#E2231A"),"7"::rgb("#FA9ABA"),"8"::rgb("#E19BDF"),"9"::rgb("#B6BD00"),"12"::rgb("#007852"),"13"::rgb("#6EC4E8"),"14"::rgb("#62259D")];
	

	
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
		create bus_line from: bus_shapefile ;
		create station from: station_shapefile ;
		create metro_line from: metro_shapefile with: [number:string(read ("c_ligne")),nature:string(read ("c_nature"))];
		create amenities from: amenities_shapefile {
			type<-"restaurant";
			color<-#yellow;
		}
		create amenities from: amenities_shop_shapefile {
			type<-"shop";
			color<-#blue;
		}
		if(realData){
			//create road from: roads_count_shapefile with: [capacity::float(read ("vol_base")),cap24_no_intervention::float(read ("vol_ref")),cap24_pca_intervention::float(read ("vol_proj"))];
			create road from: roads_count_shapefile with: [capacity::float(read ("capac_city"))];
			float maxCap<- max(road collect each.capacity);
			float minCap<- min((road where (each.capacity >0) )collect each.capacity);
			ask road {
				color<-blend(#red, #yellow,(minCap+capacity)/(maxCap-minCap));
				create people number:self.capacity/2000{
					location<-any_location_in(myself);
					color<-blend(#red, #yellow,(minCap+myself.capacity)/(maxCap-minCap));
					nationality <- flip(0.3) ? "french" :"foreigner"; 
					if flip(0.1){
						location<-any_location_in(one_of(greenSpace));
					}	
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
		
		/*matrix data <- matrix(pedestrian_count_file);
		//loop on the matrix rows (skip the first header line)
		loop i from: 1 to: data.rows -1{
			//loop on the matrix columns
			loop j from: 0 to: data.columns -1{
				write "data rows:"+ i +" colums:" + j + " = " + data[j,i];
			}	
		}*/
		/*create pedestrianZone from:pedestrian_count_file with:[nbPeople::int(get("count")) , lat::float(get("latitude")), long::float(get("longitude"))]{
			write "nbPeople" + nbPeople;
			location<-{lat,long};
			if!(self intersects world.shape){
				do die;
			}
		}*/	
	}
	reflex updateGraph when: (showInteraction = true) {
		interaction_graph <- graph<people, people>(people as_distance_graph (distance));
	}
}

species building {
	string type; 
	int date_of_creation;
	float depth;
	rgb color <- #white  ;
	
	aspect base {
		if(showBuilding){
		  draw shape color: randomColor ? rnd_color(255): (black ? #white : #black) border:rgb(125,125,125);	
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
		if(showGreen){
		  draw shape color: rgb(75,75,75) ;	
		}	
	}
	aspect green {
		draw shape color: #darkgreen ;
	}
}

species amenities{
	string type; 
	rgb color <- #darkgray  ;
	
	aspect base {
		if(showAmenities){
		  draw square(5) color: color ;	
		}
		
	}
}

species water {
	string type; 
	rgb color <- rgb(25,25,25)  ;
	
	aspect base {
		if(showWater){
		  draw shape color:color ;	
		}	
	}
}

species road  {
	rgb color;
	float capacity;
	float cap24_no_intervention;
	float cap24_pca_intervention;
	
	
	aspect base {
		if(showRoad){
		  draw shape color: color width:1;	
		}	
	}
}

species bus_line{
	rgb color;
	float capacity;
	float capacity_pca;
	aspect base {
		if(showBus){
		  draw shape color: color width:3;	
		}
	}
}

species station{
	rgb color;
	float capacity;
	float capacity_pca;
	aspect base {
		if(showStation){
		  draw circle(10) color:#gray;	
		}	
	}
}


species metro_line{
	rgb color;
	float capacity;
	float capacity_pca;
	string number;
	string nature;
	aspect base {
		if(showMetro){
		  draw shape color: metro_colors[number] width:3;	
		}
		
	}
}

species people skills:[moving]{	
	rgb color;
	point target;
	string nationality;
	string profile;
	string aspect;
	
	reflex move{
      do wander on:the_graph speed:5.0;
      //do wander  speed:10.0;
	}
	aspect base {
	  if(showPeople){
	     draw circle(4#m) color:#red  ;	
	  }
	}
	aspect congestion {
	  draw circle(4#m) color:color  ;
	}
	aspect nationality{
	  draw circle(4#m) color:(nationality=("french")) ? #white : #red  ;
	  if(nationality=("french")){
	    draw circle(8#m) - circle(6#m) color:#green;
	  }
	}	
	aspect french{
	  draw circle(4#m) color:self intersects flag[0] ?  #blue : (self intersects flag[1] ? #white : #red) ;
	}
}

species pedestrianZone{
		int nbPeople;
		float lat;
		float long;
		aspect base {
		if(showPedestrianCount){
		  draw circle(10) color: rgb(nbPeople,0,0);	
		}
	}
}

experiment ReChamp type: gui autorun:true{
	float minimum_cycle_duration<-0.0125;	
	output {
		display champ type:opengl background:black ? #black: #white draw_env:false rotate:angle fullscreen:true toolbar:false autosave:false synchronized:true
		camera_pos: {1812.4353,1518.7677,3036.6477} camera_look_pos: {1812.4353,1518.7147,0.0} camera_up_vector: {0.0,1.0,0.0}{	
			//species ilots aspect: base ;
			species building aspect: base;// transparency:0.5;
			species greenSpace aspect: base ;
			species water aspect: base;
			species road aspect: base;
			species bus_line aspect: base;
			species station aspect: base;
			species metro_line aspect: base;
			species amenities aspect:base;
			species people aspect:base trace:showTrace ? 200 :0 fading:true;
			species pedestrianZone aspect:base;
			
			
			graphics 'tablebackground'{
				draw geometry(shape_file_bounds)*1.25 color:#white empty:true;
				draw string("Share of low income")  at: { 0#px, world.shape.height*0.95 } color: #white font: font("Helvetica", 32);
			}
			
			graphics "interaction_graph" {
				if (interaction_graph != nil and (showInteraction = true)) {
					loop eg over: interaction_graph.edges {
						people src <- interaction_graph source_of eg;
						people target <- interaction_graph target_of eg;
						geometry edge_geom <- geometry(eg);
						draw line(edge_geom.points) color: #gray;
					}

				}

			}
			event["p"] action: {showPeople<-!showPeople;};
			event["t"] action: {showTrace<-!showTrace;};
			event["b"] action: {showBuilding<-!showBuilding;};
			event["r"] action: {showRoad<-!showRoad;};
			event["m"] action: {showMetro<-!showMetro;};
			event["n"] action: {showBus<-!showBus;};
			event["s"] action: {showStation<-!showStation;};
			event["a"] action: {showAmenities<-!showAmenities;};
			event["g"] action: {showGreen<-!showGreen;};
			event["w"] action: {showWater<-!showWater;};
			event["i"] action: {showInteraction<-!showInteraction;};
			event[" "] action: {black<-!black;};
			event["f"] action: {randomColor<-!randomColor;};
			
			
			
			graphics 'frame'{
				//draw geometry(shape_file_bounds)*1.25 - geometry(shape_file_bounds) color:#black;
			}			
		}
	}
}

experiment Ep1 type: gui autorun:false parent:ReChamp{
	output {
		display city_display type:java2D background:#white draw_env:false rotate:angle fullscreen:true toolbar:false parent:champ{
			species people aspect:base;	
		}
	}
}