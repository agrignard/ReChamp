  /***
* Name: ReChamp
* Author: Arnaud Grignard, Nicolas Ayoub, Tri Nguyen-Huu
* Description: ReChamp - 2019
* Tags: Tag1, Tag2, TagN
***/

model ReChamp

global {
	file buildings_shapefile <- file("../includes/GIS/buildings.shp");
	file green_spaces_shapefile <- file("../includes/GIS/green_space.shp");
	file water_shapefile <- file("../includes/GIS/water.shp");
	file roads_shapefile <- file("../includes/GIS/roads.shp");
	file voierie_shapefile <- file("../includes/GIS/voirie.shp");
	file hotspot_shapefile <- file("../includes/GIS/Hotspot.shp");
	file coldspot_shapefile <- file("../includes/GIS/Coldspot.shp");
	file intervention_shapefile <- file("../includes/GIS/Intervention.shp");
	
	file gksection_shapefile <- file("../includes/GIS/gksection.shp");
	file shape_file_bounds <- file("../includes/GIS/TableBounds.shp");
	file bus_shapefile <- file("../includes/GIS/lignes_bus.shp");
	file metro_shapefile <- file("../includes/GIS/lignes_metro_RER.shp");
	file station_shapefile <- file("../includes/GIS/stations_metro_bus_RER.shp");
	file amenities_shapefile <- file("../includes/GIS/COMMERCE_RESTAURATION_HOTELLERIE.shp");
	file amenities_shop_shapefile <- file("../includes/GIS/COMMERCE_NON_ALIMENTAIRE.shp");
	file pedestrian_shapefile <- file("../includes/GIS/pedestrianZone.shp");
	file bikelane_shapefile <- file("../includes/GIS/reseau-cyclable.shp");
	
	
	
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
	
	float traffic_density <- 2.0 parameter: 'Traffic Density' category: "Champs Elysées" min:  0.0 max: 5.0;
	int lane_number <- 3 parameter: 'Lanes' category: "Champs Elysées" min:  1 max: 4;
	bool one_way <- false parameter: 'One way'  category: "Champs Elysées";
	
	bool showPeople parameter: 'People' category: "Agent" <-true;
	bool showTrajectory parameter: 'People Trajectory' category: "Agent" <-false;
	int trajectoryLength <-5 parameter: 'Trajectory length' category: "Agent" min: 1 max: 50;
	bool showPedestrianCount;// parameter: 'Pedestrian Count' category: "Parameters" <-true;
	
	bool showRoad parameter: 'Road' category: "Mobility" <-false;
	bool showBike  parameter: 'Bike Lane' category: "Mobility" <-false;
	bool showBuilding parameter: 'Building' category: "Mobility" <-false;
	bool showBus parameter: 'Bus' category: "Mobility" <-false;
	bool showMetro parameter: 'Metro' category: "Mobility" <-false;
	bool showStation parameter: 'Station' category: "Mobility" <-false;
	
	bool showGreen parameter: 'Green' category: "Parameters" <-false;
	bool showWater parameter: 'Water' category: "Parameters" <-false;
	
	bool showAmenities parameter: 'Amenities' category: "Parameters" <-false;
	bool showKiosk parameter: 'Kiosque' category: "Parameters" <-false;
	bool showInteraction <- false parameter: "Interaction:" category: "Interaction";
	bool showBackground <- false parameter: "Background:" category: "Vizu";
	bool randomColor <- false parameter: "Random Color:" category: "Vizu";
	bool showGif  parameter: 'Gif' category: "Vizu" <-false;
	bool showHotSpot  parameter: 'HotSpot' category: "Vizu" <-false;
	int distance <- 100 parameter: "Distance:" category: "Interaction" min: 1 max: 1000;
	string currentMode parameter: 'Current Mode:' category: 'Mobility' <-"default" among:["default", "car", "bike","people","bus"];
	int currentBackGround <-0;
	list<file> backGrounds <- [file('../includes/PNG/PCA_REF.png'),file('../includes/PNG/PCA_REF.png')];
	list<string> interventionGif0 <- [('../includes/GIF/Etoile/Etoile_0.gif'),('../includes/GIF/Champs/Champs_0.gif'),('../includes/GIF/Palais/Palais_0.gif'),('../includes/GIF/Concorde/Concorde_0.gif')];
    list<string> interventionGif1 <- [('../includes/GIF/Etoile/Etoile_1.gif'),('../includes/GIF/Champs/Champs_1.gif'),('../includes/GIF/Palais/Palais_1.gif'),('../includes/GIF/Concorde/Concorde_1.gif')];
    
    
	
	
	
	map<string, rgb> metro_colors <- ["1"::rgb("#FFCD00"), "2"::rgb("#003CA6"),"3"::rgb("#837902"), "6"::rgb("#E2231A"),"7"::rgb("#FA9ABA"),"8"::rgb("#E19BDF"),"9"::rgb("#B6BD00"),"12"::rgb("#007852"),"13"::rgb("#6EC4E8"),"14"::rgb("#62259D")];
	map<string, rgb> type_colors <- ["default"::#white,"people"::#white, "car"::rgb(204,0,106),"bike"::rgb(18,145,209), "bus"::rgb(131,191,98)];
	map<string, rgb> voirie_colors <- ["Piste"::#white,"Couloir Bus"::#green, "Couloir mixte bus-vélo"::#red,"Piste cyclable"::#blue];
	
	float angle<-26.25;
	

	// for lightings
	float CAR_SPACING <- 20.0#m;
	float CAR_SPEED <- 2.0#m/#cycle;
	matrix<float> car_density_var <- [];
	matrix<float> h_shift <- [];
	matrix<float> rand_table <- [];
	
	int currentSimuState<-0;
	int nbAgent<-500;

	
	init {
		//------------------ STATIC AGENT ----------------------------------- //
		create greenSpace from: green_spaces_shapefile ;

		create building from: buildings_shapefile with: [depth:float(read ("H_MOY"))];
		create road from: roads_shapefile with: [id:int(read ("OBJECTID"))]{
			//------- compute coordinates of road segments
			if(id=1968 or id=1580){//only for Champs Elysees avenue
				loop i from: 0 to: length(shape.points)-2{
					add sqrt((shape.points[i+1].x - shape.points[i].x)^2 + (shape.points[i+1].y - shape.points[i].y)^2)+last(cumulated_segments_length) to: cumulated_segments_length;
					if shape.points[i+1].x - shape.points[i].x = 0 {
						if shape.points[i+1].y - shape.points[i].y > 0 {
							add 90 to: segments_angle;
						} else {
							add -90 to: segments_angle;
						}
					} else {
						if shape.points[i+1].x - shape.points[i].x > 0 {
							add atan((shape.points[i+1].y - shape.points[i].y)/(shape.points[i+1].x - shape.points[i].x)) to: segments_angle; 
						} else {
							add atan((shape.points[i+1].y - shape.points[i].y)/(shape.points[i+1].x - shape.points[i].x)) - 180 to: segments_angle;
						}				 
					}
					add {sin(last(segments_angle)), - cos(last(segments_angle))}  to: lane_position_shift;
				}
				car_density_var <- matrix_with({3*int(last(cumulated_segments_length)/CAR_SPACING),4},rnd(1.0)); // the maximum number of lane is harcoded and equal to 4
				h_shift <- matrix_with({3*int(last(cumulated_segments_length)/CAR_SPACING),4},rnd(14.0)); // the maximum number of lane is harcoded and equal to 4
				rand_table <- matrix_with({17+3*int(last(cumulated_segments_length)/CAR_SPACING),4},rnd(1.0)); // the maximum number of lane is harcoded and equal to 4
			}
		}	
		

		create water from: water_shapefile ;
		create station from: station_shapefile with: [type:string(read ("type"))];
		/*create amenities from: amenities_shapefile {
			type<-"restaurant";
			color<-#yellow;
		}
		create amenities from: amenities_shop_shapefile {
			type<-"shop";
			color<-#blue;
		}*/
		create hotSpot from:hotspot_shapefile;
		create coldSpot from:coldspot_shapefile;
		
		//------------------- NETWORK -------------------------------------- //
		create metro_line from: metro_shapefile with: [number:string(read ("c_ligne")),nature:string(read ("c_nature"))];
		create bikelane from:bikelane_shapefile{color<-type_colors["bike"];}
		create bus_line from: bus_shapefile{
			color<-type_colors["bus"];
		}
		
		//------------------- AGENT ---------------------------------------- //
		create people number:nbAgent{
		  type <- "car";
		  location<-any_location_in(one_of(road));
		}
		
		//Create Pedestrain
		create people number:nbAgent{
		  type <- "people";
		  location<-any_location_in(one_of(road));
		}
		
        //Create Bike
	    create people number:nbAgent{
	      type <- "bike";
		  location<-any_location_in(one_of(bikelane));	
		}
		
		//Create Bus
		create people number:nbAgent{
		  type <- "bus";
		  location<-any_location_in(one_of(bus_line));	
	    }
		
		
		ask people{
			val <- rnd(-max_dev,max_dev);
		current_trajectory <- [];
		}
		
		car_graph <- as_edge_graph(road);
		people_graph <- as_edge_graph(road);
		bike_graph <- as_edge_graph(bikelane);
		bus_graph <- as_edge_graph(bus_line);

		/*create pedestrianZone from:pedestrian_shapefile with:[nbPeople::int(get("COUNT")) , lat::float(get("latitude")), long::float(get("longitude")),type::int(get("carte_num")) ]{
			//location<-point(to_GAMA_CRS({long,lat}, "EPSG:4326"));
			if flip(0.5){
				//do die;
			}
		}*/	
		//save pedestrianZone to: "../results/pedestrianZone.csv" type:"csv" rewrite: true;
		//save pedestrianZone to:"../results/pedestrianZone.shp" type:"shp" attributes: ["ID":: int(self), "COUNT"::nbPeople];
		
		
		
		//Create Car
		/*float maxCap<- max(gksection collect each.capacity);
		float minCap<- min((gksection where (each.capacity >0) )collect each.capacity); 
		ask gksection {
				//color<-blend(#red, #green,(minCap+capacity)/(maxCap-minCap));
				color<-type_colors["car"];
				create people number:self.capacity/2000{
					type <- "car";
					location<-any_location_in(myself);
				}
		}*/
		
		
		//Graphical Species (gif loader)
		create graphicWorld from:shape_file_bounds;
		
		//First Intervention
		create intervention from:intervention_shapefile with: [id::int(read ("id")),type::string(read ("type"))]
		{   gifFile<-interventionGif0[id-1];
			do initialize;
			interventionNumber<-1;
			isActive<-true;
		}
		//Second Intervention
		create intervention from:intervention_shapefile with: [id::int(read ("id")),type::string(read ("type"))]
		{   gifFile<-interventionGif1[id-1];
			do initialize;
			interventionNumber<-2;
			isActive<-false;
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
	
	
	reflex updateSimuState{
		if (currentSimuState = 1){
			ask intervention{
				isActive<-false;
			}
			ask intervention where (each.interventionNumber=1){
				isActive<-true;
			}
		}
		if (currentSimuState = 2){
			ask intervention{
				isActive<-false;
			}
			ask intervention where (each.interventionNumber=2){
				isActive<-true;
			}
		}
	}
}

species building {
	string type; 
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
	int id;
	rgb color;

	// attributes for animated lights. Usefull only for Champs Elysees Avenue
//	int ways <- 2; // 1 way traffic or 2 way traffic
	float street_width <- 50.0;
	float capacity;		
	// attributes for animated lights
//	float traffic_density <- 0.0;
	bool oneway <- false;

	int segments_number<-5 ;
//	int aspect_size <-1 ;
	list<float> segments_x <- [];
	list<float> segments_y <- [];
	list<float> segments_length <- [];

	list<float> cumulated_segments_length <- [0.0];
	list<float> segments_angle <- [];
	list<point> lane_position_shift <- []; 
	
	int posmod(int i, int m){// Gama modulo is not the math modulo and is not convenient for negative i. This function is used to replace Gama modulo by math modulo.
		int tmp <- mod(i,m);
		return tmp>=0?tmp:(tmp+m);
	}
	
	aspect base {
		if(showRoad){
			draw shape color:type_colors["car"] width:1;	
		 	if(id=1968 or id=1580){ 		
		 		float lane_spacing <- street_width / ((one_way?1:2)*lane_number);
		 		loop way over: one_way?[1]:[1,-1]{
		 			int car_index <- int(ceil(way * CAR_SPEED * cycle / CAR_SPACING));
			 		int current_segment <- 0;
			 		loop  while: car_index * CAR_SPACING - way * CAR_SPEED * cycle < last(cumulated_segments_length) {
						loop while: cumulated_segments_length[current_segment+1] < car_index * CAR_SPACING - way * CAR_SPEED * cycle {
				 			current_segment <- current_segment + 1;
			 			}
			 			float alpha <- min([car_index * CAR_SPACING - way * CAR_SPEED * cycle, last(cumulated_segments_length) - car_index * CAR_SPACING + way * CAR_SPEED * cycle,200])/200;
						loop i from: 0 to: lane_number - 1 {
							point offset <- lane_position_shift[current_segment]*(i+0.5 + (one_way?-0.5:0)*lane_number)*lane_spacing * way;
							float shift <- (car_index) * CAR_SPACING - way * CAR_SPEED * cycle - cumulated_segments_length[current_segment] + way * h_shift[posmod(car_index,h_shift.columns),i];	 			
				 			point new_point <- shape.points[current_segment]+ {cos (segments_angle[current_segment]), sin (segments_angle[current_segment])}*shift + offset;
			 				if (car_density_var[posmod(car_index,car_density_var.columns),i]< traffic_density/lane_number) {
								draw rectangle(8#m,4#m) at: new_point rotate:segments_angle[current_segment]  color: rgb(70+120*rand_table[posmod(car_index,rand_table.columns),i],61+80*rand_table[posmod(car_index+67,rand_table.columns),i],253,alpha);
							}
						}		 	
						car_index <- car_index + 1;
					}
		 		}
			}
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

species modularBlock{
	aspect base{
		if(showKiosk){
		  draw square(10) color:#white rotate:angle;	
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
	
	reflex move {
	  if(type="bike"){
	  	do wander on:bike_graph speed:8.0#km/#h;
	  }
	  if(type="bus"){
	    do wander on:car_graph speed:6.0#km/#h;	
	  }	
	  if(type="car"){
	    do wander on:car_graph speed:25.0#km/#h;	
	  }
	  if(type="people"){
	    do wander on:people_graph speed:5.0#km/#h;	
	  }
	  float val_pt <- val + rnd(-fuzzyness, fuzzyness);
	  point pt <- location + {cos(heading + 90) * val_pt, sin(heading + 90) * val_pt};
	  	  
	  /*loop while:(length(current_trajectory) > trajectoryLength)
  	  {
      current_trajectory >> first(current_trajectory);
      }
      current_trajectory << pt;*/
	  
	}
	aspect base {
	  if(showPeople){
	     if (type="car"){
	     	 draw rectangle(5#m,10#m) rotate:heading-90 color:type_colors[type];	
	     }else{
	     	draw square(3#m) color:type_colors[type] rotate: angle;
	     }   
	  }
	  if(showTrajectory){
	       draw line(current_trajectory) color: type_colors[type] width:2.5;	
	  }
	}	
}

species pedestrianZone{
		int nbPeople;
		float lat;
		float long;
		int type;
		aspect base {
		if(showPedestrianCount){
		if (type=6){
		  draw circle(10) color: rgb(nbPeople,0,0);		
		} 
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

species intervention{
	bool isActive;
	int interventionNumber;
	int id;
	string type;
	string gifFile;
	float h;
	float w;
	bool fit_to_shape <- true;
	action initialize {
		geometry s <- shape rotated_by (-angle);
		w <- s.width ;
		h <- s.height;
		if not(fit_to_shape) {
			geometry env <- envelope(gif_file(gifFile));
			float coeff_img <- env.width / env.height;
			float coeff_shap <- s.width / s.height;
			if (coeff_img > coeff_shap ) {
				h <- w / coeff_img;
			} 
			else if (coeff_img < coeff_shap ){
				w <- h * coeff_img;
			}
		}
		
			
	}
	aspect base {
			draw shape empty:true color:#white;		
			if(showGif and isActive){
			  draw gif_file(gifFile) size:{w,h} rotate:angle;	
			}
		}
}

species hotSpot{
		aspect base {
			draw shape empty:true color:#white;
		}
}

species coldSpot{
		aspect base {
			if(showHotSpot){
			  draw shape color:rgb(0,0,0,200);	
			}	
		}
}

experiment ReChamp type: gui autorun:true{
	float minimum_cycle_duration<-0.0125;	
	output {
		display champ type:opengl background:#black draw_env:false fullscreen:1  rotate:angle toolbar:false autosave:false synchronized:true
	   	camera_pos: {1770.4355,1602.6887,2837.8093} camera_look_pos: {1770.4355,1602.6392,-0.0014} camera_up_vector: {0.0,1.0,0.0}{
	   	    species graphicWorld aspect:base position:{0,0,0};	    	
	    	species intervention aspect: base position:{0,0,0};
		    species building aspect: base;// transparency:0.5;
			species greenSpace aspect: base ;
			species water aspect: base;
			species road aspect: base;
			species bus_line aspect: base;
			species metro_line aspect: base;
			species amenities aspect:base;
			species people aspect:base;
			species coldSpot aspect:base;
			species pedestrianZone aspect:base;
			species station aspect: base;
			species bikelane aspect:base;
			species modularBlock aspect:base; 
			
			
			//species voirie aspect:base;
						
			graphics 'tablebackground'{
				draw geometry(shape_file_bounds) color:#white empty:true;
				draw string("State: " + currentSimuState) rotate:angle at:{400,400} color:#white empty:true;
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
			event["g"] action: {showGif<-!showGif;};
			event["b"] action: {showBuilding<-!showBuilding;};
			event["r"] action: {showRoad<-!showRoad;};
			event["v"] action: {showBike<-!showBike;};
			event["m"] action: {showMetro<-!showMetro;};
			event["n"] action: {showBus<-!showBus;};
			event["s"] action: {showStation<-!showStation;};
			event["a"] action: {showAmenities<-!showAmenities;};
			event["k"] action: {showKiosk<-!showKiosk;};
			event["j"] action: {showGreen<-!showGreen;};
			event["w"] action: {showWater<-!showWater;};
			event["i"] action: {showInteraction<-!showInteraction;};
			event["c"] action: {showPedestrianCount<-!showPedestrianCount;};
			event["f"] action: {randomColor<-!randomColor;};
			event["h"] action: {showHotSpot<-!showHotSpot;};
			event[" "] action: {showBackground<-!showBackground;};
			
			/*event["0"] action: {currentMode<-"default";};
			event["1"] action: {currentMode<-"car";};
			event["2"] action: {currentMode<-"people";};
			event["3"] action: {currentMode<-"bike";};
			event["4"] action: {currentMode<-"bus";};*/
			
			
			event["0"] action: {lane_number<-4;currentSimuState<-0;};
			event["1"] action: {lane_number<-2;currentSimuState<-1;};
			event["2"] action: {currentSimuState<-2;};
			event["3"] action: {currentSimuState<-3;};
			event["4"] action: {currentSimuState<-4;};
			event["5"] action: {currentSimuState<-5;};
			event["6"] action: {currentSimuState<-6;};
			event["7"] action: {currentSimuState<-7;};
			event["8"] action: {currentSimuState<-8;};
			event["9"] action: {currentSimuState<-9;};


		}
	}
}

