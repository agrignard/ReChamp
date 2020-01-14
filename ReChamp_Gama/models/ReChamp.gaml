  /***
* Name: ReChamp
* Author: Arnaud Grignard, Tri Nguyen-Huu, Nicolas Ayoub 
* Description: ReChamp - 2019
* Tags: Tag1, Tag2, TagN
***/

model ReChamp

global {
	//EXISTING SHAPEFILE (FROM OPENDATA and OPENSTREETMAP)
	file shape_file_bounds <- file("../includes/GIS/TableBounds.shp");
	file buildings_shapefile <- file("../includes/GIS/buildings.shp");
	
	file water_shapefile <- file("../includes/GIS/water.shp");
	file roads_shapefile <- file("../includes/GIS/roads_OSM.shp");
	file nodes_shapefile <- file("../includes/GIS/nodes_OSM.shp");
	file signals_zone_shapefile <- file("../includes/GIS/signals_zone.shp");
	
	file bus_shapefile <- file("../includes/GIS/lignes_bus.shp");
	file metro_shapefile <- file("../includes/GIS/lignes_metro_RER.shp");
	file station_shapefile <- file("../includes/GIS/stations_metro_bus_RER.shp");
	file amenities_shapefile <- file("../includes/GIS/COMMERCE_RESTAURATION_HOTELLERIE.shp");
	file amenities_shop_shapefile <- file("../includes/GIS/COMMERCE_NON_ALIMENTAIRE.shp");
	file bikelane_shapefile <- file("../includes/GIS/reseau-cyclable.shp");
	
	//GENERATED SHAPEFILE (FROM QGIS)
	//INTERVENTION
	file hotspot_shapefile <- file("../includes/GIS/Hotspot.shp");
	file coldspot_shapefile <- file("../includes/GIS/Coldspot.shp");
	file intervention_shapefile <- file("../includes/GIS/Intervention.shp");		
	//MOBILITY
	file Mobility_Now_shapefile <- file("../includes/GIS/PCA_CE_EXP_EXI_MOBILITY.shp");
	file Mobility_Future_shapefile <- file("../includes/GIS/PCA_CE_EXP_PRO_MOBILITY.shp");
	//NATURE
	file Nature_Now_shapefile <- file("../includes/GIS/PCA_CE_EXP_EXI_NATURE.shp");
	file Nature_Future_shapefile <- file("../includes/GIS/PCA_CE_EXP_PRO_NATURE.shp");
	//USAGE
	file Usage_Now_shapefile <- file("../includes/GIS/PCA_CE_EXP_EXI_USAGE.shp");
	file Usage_Future_shapefile <- file("../includes/GIS/PCA_CE_EXP_PRO_USAGE.shp");

	geometry shape <- envelope(shape_file_bounds);
	graph car_graph;
	graph people_graph;
	graph bike_graph;
	graph bus_graph;
	
	graph driving_road_network;
		
	
	float max_dev <- 10.0;
	float fuzzyness <- 1.0;
	float dist_group_traffic_light <- 50.0;
	
	bool showCar parameter: 'Car (c)' category: "Agent" <-true;
	bool showPedestrian parameter: 'Pedestrain (p)' category: "Agent" <-true;
	bool showBike parameter: 'Bike (b)' category: "Agent" <-true;
	
	
	bool wander parameter: 'People Wandering' category: "Agent" <-false;
	bool showBuilding parameter: 'Building (b)' category: "Agent" <-false;
	bool showRoad parameter: 'Road Simu(r)' category: "Agent" <-false;
	
	bool showVizuRoad parameter: 'Road Vizu(q)' category: "Interaction" <-false;
	bool showBikeLane  parameter: 'Bike Lane (v)' category: "Interaction" <-false;
	bool showGreen parameter: 'Green (j)' category: "Interaction" <-true;
	bool showUsage parameter: 'Usage (u)' category: "Interaction" <-true;
	
	bool showBusLane parameter: 'Bus Lane(n)' category: "Mobility" <-false;
	bool showMetroLane parameter: 'Metro Lane (m)' category: "Mobility" <-false;
	bool showStation parameter: 'Station (s)' category: "Mobility" <-false;
	bool showTrafficSignal parameter: 'Traffic signal (t)' category: "Mobility" <-true;
	
	
	bool showWater parameter: 'Water (w)' category: "Parameters" <-false;
	bool showAmenities parameter: 'Amenities (a)' category: "Parameters" <-false;
	bool showBackground <- false parameter: "Background (Space)" category: "Vizu";
	bool randomColor <- false parameter: "Random Color (f):" category: "Vizu";
	bool showGif  parameter: 'Gif (g)' category: "Vizu" <-false;
	bool showHotSpot  parameter: 'HotSpot (h)' category: "Vizu" <-false;
	int currentBackGround <-0;
	list<file> backGrounds <- [file('../includes/PNG/PCA_REF.png'),file('../includes/PNG/PCA_REF.png')];
	list<string> interventionGif0 <- [('../includes/GIF/Etoile/Etoile_0.gif'),('../includes/GIF/Champs/Champs_0.gif'),('../includes/GIF/Palais/Palais_0.gif'),('../includes/GIF/Concorde/Concorde_0.gif')];
    list<string> interventionGif1 <- [('../includes/GIF/Etoile/Etoile_1.gif'),('../includes/GIF/Champs/Champs_1.gif'),('../includes/GIF/Palais/Palais_1.gif'),('../includes/GIF/Concorde/Concorde_1.gif')];
    
	
	string transition0to_1<-'../includes/GIF/Etoile/Etoile_1.gif';
	
	map<string, rgb> metro_colors <- ["1"::rgb("#FFCD00"), "2"::rgb("#003CA6"),"3"::rgb("#837902"), "6"::rgb("#E2231A"),"7"::rgb("#FA9ABA"),"8"::rgb("#E19BDF"),"9"::rgb("#B6BD00"),"12"::rgb("#007852"),"13"::rgb("#6EC4E8"),"14"::rgb("#62259D")];
	map<string, rgb> type_colors <- ["default"::#white,"people"::#white, "car"::rgb(204,0,106),"bike"::rgb(18,145,209), "bus"::rgb(131,191,98)];
	map<string, rgb> voirie_colors <- ["Piste"::#white,"Couloir Bus"::#green, "Couloir mixte bus-vélo"::#red,"Piste cyclable"::#blue];
	
	float angle<-26.25;

	int currentSimuState<-0;
	bool updateSim<-true;
	int nbAgent<-5000;
	map<string,float> mobilityRatio <-["people"::0.3, "car"::0.2,"bike"::0.1, "bus"::0.5];

	map<road,float> proba_use_road;
	list<intersection> input_intersections;
	list<intersection> output_intersections;
	list<intersection> possible_targets; 
	
	
	init {
		//------------------ STATIC AGENT ----------------------------------- //
		create building from: buildings_shapefile with: [depth:float(read ("H_MOY"))];
		create intersection from: nodes_shapefile with: [is_traffic_signal::(read("type") = "traffic_signals"),  is_crossing :: (string(read("crossing")) = "traffic_signals"), group :: int(read("group")), phase :: int(read("phase"))];
		create signals_zone from: signals_zone_shapefile;
		//create road agents using the shapefile and using the oneway column to check the orientation of the roads if there are directed
		create road from: roads_shapefile with: [lanes::int(read("lanes")), oneway::string(read("oneway"))] {
			maxspeed <- (lanes = 1 ? 30.0 : (lanes = 2 ? 50.0 : 70.0)) °km / °h;
			switch oneway {
				match "no" {
					create road {
						lanes <- max([1, int(myself.lanes / 2.0)]);
						shape <- polyline(reverse(myself.shape.points));
						maxspeed <- myself.maxspeed;
						linked_road <- myself;
						myself.linked_road <- self;
					}

					lanes <- int(lanes / 2.0 + 0.5);
				}

				match "-1" {
					shape <- polyline(reverse(shape.points));
				}
			}
		}
		

		//creation of the road network using the road and intersection agents
		driving_road_network <- (as_driving_graph(road, intersection)) ;
			
		
		
		output_intersections <- intersection where (empty(each.roads_out));
		input_intersections <- intersection where (empty(each.roads_in));
		possible_targets <- intersection - input_intersections;
		proba_use_road <- road as_map (each::each.proba_use);
		do check_signals_integrity;
		
		create water from: water_shapefile ;
		create station from: station_shapefile with: [type:string(read ("type"))];

		create hotSpot from:hotspot_shapefile;
		create coldSpot from:coldspot_shapefile;
		
		//------------------- NETWORK -------------------------------------- //
		create metro_line from: metro_shapefile with: [number:string(read ("c_ligne")),nature:string(read ("c_nature"))];
		create bikelane from:bikelane_shapefile{color<-type_colors["bike"];}
		create bus_line from: bus_shapefile{
			color<-type_colors["bus"];
		}
		
		//------------------- AGENT ---------------------------------------- //
		create people number:nbAgent*mobilityRatio["car"]{
		  type <- "car";
		  // location <- any_location_in(one_of(road where (each.mode="car")));
		  	max_speed <- 160 #km / #h;
			vehicle_length <- 10.0 #m;
			right_side_driving <- true;
			proba_lane_change_up <- 0.1 + (rnd(500) / 500);
			proba_lane_change_down <- 0.5 + (rnd(500) / 500);
			location <- one_of(intersection - output_intersections).location;
			security_distance_coeff <- 5 / 9 * 3.6 * (1.5 - rnd(1000) / 1000);
			proba_respect_priorities <- 1.0;// - rnd(200 / 1000);
			proba_respect_stops <- [1.0];
			proba_block_node <- 0.0;
			proba_use_linked_road <- 0.0;
			max_acceleration <- 5 / 3.6;
			speed_coeff <- 1.2 - (rnd(400) / 1000);
		}
		
		//Create Pedestrain
		create pedestrian number:nbAgent*mobilityRatio["people"]{
		  type <- "people";
		  location<-any_location_in(one_of(building));
		}
		
        //Create Bike
	    create bike number:nbAgent*mobilityRatio["bike"]{
	      type <- "bike";
		  location<-any_location_in(one_of(building));	
		}
		
		car_graph <- as_edge_graph(road);
		people_graph <- as_edge_graph(road);
		bike_graph <- as_edge_graph(bikelane);
						
		//Graphical Species (gif loader)
		create graphicWorld from:shape_file_bounds;
		
		//First Intervention (Paris Now)
		create intervention from:intervention_shapefile with: [id::int(read ("id")),type::string(read ("type"))]
		{   gifFile<-interventionGif0[id-1];
			do initialize;
			interventionNumber<-1;
			isActive<-true;
		}
		//Second Intervention (PCA proposal)
		create intervention from:intervention_shapefile with: [id::int(read ("id")),type::string(read ("type"))]
		{   gifFile<-interventionGif1[id-1];
			do initialize;
			interventionNumber<-2;
			isActive<-false;
		}	
		ask intervention {
			ask road overlapping self {
				hot_spot <- true;
			}
		}	
		ask intersection where each.is_traffic_signal{
			if empty(signals_zone overlapping self){
				is_traffic_signal <- false;
			}
		}
		
		do init_traffic_signal;
		map general_speed_map <- road as_map (each::((each.hot_spot ? 1 : 10) * each.shape.perimeter / each.maxspeed));
		driving_road_network <- driving_road_network with_weights general_speed_map;	 
	}
	
	action init_traffic_signal { 
		
		list<intersection> traffic_signals <- intersection where each.is_traffic_signal ;
		list<intersection> to_remove <- traffic_signals where empty(each.roads_in);
		ask to_remove {
			is_traffic_signal <- false;
		}
		traffic_signals <- traffic_signals -to_remove;
		ask traffic_signals {
			stop << [];
		}
		
		
		loop i over: (remove_duplicates(traffic_signals collect(each.group)) - 0) {
			list<intersection> gp <- traffic_signals where(each.group = i);
			rgb col <- rnd_color(255);
			int cpt_init <- rnd(100);
			bool green <- flip(0.5);
			ask gp {
				color_group <- col;
				loop rd over: roads_in {
					ways1 << road(rd);
					if phase = 1 {
						if green{do to_green;}else{do to_red;}
					}else{
						if green{do to_red;}else{do to_green;}
					}
				counter <- cpt_init;	
				}
			}
		}
		
		list<list<intersection>> groupes <- traffic_signals where (each.group = 0) simple_clustering_by_distance dist_group_traffic_light;
		loop gp over: groupes {
			rgb col <- rnd_color(255);
			ask gp {color_group <- col;}
			int cpt_init <- rnd(100);
			bool green <- flip(0.5);
			if (length(gp) = 1) {
				ask (intersection(first(gp))) {
					if (green) {do to_green;} 
					else {do to_red;}
					float ref_angle <- 0.0;
					if (length(roads_in) >= 2) {
						road rd0 <- road(roads_in[0]);
						list<point> pts <- rd0.shape.points;
						ref_angle <- float(last(pts) direction_to rd0.location);
					}
					do compute_crossing(ref_angle);
				}	
			} else {
				point centroide <- mean (gp collect (intersection(each)).location);
				float angle_ref <- centroide direction_to intersection(first(gp)).location;
				bool first <- true;
				float ref_angle <- 0.0;
				ask first(gp where (length(each.roads_in) > 0)) {
					road rd0 <- road(roads_in[0]);
					list<point> pts <- rd0.shape.points;
					ref_angle <- float(last(pts) direction_to rd0.location);
				}
				
				loop si over: gp {
					intersection ns <- intersection(si);
					bool green_si <- green;
					float ang <- abs((centroide direction_to ns.location) - angle_ref);
					if (ang > 45 and ang < 135) or  (ang > 225 and ang < 315) {
						green_si <- not(green_si);
					}
					ask ns {
						counter <- cpt_init;
						
						if (green_si) {do to_green;} 
							else {do to_red;}
						if (not empty(roads_in)) {
							do compute_crossing(ref_angle);
						}
					}	
				}
			}
		}
		ask traffic_signals where (each.group = 0){
			loop rd over: roads_in {
				if not(rd in ways2) {
					ways1 << road(rd);
				}
			}
		} 
	}
	
	reflex updateSimuState when:updateSim=true{
		ask stroller{do die;}
		if (currentSimuState = 0){
			ask vizuRoad where (each.state="future"){
				do die;
			}
			create vizuRoad from: Mobility_Now_shapefile with: [type:string(read ("type"))] {
				state<-"present";
			}
			ask park where (each.state="future"){
				do die;
			}
			create park from: Nature_Now_shapefile {
				state<-"present";
				create stroller number:self.shape.area/1000{
			  		location<-any_location_in(myself.shape);	
			  		myCurrentGarden<-myself;	
				}
			}
			ask culture where (each.state="future"){
				do die;
			}
			create culture from: Usage_Now_shapefile {
				state<-"present";
			}
		}
		if (currentSimuState = 1){
			ask vizuRoad where (each.state="present"){
				do die;
			}
			create vizuRoad from: Mobility_Future_shapefile with: [type:string(read ("type"))] {
				state<-"future";
			}
			ask park where (each.state="present"){
				do die;
			}
			create park from: Nature_Future_shapefile {
				state<-"future";
				create stroller number:self.shape.area/1000{
			  		location<-any_location_in(myself.shape);	
			  		myCurrentGarden<-myself;	
				}
			}
			ask culture where (each.state="present"){
				do die;
			}
			create culture from: Usage_Future_shapefile {
				state<-"future";
			}
		}
		updateSim<-false;
	}
	
	// ne pas effacer ce qui suit, c'est pour des tests tant qu'on risque de modifier les shapefiles
	action check_signals_integrity{
		ask input_intersections where(each.group != 0){
			write "intersection "+self+" from group "+self.group+" is an input intersection";
		}
		ask output_intersections where(each.group != 0){
			write "intersection "+self+" from group "+self.group+" is an output intersection";
		}
	}
}

species culture{
	string state;
	aspect base {
		if(showUsage){
		  draw shape color: #yellow;	
		}  	
	}
}

species vizuRoad{
	string state;
	string type;
	aspect base {
		if(showVizuRoad){
			draw shape color:type_colors[type] width:1;	
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


species park {
	string state;
	string type; 
	rgb color <- #darkgreen  ;
	
	aspect base {
		if(showGreen){
		  draw shape color: #olivedrab ;	
		}	
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



species road  skills: [skill_road]  {
	int id;
	rgb color;
	string mode;
	float proba_use <- 100.0;

	float capacity;		
	string oneway;
	bool hot_spot <- false;
	
	//action (pas jolie jolie) qui change le nombre de voie d'une route.
	action change_number_of_lanes(int new_number) {
		int prev <- lanes;
		lanes <- new_number;
		if prev < new_number {
			list<list<list<agent>>> new_agents_on;
			int nb_seg <- length(agents_on[0]);
			loop i from: 0 to: new_number - 1 {
				if (i < prev) {
					list<list<agent>> ags_per_lanes <- agents_on[i];
					new_agents_on << ags_per_lanes;
				} else {
					list<list<agent>> ags_per_lanes <- [];
					loop times: nb_seg {
						ags_per_lanes << [];
					}
					new_agents_on << ags_per_lanes;
				}	
			}
			agents_on <- new_agents_on;
		} else if prev > new_number {
			list<list<list<agent>>> new_agents_on;
			int nb_seg <- length(agents_on[0]);
			loop i from: 0 to: prev - 1 {
				list<list<agent>> ags_per_lanes <- agents_on[i];
				if (i < new_number) {
					new_agents_on << ags_per_lanes;
				} else {
					loop j from: 0 to: nb_seg -1 {
						list<people> ags <- list<people>(ags_per_lanes[j]);
						ask ags {
							current_lane <- new_number - 1;
							new_agents_on[new_number - 1][segment_index_on_road] << self;
						}
					} 	
				}
			}
			agents_on <- new_agents_on;
		}
	}
	aspect base {
		if(showRoad){
			draw shape color:type_colors["car"] width:1;	
		}
	}
}

species bikelane{
	aspect base {
		if(showBikeLane){
		  draw shape color: color width:1;	
		}	
	}
}


species bus_line{
	rgb color;
	float capacity;
	float capacity_pca;
	aspect base {
		if(showBusLane){
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
		  if(showMetroLane){
		  	if(type="metro"){
		  	  draw circle(20) - circle(16) color:#blue;	
		  	  draw circle(16) color:#white;	
		  	}
		  }
		  if(showBusLane){
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
		if(showMetroLane){
		  draw shape color: metro_colors[number] width:3;	
		}
		
	}
}


species pedestrian skills:[moving]{
	string type;
	reflex move{
		do wander on:people_graph speed:5.0#km/#h;
	}
	aspect base{
		if(showPedestrian){
		 draw square(3#m) color:type_colors[type] rotate: angle;	
		}	
	}
}

species bike skills:[moving]{
	string type;
	reflex move{
		do wander on:people_graph speed:8.0#km/#h;
	}
	aspect base{
		if(showBike){
		 draw square(3#m) color:type_colors[type] rotate: angle;	
		}	
	}
}

species stroller skills:[moving]{
	
	park myCurrentGarden;
		
	reflex strol{
		do wander bounds:myCurrentGarden.shape;
	}
	
	aspect base {
	  if(showPedestrian){
	    draw square(3#m) color:type_colors["people"] rotate: angle;   
	  }
	}
}

species people skills:[advanced_driving]{	
	rgb color;
	point target;
	intersection target_intersection;
	string nationality;
	string profile;
	string aspect;
	string type;
		
	reflex leave when: (type = "car" and final_target = nil) or (type != "car" and target = nil) {
		if (type="car") {
			if (target_intersection != nil and target_intersection in output_intersections) {
				if current_road != nil {
					ask current_road as road {
						do unregister(myself);
					}
				}
				location <- one_of(input_intersections).location;
			}
			target_intersection <- one_of(possible_targets);
			current_path <- compute_path(graph: driving_road_network, target: target_intersection);
		} else {
			target <- any_location_in(one_of(building));
		}
	}
	
	
	reflex move when: (type = "car" and final_target != nil) or (type != "car" and target != nil){	
	  if(type="car"){
	  	if(wander){
	  	  do wander on:car_graph speed:25.0#km/#h proba_edges: proba_use_road ;	
	  	}else{
	  	  do drive;
	  			
	  	}
	  } 
	}
	
	point calcul_loc {
		if (current_road = nil) {
			return location;
		} else {
			float val <- (road(current_road).lanes - current_lane)*3 + 1.0;
			val <- on_linked_road ? -val : val;
			if (val = 0) {
				return location;
			} else {
				return (location + {cos(heading + 90) * val, sin(heading + 90) * val});
			}

		}

	} 
	aspect base {
	  if(showCar){
	     if (type="car"){
	      	 draw rectangle(5#m,10#m) at:wander ? location : calcul_loc() rotate:heading-90 color:type_colors[type];	
	    }else{
	     	draw square(3#m) color:type_colors[type] rotate: angle;
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

species signals_zone{
		aspect base {
			draw shape empty: true  color:#green;		
		}
}

species intersection skills: [skill_road_node] {
	int phase;
	bool is_traffic_signal;
	bool is_crossing;
	int group;
	list<list> stop;
	int time_to_change <- 100;
	int counter <- rnd(time_to_change);
	list<road> ways1;
	list<road> ways2;
	bool is_green;
	rgb color_fire;
	rgb color_group;

	action compute_crossing(float ref_angle) {
		loop rd over: roads_in {
				list<point> pts2 <- road(rd).shape.points;
				float angle_dest <- float(last(pts2) direction_to rd.location);
				float ang <- abs(angle_dest - ref_angle);
				if (ang > 45 and ang < 135) or (ang > 225 and ang < 315) {
					ways2 << road(rd);
				}

			}
		loop rd over: roads_in {
			if not (rd in ways2) {
				ways1 << road(rd);
			}

		}

	}

	action to_green {
		stop[0] <- ways2;
		color_fire <- #green;
		is_green <- true;
	}

	action to_red {
		stop[0] <- ways1;
		color_fire <- #red;
		is_green <- false;
	}

	reflex dynamic_node when: is_traffic_signal {
		counter <- counter + 1;
		if (counter >= time_to_change) {
			counter <- 0;
			if is_green {
				do to_red;
			} else {
				do to_green;
			}

		}

	}

	aspect default {
		if (is_traffic_signal and showTrafficSignal) {
			draw circle(5) color: color_fire;
			draw triangle(5) color: color_group border: #black;
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
		    species building aspect: base;
			species park aspect: base ;
			species culture aspect: base ;
			species water aspect: base;
			species road aspect: base;
			species vizuRoad aspect:base;
			species bus_line aspect: base;
			species metro_line aspect: base;
			species amenities aspect:base;
			species intersection;
			species people aspect:base;
			species pedestrian aspect:base;
			species bike aspect:base;
			species stroller aspect:base;
			species coldSpot aspect:base;
			species station aspect: base;
			species bikelane aspect:base;
			species signals_zone aspect: base;
									
			graphics 'tablebackground'{
				draw geometry(shape_file_bounds) color:#white empty:true;
				draw string("State: " + currentSimuState) rotate:angle at:{400,400} color:#white empty:true;
			}
			
			event["p"] action: {showPedestrian<-!showPedestrian;};
			event["c"] action: {showCar<-!showCar;};
			event["b"] action: {showBike<-!showBike;};
			event["g"] action: {showGif<-!showGif;};
			event["l"] action: {showBuilding<-!showBuilding;};
			event["r"] action: {showRoad<-!showRoad;};
			event["q"] action: {showVizuRoad<-!showVizuRoad;};
			event["v"] action: {showBike<-!showBike;};
			event["m"] action: {showMetroLane<-!showMetroLane;};
			event["n"] action: {showBusLane<-!showBusLane;};
			event["s"] action: {showStation<-!showStation;};
			event["a"] action: {showAmenities<-!showAmenities;};
			event["j"] action: {showGreen<-!showGreen;};
			event["u"] action: {showUsage<-!showUsage;};
			event["w"] action: {showWater<-!showWater;};
			event["f"] action: {randomColor<-!randomColor;};
			event["h"] action: {showHotSpot<-!showHotSpot;};
			event["t"] action: {showTrafficSignal<-!showTrafficSignal;};
			event[" "] action: {showBackground<-!showBackground;};				
			event["0"] action: {if(currentSimuState!=0){currentSimuState<-0;updateSim<-true;}};
			event["1"] action: {if(currentSimuState!=1){currentSimuState<-1;updateSim<-true;}};
		}
	}
}

