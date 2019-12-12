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
	file voierie_shapefile <- file("../includes/GIS/voirie.shp");
	
	file gksection_shapefile <- file("../includes/GIS/gksection.shp");
	file shape_file_bounds <- file("../includes/GIS/TableBounds.shp");
	file bus_shapefile <- file("../includes/GIS/lignes_bus.shp");
	file metro_shapefile <- file("../includes/GIS/lignes_metro_RER.shp");
	file station_shapefile <- file("../includes/GIS/stations_metro_bus_RER.shp");
	file amenities_shapefile <- file("../includes/GIS/COMMERCE_RESTAURATION_HOTELLERIE.shp");
	file amenities_shop_shapefile <- file("../includes/GIS/COMMERCE_NON_ALIMENTAIRE.shp");
	file pedestrian_shapefile <- file("../includes/GIS/pedestrianZone.shp");
	file bikelane_shapefile <- file("../includes/GIS/reseau-cyclable.shp");
	
	file gamaRaster <- file('../includes/PNG/4k still_proposal.png');

	//file pedestrian_count_file <- csv_file("../includes/PCA_STREAM_KEPLER_MY_TRAFFIC.csv",",",true);

	geometry shape <- envelope(shape_file_bounds);
	graph car_graph;
	graph people_graph;
	graph bike_graph;
	graph bus_graph;
	graph<people, people> interaction_graph;
	bool realData<-true;
	
	float max_dev <- 10.0;
	float fuzzyness <- 1.0;
	
	
	bool showPeople parameter: 'People' category: "Parameters" <-true;
	bool showTrajectory parameter: 'People Trajectory' category: "Parameters" <-false;
	int trajectoryLength <-5 parameter: 'Trajectory length' category: "Parameters" min: 1 max: 100;
	bool showPedestrianCount parameter: 'Pedestrian Count' category: "Parameters" <-true;
	bool showRoad parameter: 'Road' category: "Parameters" <-false;
	bool showBike  parameter: 'Bike Lane' category: "Parameters" <-false;
	bool showPCA parameter: 'PCA' category: "Parameters" <-false;
	bool showBuilding parameter: 'Building' category: "Parameters" <-false;
	bool showVoierie parameter: 'Voierie' category: "Parameters" <-false;
	bool showGreen parameter: 'Green' category: "Parameters" <-true;
	bool showWater parameter: 'Water' category: "Parameters" <-true;
	bool showBus parameter: 'Bus' category: "Parameters" <-false;
	bool showMetro parameter: 'Metro' category: "Parameters" <-false;
	bool showTrace parameter: 'Trace' category: "Parameters" <-false;
	bool showStation parameter: 'Station' category: "Parameters" <-false;
	bool showAmenities parameter: 'Amenities' category: "Parameters" <-false;
	bool showInteraction <- false parameter: "Interaction:" category: "Interaction";
	bool black <- true parameter: "Black:" category: "Vizu";
	bool showBackground <- false parameter: "Background:" category: "Vizu";
	bool randomColor <- false parameter: "Random Color:" category: "Vizu";
	int distance <- 100 parameter: "Distance:" category: "Interaction" min: 1 max: 1000;
	string currentMode parameter: 'Current Mode:' category: 'Mobility' <-"default" among:["default", "car", "bike","people","bus"];
	int currentBackGround <-0;
	list<file> backGrounds <- [file('../includes/PNG/4K still_white.png'),file('../includes/PNG/4k still_proposal.png'),file('../includes/PNG/4k still_existing.png'),file('../includes/PNG/4K still_black.png'),file('../includes/PNG/4k still_B_proposal.png'),file('../includes/PNG/4k still_B_existing.png')];

	map<string, rgb> metro_colors <- ["1"::rgb("#FFCD00"), "2"::rgb("#003CA6"),"3"::rgb("#837902"), "6"::rgb("#E2231A"),"7"::rgb("#FA9ABA"),"8"::rgb("#E19BDF"),"9"::rgb("#B6BD00"),"12"::rgb("#007852"),"13"::rgb("#6EC4E8"),"14"::rgb("#62259D")];
	map<string, rgb> type_colors <- ["default"::#white,"people"::#white, "car"::#red,"bike"::#blue, "bus"::#yellow];
	map<string, rgb> voirie_colors <- ["Piste"::#white,"Couloir Bus"::#green, "Couloir mixte bus-vélo"::#red,"Piste cyclable"::#blue];
	
	float angle<-26.5;
	
	init {
		create greenSpace from: green_spaces_shapefile ;
		create building from: buildings_shapefile with: [depth:float(read ("H_MOY")),date_of_creation:int(read ("AN_CONST"))];
		create gksection from: gksection_shapefile with: [capacity::float(read ("capac_city"))];
		create ilots from: ilots_shapefile ;
		create water from: water_shapefile ;
		create bus_line from: bus_shapefile;
		create station from: station_shapefile with: [type:string(read ("type"))];
		//create voirie from: voierie_shapefile with: [type:string(read ("lib_classe"))];
		create metro_line from: metro_shapefile with: [number:string(read ("c_ligne")),nature:string(read ("c_nature"))];
		create bikelane from:bikelane_shapefile{color<-#blue;}
		create amenities from: amenities_shapefile {
			type<-"restaurant";
			color<-#yellow;
		}
		create amenities from: amenities_shop_shapefile {
			type<-"shop";
			color<-#blue;
		}
		//Create Car
		float maxCap<- max(gksection collect each.capacity);
		float minCap<- min((gksection where (each.capacity >0) )collect each.capacity); 
		ask gksection {
				color<-blend(#red, #green,(minCap+capacity)/(maxCap-minCap));
				create people number:self.capacity/2000{
					type <- "car";
					location<-any_location_in(myself);
				}
		}
		//Create Pedestrain
		create people number:1000{
		  type <- "people";
		  location<-any_location_in(one_of(gksection));
		}
		
        //Create Bike
		ask bikelane{
			create people number:1{
			  type <- "bike";
			  location<-any_location_in(myself);	
			}
		}
		//Create Buus
		ask bus_line{
			create people number:1{
			  type <- "bus";
			  location<-any_location_in(myself);	
			}
		}
		
		ask people{
			val <- rnd(-max_dev,max_dev);
		current_trajectory <- [];
		}
		
		car_graph <- as_edge_graph(gksection);
		people_graph <- as_edge_graph(gksection);
		bike_graph <- as_edge_graph(bikelane);
		bus_graph <- as_edge_graph(bus_line);

		/*create pedestrianZone from:pedestrian_shapefile with:[nbPeople::int(get("COUNT")) , lat::float(get("latitude")), long::float(get("longitude"))]{
			//location<-point(to_GAMA_CRS({long,lat}, "EPSG:4326"));
			if flip(0.95){
				do die;
			}
		}*/	
		//save pedestrianZone to: "../results/pedestrianZone.csv" type:"csv" rewrite: true;
		//save pedestrianZone to:"../results/pedestrianZone.shp" type:"shp" attributes: ["ID":: int(self), "COUNT"::nbPeople];
		
		
		//Graphical Species (gif loader)
		create graphicWorld from:shape_file_bounds;
		create placeEtoile{
			location<-point(to_GAMA_CRS({2.29500000,48.8738}, "EPSG:4326"));
		}
		create concorde{
			location<-point(to_GAMA_CRS({2.3211,48.8655}, "EPSG:4326"));
		}
	}
	reflex updateGraph when: (showInteraction = true) {
		if(currentMode="default"){
		  interaction_graph <- graph<people, people>(people as_distance_graph (distance));	
		}
		if(currentMode="car"){
		  interaction_graph <- graph<people, people>(people where (each.type="car") as_distance_graph (distance));	
		}
		if(currentMode="people"){
		  interaction_graph <- graph<people, people>(people where (each.type="people") as_distance_graph (distance));	
		}
		if(currentMode="bike"){
		  interaction_graph <- graph<people, people>(people where (each.type="bike") as_distance_graph (distance));	
		}
		if(currentMode="bus"){
		  interaction_graph <- graph<people, people>(people where (each.type="bus") as_distance_graph (distance));	
		}
		
	}
}

species building {
	string type; 
	int date_of_creation;
	float depth;
	rgb color <- rgb(75,75,75);
	aspect base {
		if(showBuilding){
		  draw shape color: randomColor ? rnd_color(255): color;	
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

species voirie schedules:[]{
	string type; 
	rgb color <- rgb(175,175,175);
	
	aspect base {
		if(showVoierie){
		  draw shape color:rgb(100,100,100) ;	
		}	
	}
}

species greenSpace {
	string type; 
	rgb color <- #darkgreen  ;
	
	aspect base {
		if(showGreen){
		  draw shape color: rgb(50,50,50) ;	
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
	aspect base {
		if(showRoad){
		  draw shape color: color width:1;	
		}	
	}
}

species bikelane{
	aspect base {
		if(showBike){
		  draw shape color: color width:1;	
		}	
	}
}


species gksection  parent:road{
	float cap24_no_intervention;
	float cap24_pca_intervention;
}
species bus_line{
	rgb color;
	float capacity;
	float capacity_pca;
	aspect base {
		if(showBus){
		  draw shape color: color;	
		}
	}
}

species station{
	rgb color;
	string type;
	float capacity;
	float capacity_pca;
	aspect base {
		if(showStation){
		  if(showMetro){
		  	if(type="metro"){
		  	  draw circle(20) - circle(16) color:#blue;	
		  	  draw circle(16) color:#white;	
		  	}
		  }
		  if(showBus){
		  	if(type="bus"){
		  	  draw circle(20) - circle(16) color:#yellow;	
		  	  draw circle(16) color:#white;		
		  	}
		  }
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
	string type;
	float val ;
	list<point> current_trajectory;
	
	reflex move{
	  if(type="bike"){
	  	do wander on:bike_graph speed:8.0#km/#h;
	  }
	  if(type="bus"){
	    do wander on:bus_graph speed:6.0#km/#h;	
	  }	
	  if(type="car"){
	    do wander on:car_graph speed:25.0#km/#h;	
	  }
	  if(type="people"){
	    do wander on:people_graph speed:5.0#km/#h;	
	  }
	  float val_pt <- val + rnd(-fuzzyness, fuzzyness);
	  point pt <- location + {cos(heading + 90) * val_pt, sin(heading + 90) * val_pt};
	  	  
	  loop while:(length(current_trajectory) > trajectoryLength)
  	  {
      current_trajectory >> first(current_trajectory);
      }
      current_trajectory << pt;
	  
	}
	aspect base {
	  if(showPeople){
	     	
	     if (type="car"){
	     	 draw rectangle(5#m,10#m) rotate:heading-90 color:type_colors[type];	
	     }else{
	     	draw circle(3#m) color:type_colors[type];
	     }   
	  }
	  if(showTrajectory){
	       draw line(current_trajectory) color: type_colors[type];	
	  }
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

species graphicWorld{
	aspect base{
		if(showBackground){
		  draw shape texture:backGrounds[currentBackGround].path;	
		}
	}
}

species placeEtoile{
		aspect base {
			//draw square(500#m) empty:true color:#white rotate:angle;
			draw gif_file("../includes/GIF/testchamps.gif") size: {548,550} rotate:angle;
		}
}

species concorde{
		aspect base {
			draw rectangle(200#m,400#m) empty:true color:#white rotate:angle;
			//draw gif_file("../images/fish3.gif") size: {10,10};
		}
}

experiment ReChamp type: gui autorun:true{
	float minimum_cycle_duration<-0.0125;	
	output {
		display champ type:opengl background:black ? #black: #white draw_env:false fullscreen:1  rotate:angle toolbar:false autosave:false synchronized:true
	    camera_pos: {1803.8563,1528.4784,2339.1708} camera_look_pos: {1803.8563,1528.4376,-1.0E-4} camera_up_vector: {0.0,1.0,0.0}{
	    	species graphicWorld aspect:base position:{0,0,0};
	    	species placeEtoile aspect: base position:{0,0,0};
	    	species concorde aspect: base position:{0,0,0};
	    	
	    	
			species building aspect: base;// transparency:0.5;
			species greenSpace aspect: base ;
			species water aspect: base;
			species road aspect: base;
			species gksection aspect: base;
			species bus_line aspect: base;
			species metro_line aspect: base;
			species amenities aspect:base;
			species people aspect:base trace:showTrace ? 200 :0 fading:true;
			species pedestrianZone aspect:base;
			species station aspect: base;
			species bikelane aspect:base;
			//species voirie aspect:base;
						
			graphics 'tablebackground'{
				draw geometry(shape_file_bounds) color:#white empty:true;
			}
			
			graphics "interaction_graph" {
				if (interaction_graph != nil and (showInteraction = true)) {
					loop eg over: interaction_graph.edges {
						people src <- interaction_graph source_of eg;
						people target <- interaction_graph target_of eg;
						geometry edge_geom <- geometry(eg);
						draw line(edge_geom.points) color: type_colors[currentMode];
					}
				}
			}
			event["p"] action: {showPeople<-!showPeople;};
			event["t"] action: {showTrajectory<-!showTrajectory;};
			event["g"] action: {showBackground<-!showBackground;};
			event["b"] action: {showBuilding<-!showBuilding;};
			event["r"] action: {showRoad<-!showRoad;};
			event["v"] action: {showBike<-!showBike;};
			event["m"] action: {showMetro<-!showMetro;};
			event["n"] action: {showBus<-!showBus;};
			event["s"] action: {showStation<-!showStation;};
			event["a"] action: {showAmenities<-!showAmenities;};
			event["g"] action: {showGreen<-!showGreen;};
			event["w"] action: {showWater<-!showWater;};
			event["i"] action: {showInteraction<-!showInteraction;};
			event["c"] action: {showPedestrianCount<-!showPedestrianCount;};
			event["f"] action: {randomColor<-!randomColor;};
			event[" "] action: {currentBackGround<-currentBackGround mod (length(backGrounds)-1) +1;};
			
			event["0"] action: {currentMode<-"default";};
			event["1"] action: {currentMode<-"car";};
			event["2"] action: {currentMode<-"people";};
			event["3"] action: {currentMode<-"bike";};
			event["4"] action: {currentMode<-"bus";};
			
		}
	}
}

