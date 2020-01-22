  /***
* Name: ReChamp
* Author: Arnaud Grignard, Tri Nguyen-Huu, Patrick Taillandier, Nicolas Ayoub 
* Description: ReChamp - 2019
* Tags: Tag1, Tag2, TagN
***/

model ReChamp

global {
	
	int chrono_size <- 30;
	bool fps_monitor <- true;
	float m_time;
	list<float> chrono <- list_with(chrono_size,0.0);
	
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
	file bikelane_shapefile <- file("../includes/GIS/reseau-cyclable_reconnected.shp");
	
	//GENERATED SHAPEFILE (FROM QGIS)
	//INTERVENTION
	file coldspot_shapefile <- file("../includes/GIS/Coldspot.shp");
	file intervention_shapefile <- file("../includes/GIS/Intervention.shp");		
	//MOBILITY
	file Mobility_Now_shapefile <- file("../includes/GIS/PCA_CE_EXP_EXI_MOBILITY_ABSTRACT.shp");
	file Mobility_Future_shapefile <- file("../includes/GIS/PCA_CE_EXP_PRO_MOBILITY_ABSTRACT.shp");
	//NATURE
	file Nature_Now_shapefile <- file("../includes/GIS/PCA_CE_EXP_EXI_NATURE.shp");
	file Nature_Future_shapefile <- file("../includes/GIS/PCA_CE_EXP_PRO_NATURE.shp");
	//USAGE
	file Usage_Now_shapefile <- file("../includes/GIS/PCA_CE_EXP_EXI_USAGE.shp");
	file Usage_Future_shapefile <- file("../includes/GIS/PCA_CE_EXP_PRO_USAGE.shp");

	file Waiting_line_shapefile <- shape_file("../includes/GIS/Waiting_line.shp");

	geometry shape <- envelope(shape_file_bounds);
	graph people_graph;
	graph bike_graph;
	graph bus_graph;
	
	graph driving_road_network;
	
	float max_dev <- 10.0;
	float fuzzyness <- 1.0;
	float dist_group_traffic_light <- 50.0;

	
	bool showCar parameter: 'Car (c)' category: "Agent" <-true;

	bool showRoad parameter: 'Road Simu(r)' category: "Parameters" <-false;
		
	bool precomp parameter: 'Precomp' category: "Agent" <-false;
	bool precompv parameter: 'Precomp version 2' category: "Agent" <-true;
	bool showVizuRoad parameter: 'Mobility(m)' category: "Infrastructure" <-true;
	bool showGreen  <-true;
	bool showUsage <-true;

	
	bool showCarTrajectory parameter: 'Car Trajectory' category: "Trajectory" <-true;
		
	
	int peopleTrajectoryLength <-25 parameter: 'People Trajectory length' category: "Trajectory" min: 0 max: 50;
	int carTrajectoryLength <-25 parameter: 'Car Trajectory length' category: "Trajectory" min: 0 max: 50;
	int bikeTrajectoryLength <-25 parameter: 'Bike Trajectory length' category: "Trajectory" min: 0 max: 50;
	int busTrajectoryLength <-25 parameter: 'Bus Trajectory length' category: "Trajectory" min: 0 max: 50;
	
	
	
	bool smoothTrajectory parameter: 'Smooth Trajectory' category: "Trajectory" <-true;
	float trajectoryTransparency <-0.5 parameter: 'Trajectory transparency' category: "Trajectory" min: 0.0 max: 1.0;
	
	
	bool showWater parameter: 'Water (w)' category: "Parameters" <-false;
	bool showWaitingLine parameter: 'Waiting Line (x)' category: "Parameters" <-false;
	bool showAmenities parameter: 'Amenities (a)' category: "Parameters" <-false;
	bool showIntervention parameter: 'Intervention (i)' category: "Parameters" <-false;
	bool showBackground <- false parameter: "Background (Space)" category: "Parameters";
	float dotPoint <-2.0#m parameter: 'Dot size' category: "Parameters" min: 0.5#m max: 5.0#m;
	
	
	bool showGif  parameter: 'Gif (g)' category: "Parameters" <-false;
	bool showHotSpot  parameter: 'HotSpot (h)' category: "Parameters" <-false;
	int currentBackGround <-0;
	list<file> backGrounds <- [file('../includes/PNG/PCA_REF.png'),file('../includes/PNG/PCA_REF.png')];
	file dashboardbackground <- file('../includes/PNG/dashboardtest.png');
	list<string> interventionGif0 <- [('../includes/GIF/Etoile/Etoile_0.gif'),('../includes/GIF/Champs/Champs_0.gif'),('../includes/GIF/Palais/Palais_0.gif'),('../includes/GIF/Concorde/Concorde_0.gif')];
    list<string> interventionGif1 <- [('../includes/GIF/Etoile/Etoile_1.gif'),('../includes/GIF/Champs/Champs_1.gif'),('../includes/GIF/Palais/Palais_1.gif'),('../includes/GIF/Concorde/Concorde_1.gif')];
    
	bool right_side_driving <- true;
	string transition0to_1<-'../includes/GIF/Etoile/Etoile_1.gif';
	
	
	map<string, rgb> metro_colors <- ["1"::rgb("#FFCD00"), "2"::rgb("#003CA6"),"3"::rgb("#837902"), "6"::rgb("#E2231A"),"7"::rgb("#FA9ABA"),"8"::rgb("#E19BDF"),"9"::rgb("#B6BD00"),"12"::rgb("#007852"),"13"::rgb("#6EC4E8"),"14"::rgb("#62259D")];
	//OLD PCA
	//map<string, rgb> type_colors <- ["default"::#white,"people"::#yellow, "car"::rgb(204,0,106),"bike"::rgb(18,145,209), "bus"::rgb(131,191,98)];
	//NEW COLOR
	map<string, rgb> type_colors <- ["default"::#white,"people"::#yellow, "car"::rgb(255,0,0),"bike"::rgb(18,145,209), "bus"::rgb(131,191,98)];
	
	map<string, rgb> voirie_colors <- ["Piste"::#white,"Couloir Bus"::#green, "Couloir mixte bus-vélo"::#red,"Piste cyclable"::#blue];
	map<string, rgb> nature_colors <- ["exi"::rgb(115,175,0),"pro"::rgb(183,255,97)];
	map<string, rgb> usage_colors <- ["exi"::rgb(75,75,75),"pro"::rgb(175,175,175)];
	
	float angle<-26.25;

	int stateNumber <- 2;
	string currentSimuState_str <- "present" among: ["present", "future"];
	int currentSimuState<-0;
	int currentStoryTellingState<-0;
	list<string> catchPhrase<-["traffic","public space","vibrancy","traffic","public space","vibrancy"];
	bool updateSim<-true;
	int nbAgent<-1000;
	float step <- 1 #sec;
	map<string,float> mobilityRatioNow <-["people"::0.49, "car"::0.3,"bike"::0.2, "bus"::0.01];
	map<string,float> mobilityRatioFuture <-["people"::0.6, "car"::0.2,"bike"::0.3, "bus"::0.1];

	

	list<list<intersection>> input_intersections <-list_with(stateNumber, []);
	list<list<intersection>> output_intersections <-list_with(stateNumber, []);
	list<list<intersection>> possible_targets <-list_with(stateNumber, []);
	
	map<agent,float> proba_choose_park;
	map<agent,float> proba_choose_culture;
	//list<intersection> tf_can_be_desactivated;
//	list<list<intersection>> active_traffic_lights <-list_with(stateNumber, []);
	
	
	list<intersection> vertices;
	
	init {
		
		//------------------ STATIC AGENT ----------------------------------- //

			

		
		create vizuRoad from: Mobility_Now_shapefile with: [type:string(read ("type"))] {
			state<<"present";
		}
		create vizuRoad from: Mobility_Future_shapefile with: [type:string(read ("type"))] {
			state<<"future";
		}

		create building from: buildings_shapefile with: [depth:float(read ("H_MOY"))];
		create intersection from: nodes_shapefile with: [is_traffic_signal::(read("type") = "traffic_signals"),  is_crossing :: (string(read("crossing")) = "traffic_signals"), group :: int(read("group")), phase :: int(read("phase"))];
		create signals_zone from: signals_zone_shapefile;
		//create road agents using the shapefile and using the oneway column to check the orientation of the roads if there are directed
		create road from: roads_shapefile with: [lanes_nb::[int(read("lanes")),int(read("pro_lanes"))], oneway::string(read("oneway")), is_tunnel::[(read("tunnel")="yes"?true:false),(read("pro_tunnel")="yes"?true:false)]] {
			maxspeed <- (lanes = 1 ? 30.0 : (lanes = 2 ? 40.0 : 50.0)) °km / °h;
					
			switch oneway {
				match "no" {
					create road {
						lanes <- myself.lanes;
						lanes_nb <- myself.lanes_nb;
						shape <- polyline(reverse(myself.shape.points));
						maxspeed <- myself.maxspeed;
						is_tunnel <- myself.is_tunnel;
						oneway <- myself.oneway;
					}
				}

				match "-1" {
					shape <- polyline(reverse(shape.points));
				}
			}
		}
		

		ask road{
			loop i from: 0 to: length(shape.points) -2{
				point vec_dir <- (shape.points[i+1]-shape.points[i])/norm(shape.points[i+1]-shape.points[i]);
				point vec_ortho <- {vec_dir.y,-vec_dir.x}*(right_side_driving?-1:1);
				vec_ref << [vec_dir,vec_ortho];
			}
			loop i from: 0 to: lanes-1{
				offset_list << (oneway='no')?((lanes - i - 0.5)*3 + 0.25):((0.5*lanes - i - 0.5)*3);
			}
			loop i from: 0 to: length(shape.points) - 3 step: 1{		
				float a <- angle_between(shape.points[i+1],shape.points[i],shape.points[i+2]);
				if !is_number(a){//probleme de precision avec angle_between qui renvoie un #nan
					a <- 180.0;
				}
				angles << a;
			}
		}

		//creation of the road network using the road and intersection agents
		driving_road_network <- (as_driving_graph(road, intersection)) use_cache false ;
		vertices <- list<intersection>(driving_road_network.vertices);
		loop i from: 0 to: length(vertices) - 1 {
			vertices[i].id <- i; 
		}
		
		loop j from: 0 to: stateNumber - 1{
			loop i over: intersection{
				if empty(i.roads_out where (road(each).lanes_nb[j] != 0)){output_intersections[j] << i;}
				if empty(i.roads_in where (road(each).lanes_nb[j] != 0)){input_intersections[j] << i;}
			}
			possible_targets[j] <- intersection - input_intersections[j];
		}
		
		ask intersection where each.is_traffic_signal{
			if empty(signals_zone overlapping self){
				is_traffic_signal <- false;
			}
		}
		do init_traffic_signal;
		loop j from: 0 to: stateNumber - 1{
			ask intersection where each.is_traffic_signal {
				activityStates[j] <- (roads_in first_with (road(each).lanes_nb[j] > 0) != nil);	
			}
		}


		do check_signals_integrity;
		
		do updateSimuState;
		
		create water from: water_shapefile ;
	
		create coldSpot from:coldspot_shapefile;
		
		//------------------- NETWORK -------------------------------------- //
	
		
		//------------------- AGENT ---------------------------------------- //
		
		do create_cars(round(nbAgent*world.get_mobility_ratio()["car"]));
		
		//Create Pedestrain
		
		
		
		 //Create Bus
	
		
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

		

//		map general_speed_map <- road as_map (each::((each.hot_spot ? 1 : 10) *(each.shape.perimeter / each.maxspeed) / (1+each.lanes)));
//		driving_road_network <- driving_road_network with_weights general_speed_map; 
	}
	
	map<string,float> get_mobility_ratio {
		if (currentSimuState = 0) {
			return mobilityRatioNow;
		} else {
			return mobilityRatioFuture;
		}
	}
	
	reflex chrono when: fps_monitor{
		chrono >> first(chrono);
		float new_m_time <- machine_time;
		chrono << new_m_time - m_time;
		if cycle mod 5 = 0 {
			write "fps: "+round((1/mean(chrono))*10000)/10+"    ("+mean(chrono)+"ms per frame)";
			}
		m_time <- new_m_time;
	}
	
	action updateStoryTelling (int n){
			if(n=1){currentStoryTellingState<-1;currentSimuState<-0;updateSim<-true;showVizuRoad<-true;showGreen<-false;showUsage<-false;peopleTrajectoryLength<-25;carTrajectoryLength<-50;bikeTrajectoryLength<-25;busTrajectoryLength<-25;}
			if(n=2){currentStoryTellingState<-2;showVizuRoad<-true;showGreen<-true;showUsage<-false;peopleTrajectoryLength<-25;carTrajectoryLength<-50;bikeTrajectoryLength<-25;busTrajectoryLength<-25;}
			if(n=3){currentStoryTellingState<-3;showVizuRoad<-true;showGreen<-true;showUsage<-true;peopleTrajectoryLength<-25;carTrajectoryLength<-50;bikeTrajectoryLength<-25;busTrajectoryLength<-25;}
			if(n=4){currentStoryTellingState<-4;currentSimuState<-1;updateSim<-true;showVizuRoad<-true;showGreen<-false;showUsage<-false;peopleTrajectoryLength<-50;carTrajectoryLength<-25;bikeTrajectoryLength<-25;busTrajectoryLength<-25;}
			if(n=5){currentStoryTellingState<-5;showVizuRoad<-true;showGreen<-true;showUsage<-false;peopleTrajectoryLength<-50;carTrajectoryLength<-25;bikeTrajectoryLength<-25;busTrajectoryLength<-25;}
			if(n=6){currentStoryTellingState<-6;showVizuRoad<-true;showGreen<-true;showUsage<-true;peopleTrajectoryLength<-50;carTrajectoryLength<-25;bikeTrajectoryLength<-25;busTrajectoryLength<-25;}
	}
	
	
	action create_cars(int nb) {
		create car number:nb{
		 	type <- "car";
		  	max_speed <- 160 #km / #h;
		  	speed<-15 #km/#h + rnd(10 #km/#h);
			vehicle_length <- 10.0 #m;
			right_side_driving <- myself.right_side_driving;
			proba_lane_change_up <- 0.1 + (rnd(500) / 500);
			proba_lane_change_down <- 0.5 + (rnd(500) / 500);
			current_intersection <- one_of(intersection - output_intersections);
			location <-current_intersection.location;
			security_distance_coeff <- 5 / 9 * 3.6 * (1.5 - rnd(1000) / 1000);
			proba_respect_priorities <- 1.0;// - rnd(200 / 1000);
			proba_respect_stops <- [1.0];
			proba_block_node <- 0.0;
			proba_use_linked_road <- 0.0;
			max_acceleration <- 5 / 3.6;
			speed_coeff <- 1.2 - (rnd(400) / 1000);
		}
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
				point centroide <- mean (gp collect (intersection(each)).location);
				loop rd over: roads_in {
					road r <- road(rd);
					bool inward <- distance_to(centroide, first(rd.shape.points)) > distance_to(centroide, last(rd.shape.points));
					if length(roads_in) = 1{// trouver un truc moins moche et plus générique pour ça
						ways1 << r;
					}else if inward {
						ways1 << r;
					}
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
	
	
	//on pourrait le virer, c'est juste a utiliser une fois (je laisse pour le moment pour ref)

	
	reflex updateSimuState when:updateSim=true{
		do updateSimuState;
	}

	reflex update_cars {
		ask first(100,shuffle(car where(each.to_update))){
			do update;
		}
		//write car count(each.to_update);
	}
	
	list<intersection> nodes_for_path (intersection source, intersection target, file ssp){
		
		list<intersection> nodes <- [];
		int id <- source.id;
		int target_id <- target.id;
		int cpt <- 0;
		loop while: id != target_id {
			nodes << intersection(vertices[id]);
			id <- int(ssp[target_id, id]);
			cpt <- cpt +1;
			if (id = -1 or cpt > 50000) {
				return list<intersection>([]);
			}
		}
		nodes<<target;
		return nodes;
	}
	

	
	action updateSimuState {
		if (currentSimuState = 0){currentSimuState_str <- "present";}
		if (currentSimuState = 1){currentSimuState_str <- "future";}
		ask road {do change_number_of_lanes(lanes_nb[currentSimuState]);}
		ask intersection where(each.is_traffic_signal){do change_activity;}
		
		if (driving_road_network != nil) {
			map general_speed_map <- road as_map (each:: !each.to_display ? 1000000000.0 : ((each.hot_spot ? 1 : 10) * (each.shape.perimeter / each.maxspeed)/(1+each.lanes)));
			driving_road_network <- driving_road_network with_weights general_speed_map;
		}
		ask car {self.to_update <- true;}
		updateSim<-false;
		
	
	
		int nb_cars <- length(car);
		int nb_cars_target <- round(nbAgent * get_mobility_ratio()["car"]);
		if (nb_cars_target > nb_cars) {
			do create_cars(nb_cars_target - nb_cars);
		} else if (nb_cars_target < nb_cars) {
			ask (nb_cars - nb_cars_target) among car {
				do remove_and_die;
			}
		}
		ask road {
		  	loop i from: 0 to:length(agents_on) - 1 {
		  		list<list<agent>> ag_l <- agents_on[i];
				loop j from: 0 to: length(ag_l) - 1  {
					list<agent> ag_s <- ag_l[j];
					ag_s <- list<agent>(ag_s) where (each != nil and not dead(each));
					agents_on[i][j] <- ag_s;
				}
			}
		}
	}
	// ne pas effacer ce qui suit, c'est pour des tests tant qu'on risque de modifier les shapefiles
	action check_signals_integrity {
		if false{
			ask input_intersections[0] where(each.group != 0){
				write "intersection "+self+" from group "+self.group+" is an input intersection for state 0";
			}
			ask output_intersections[0] where(each.group != 0){
				write "intersection "+self+" from group "+self.group+" is an output intersection for state 0";
			}
			ask input_intersections[1] where(each.group != 0){
				write "intersection "+self+" from group "+self.group+" is an input intersection for state 1";
				color <- #blue;
			}
			ask output_intersections[1] where(each.group != 0){
				write "intersection "+self+" from group "+self.group+" is an output intersection for state 1";
				color <- #blue;
			}
		}
	}
	
}


species vizuRoad{
	list<string> state;
	string type;
	aspect base {
		if(showVizuRoad and (currentSimuState_str in state)){
			draw shape color:type_colors[type];	
		}
	}
}

species building {
	string type; 
	float depth;
	rgb color <- rgb(75,75,75);
	aspect base {
		
	//	  draw shape color:rgb(75,75,75) empty:true;	
		
	}
}

species ilots {
	string type; 
	rgb color <- rgb(175,175,175)  ;
	
	aspect base {
		draw shape color: color ;
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
	bool test <- false;
	list<float> offset_list;
	list<float> angles;
	
	
	int id;
	list<bool> is_tunnel <- list_with(stateNumber,false);
	rgb color;
	string mode;
	float proba_use <- 100.0;

	float capacity;		
	string oneway;
	bool hot_spot <- false;

	list<list<point>> vec_ref;
	bool to_display <- true;
	
	list<int> lanes_nb;

	
	//action (pas jolie jolie) qui change le nombre de voie d'une route.
	action change_number_of_lanes(int new_number) {
		if new_number = 0{
			to_display <- false;
		}else {
			to_display <- true;
			int prev <- lanes;
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
			//	lanes <- new_number;
			} else if prev > new_number {
				list<list<list<agent>>> new_agents_on;
				int nb_seg <- length(shape.points) - 1;
				loop i from: 0 to: prev - 1 {
					list<list<agent>> ags_per_lanes <- agents_on[i];
					if (i < new_number) {
						new_agents_on << ags_per_lanes;
					} else {
						loop j from: 0 to: nb_seg -1 {
							list<car> ags <- list<car>(ags_per_lanes[j]);
							loop ag over: ags {
								new_agents_on[new_number - 1][j] << ag;
								ag.current_lane <- 0;
							}
						} 	
					}
				}
			//	lanes <- new_number;
				agents_on <- new_agents_on;		
			}
			lanes <- new_number;		
		}
	}
	
	
	float compute_offset(int current_lane){
		if precomp{
			return offset_list[min([current_lane,lanes -1])];
		}else{
			return (oneway='no')?((lanes - min([current_lane,lanes -1]) - 0.5)*3 + 0.25):((0.5*lanes - min([current_lane, lanes - 1]) - 0.5)*3);
		}
			
	}
	
	aspect base {
		if(showRoad and to_display){
			draw shape color:is_tunnel[currentSimuState]?rgb(50,0,0):type_colors["car"] width:1;	
		}
		if test{
			draw 3 around(shape) color: #white;
		}
	}
}















species car skills:[advanced_driving]{	
	bool to_update <- false;
	bool test_car <- false;
	point target_offset <- {0,0};
	int old_index <- 0;
	int old_segment_index;

	
	int fade_count <- 0;
	point current_offset <- {0,0};
	rgb color;
	point target;
	intersection target_intersection;
	string nationality;
	string profile;
	string aspect;
	string type;
	float speed;
	bool in_tunnel -> current_road != nil and road(current_road).is_tunnel[currentSimuState];
	list<point> current_trajectory;
	intersection current_intersection;
	
	
	action remove_and_die {
		if (current_road != nil) {
			ask road(current_road) {
				do unregister(myself);
				/*loop ag_l over: agents_on {
					loop ag_s over: ag_l  {
						if (myself in  list<agent>(ag_s)) {
							 list<agent>(ag_s) >> myself;
						}
					}
				}*/
			}
			
		//	write name + " -> " + current_road + " road(current_road):" + road(current_road).agents_on + " : " + road(current_road).all_agents;
		}
		do die;
	}
	reflex smooth_curve{
		if precomp{
			if smoothTrajectory{
				if (old_segment_index != segment_index_on_road) or (old_index != current_index){
					target_offset <- compute_offset_optim(3);
					old_segment_index <- segment_index_on_road;
					old_index <- current_index;
				}
				current_offset  <- current_offset + (target_offset - current_offset) * min([1,real_speed/100*step]);
			}else{
				float val <- road(current_road).compute_offset(current_lane);
				val <- on_linked_road ? -val : val;
				if (current_road != nil){
					current_offset <- road(current_road).vec_ref[segment_index_on_road][1] * val;
				}
				
			}	
		}else{
			if smoothTrajectory{
				current_offset  <- current_offset + (compute_offset(3) - current_offset) * min([1,real_speed/100*step]);
			}else{
				float val <- road(current_road).compute_offset(current_lane);
				val <- on_linked_road ? -val : val;
				if (current_road != nil){
					current_offset <- road(current_road).vec_ref[segment_index_on_road][1] * val;
				}
				
			}	
		}
		
	}


	bool use_blocked_road {
		if currentSimuState = 0 {return false;}
		if (current_path = nil) {/*write "reason nil path";
			write "car "+ int(self); 
			write current_path;*/
	//		ask world {do pause;}
			return false;
		}
		loop rd over:current_path.edges {
			if road(rd).lanes_nb[1] = 0 {
				//write "blocked road: "+road(rd);
				return true;
			}
		}
		return false;
		
	}
	reflex leave when: final_target = nil  {
		do leave;
	}
	
	action leave{
		if (target_intersection != nil and target_intersection in output_intersections) {
			if current_road != nil {
				ask current_road as road {
					do unregister(myself);
				}
			}
			current_intersection <- one_of(input_intersections[currentSimuState]);
			location <-current_intersection.location;
		}
		target_intersection <- one_of(possible_targets[currentSimuState]);
		current_lane <- 0;
		current_path <- compute_path(graph: driving_road_network, target: target_intersection);
		current_trajectory <- [];
	}
	
	
	reflex move when: final_target != nil{	
	  	do drive;	
	  	//on tente le tout pour le tout
	  	loop while:(length(current_trajectory) > carTrajectoryLength)
  	    {
        current_trajectory >> first(current_trajectory);
        }
        current_trajectory << location+current_offset;
	}
	
	
	action update{// il reste du code pour debuguer a nettoyer, ne pas trop toucher aux trucs chelous
		list<bool> trace;
		list<road> road_trace;
		if current_road != nil{
			trace << road(current_road).to_display;	
			road_trace << road(current_road);
			if not(road(current_road).to_display){//current road is not good
				fade_count <- 15;
			}else{//current road is good
				trace << road(current_road).to_display;
				road_trace << road(current_road);
				int truc <- 0;
				if target_intersection in possible_targets[currentSimuState]{// target is good
					truc <- 1;
					target <- last(road(current_road).shape.points);
//					graph driving_road_network2 <- driving_road_network with_weights general_speed_map;
					current_path <- compute_path(graph: driving_road_network, target: target_intersection);
					trace << road(current_road).to_display;
					road_trace << road(current_road);
					if (road(current_road).to_display){
						
					}
				}else{//target is not good
					truc <- 2;
					trace << road(current_road).to_display;
					road_trace << road(current_road);
					target_intersection <- one_of(possible_targets[currentSimuState]);
					current_lane <- 0;
					current_path <- compute_path(graph: driving_road_network, target: target_intersection);
					trace << road(current_road).to_display;
					road_trace << road(current_road);
				}
				
				if use_blocked_road(){
					trace << road(current_road).to_display;
					road_trace << road(current_road);
//					write ""+int(self)+" is updating at step "+cycle+" target possible "+(target_intersection in possible_targets[1]); // I left this block  to check is this happens sometimes...
//					write "current road "+current_road+" to display? "+road(current_road).to_display+" choice "+truc+" target "+target_intersection;
//					write "road trace: "+road_trace;
//					write "trace "+ trace+"\n";
		//			ask world {do pause;}
				}
			}
			to_update <- false;
		}
//		write "car "+int(self);
	}

	reflex fade when: (fade_count > 0){
		fade_count <- fade_count - 1;
		if fade_count = 0{
			if current_road != nil {
				ask current_road as road {
					do unregister(myself);
				}
			}
			current_intersection <- one_of(input_intersections[currentSimuState]);
			location <-current_intersection.location;
			target_intersection <- one_of(possible_targets[currentSimuState]);
			current_lane <- 0;
			current_path <- compute_path(graph: driving_road_network, target: target_intersection);
			current_trajectory <- [];
		}	
	}
	
	point calcul_loc {
		if (current_road = nil) {
			return location;
		} else {		
			return (location + current_offset);
		}
	} 
	
	
	aspect base {
		if(showCar){
		    draw rectangle(dotPoint,dotPoint*2) at: calcul_loc() rotate:heading-90 color:in_tunnel?rgb(50,0,0):rgb(type_colors[type],(fade_count=0)?1:fade_count/20);	   
	  	}
	  	if (test_car){
	  		draw rectangle(2.5#m,5#m) at: calcul_loc() rotate:heading-90 color:#green;
	  		loop p over: targets{
	  			draw circle(1#m) at: p color: #green; 
	  		}
	  		draw circle(5#m) at: first(targets) color: #green;
	  		draw circle(3#m) at: last(targets) color: #green;
	  	}
	  	if(showCarTrajectory){
	       draw line(current_trajectory) color: rgb(type_colors[type].red,type_colors[type].green,type_colors[type].blue,trajectoryTransparency);	
	  	}
	}	
	
	point compute_offset_optim(int s){
		if precompv{
			if current_road = nil or current_path = nil{
				return current_offset;
			}else{
				int ci <- current_index;
				int cs <- segment_index_on_road;
				int count <- 0;
				point offset_comp <- road(current_road).vec_ref[0][1]*road(current_road).compute_offset(current_lane);
				float weight <- 1.0;
				loop while: (count < s - 1) and ci < length(current_path.edges){
					count <- count + 1;
					road cr <- road(current_path.edges[ci]);
					if cs < length(cr.angles) {
						float a <- cr.angles[cs];
						float w <- 1+abs(a-180);
						weight <- weight + 1+w;
						if abs(abs(a-90)-90)<5{
							offset_comp <- offset_comp + cr.vec_ref[cs][1]*cr.compute_offset(current_lane)*w;
						}else{
							offset_comp <- offset_comp + (cr.vec_ref[cs][0]-cr.vec_ref[cs+1][0])*cr.compute_offset(current_lane)/sin(a)*w;
						}
						cs <- cs + 1;
					}else {
						if ci + 1 < length(current_path.edges){
							road cr2 <- road(current_path.edges[ci+1]);
							float a <- angle_between(last(cr.shape.points),cr.shape.points[length(cr.shape.points)-2],cr2.shape.points[1]);
							if !is_number(a){//probleme de precision avec angle_between qui renvoie un #nan
								a <- 180.0;
							}
							float w <- 1+abs(a-180);
							weight <- weight + w;
							if abs(abs(a-90)-90)<5{
								offset_comp <- offset_comp + cr.vec_ref[cs][1]*cr.compute_offset(current_lane)*w;
							}else{
								offset_comp <- offset_comp + (cr.vec_ref[cs][0]*cr2.compute_offset(current_lane)-cr2.vec_ref[0][0]*cr.compute_offset(current_lane))/sin(a)*(1+abs(a-180));
							}
						}
						ci <- ci + 1;	
						cs <- 0;
					}
				}
//				if (test_car){
//					list<list<point>> segment_list <- [];
//					list<road> lr <- [];
//					list<list<point>> tmp_vec_ref <- [];
//					int ci <- current_index;
//					int cs <- segment_index_on_road;
//					int count <- 0;
//					loop while: (count < s) and ci < length(current_path.edges){
//						segment_list << copy_between(road(current_path.edges[ci]).shape.points,cs,cs+2);
//						tmp_vec_ref << road(current_path.edges[ci]).vec_ref[cs];
//						lr << road(current_path.edges[ci]);
//						count <- count + 1;
//						cs <- cs + 1;
//						if (cs > length(road(current_path.edges[ci]).shape.points)-2){
//							cs <- 0;
//							ci <- ci + 1;
//						}
//					}
//					list<point> offset_list <- [tmp_vec_ref[0][1]*lr[0].compute_offset(current_lane)];
//					list<float> weight_list <- [1.0];
//					loop i from: 0 to: length(segment_list) - 2 step: 1{		
//						float a <- angle_between(last(segment_list[i]),first(segment_list[i]),last(segment_list[i+1]));
//						if !is_number(a){//probleme de precision avec angle_between qui renvoie un #nan
//							a <- 180.0;
//						}
//						weight_list << 1+abs(a-180);
//						if abs(abs(a-90)-90)<5{
//							offset_list << tmp_vec_ref[i][1]*lr[i].compute_offset(current_lane);
//						}else{
//							offset_list << (tmp_vec_ref[i][0]*lr[i+1].compute_offset(current_lane)-tmp_vec_ref[i+1][0]*lr[i].compute_offset(current_lane))/sin(a);
//						}
//					}
//					loop i from: 0 to: length(segment_list) - 2 step: 1{
//						draw circle(2#m) at: last(segment_list[i]) color: #white;//rgb(255 - i *100,255 - i*100,255); 
//						draw circle(0.5#m) at:  last(segment_list[i])+offset_list[i+1] color: rgb(255 - i *100,255 - i*100,255); 
//					}	
//				}
				return offset_comp / weight;
			}
			
			
		}else{

			if current_road = nil or current_path = nil{
				return current_offset;
			}else{
				int ci <- current_index;
				int cs <- segment_index_on_road;
				list<list<point>> segment_list <- [];
				list<road> lr <- [];
				list<list<point>> tmp_vec_ref <- [];
				int count <- 0;
				loop while: (count < s) and ci < length(current_path.edges){
					segment_list << copy_between(road(current_path.edges[ci]).shape.points,cs,cs+2);
					tmp_vec_ref << road(current_path.edges[ci]).vec_ref[cs];
					lr << road(current_path.edges[ci]);
					count <- count + 1;
					cs <- cs + 1;
					if (cs > length(road(current_path.edges[ci]).shape.points)-2){
						cs <- 0;
						ci <- ci + 1;
					}
				}
				point offset_comp <- tmp_vec_ref[0][1]*lr[0].compute_offset(current_lane);
				float weight <- 1.0;
				loop i from: 0 to: length(segment_list) - 2 step: 1{		
					float a <- angle_between(last(segment_list[i]),first(segment_list[i]),last(segment_list[i+1]));
					if !is_number(a){//probleme de precision avec angle_between qui renvoie un #nan
						a <- 180.0;
					}
					weight <- weight + 1+abs(a-180);
					if abs(abs(a-90)-90)<5{
						offset_comp <- offset_comp + tmp_vec_ref[i][1]*lr[i].compute_offset(current_lane)*(1+abs(a-180));
					}else{
						offset_comp <- offset_comp + (tmp_vec_ref[i][0]*lr[i+1].compute_offset(current_lane)-tmp_vec_ref[i+1][0]*lr[i].compute_offset(current_lane))/sin(a)*(1+abs(a-180));
					}
				}
				if (test_car){
					loop i from: 0 to: length(segment_list) - 2 step: 1{
						draw circle(1#m) at: last(segment_list[i]) color: rgb(255 - i *100,255 - i*100,255); 
			//			draw circle(0.5#m) at:  last(segment_list[i])+offset_list[i+1] color: rgb(255 - i *100,255 - i*100,255); 
					}	
				}
	//			point offset <- {0,0};
	//			loop i from: 0 to: length(offset_list)-1{
	//				offset <- offset + offset_list[i]*weight_list[i];
	//			}
				return offset_comp / weight;
			}






		}
		
	}
	
	
	
//	point compute_offset_optim(int s){
//		if current_road = nil or current_path = nil{
//			return current_offset;
//		}else{
//			int ci <- current_index;
//			int cs <- segment_index_on_road;
//			list<list<point>> segment_list <- [];
//			list<road> lr <- [];
//			list<list<point>> tmp_vec_ref <- [];
//			int count <- 0;
//			float weight <- 1.0;
//			loop while: (count < s) and ci < length(current_path.edges){
//				segment_list << copy_between(road(current_path.edges[ci]).shape.points,cs,cs+2);
//				tmp_vec_ref << road(current_path.edges[ci]).vec_ref[cs];
//				lr << road(current_path.edges[ci]);
//				count <- count + 1;
//				cs <- cs + 1;
//				if (cs > length(road(current_path.edges[ci]).shape.points)-2){
//					cs <- 0;
//					ci <- ci + 1;
//				}
//			}
//			point offset_comp <- tmp_vec_ref[0][1]*lr[0].compute_offset(current_lane);
//			loop i from: 0 to: length(segment_list) - 2 step: 1{		
//				float a <- angle_between(last(segment_list[i]),first(segment_list[i]),last(segment_list[i+1]));
//				if !is_number(a){//probleme de precision avec angle_between qui renvoie un #nan
//					a <- 180.0;
//				}
//				weight <- weight + 1+abs(a-180);
//				if abs(abs(a-90)-90)<5{
//					offset_comp <- offset_comp + tmp_vec_ref[i][1]*lr[i].compute_offset(current_lane);
//				}else{
//					offset_comp <- offset_comp + (tmp_vec_ref[i][0]*lr[i+1].compute_offset(current_lane)-tmp_vec_ref[i+1][0]*lr[i].compute_offset(current_lane))/sin(a);
//				}
//			}
//			if (test_car){
//				loop i from: 0 to: length(segment_list) - 2 step: 1{
//					draw circle(1#m) at: last(segment_list[i]) color: rgb(255 - i *100,255 - i*100,255); 
//		//			draw circle(0.5#m) at:  last(segment_list[i])+offset_list[i+1] color: rgb(255 - i *100,255 - i*100,255); 
//				}	
//			}
////			point offset <- {0,0};
////			loop i from: 0 to: length(offset_list)-1{
////				offset <- offset + offset_list[i]*weight_list[i];
////			}
//			return offset_comp / weight;
//		}
//	}
	
	
	//
	//
	//
	//
	
	
	point compute_offset(int s){
		if current_road = nil or current_path = nil{
			return current_offset;
		}else{
			int ci <- current_index;
			int cs <- segment_index_on_road;
			list<list<point>> segment_list <- [];
			list<road> lr <- [];
			list<list<point>> tmp_vec_ref <- [];
			int count <- 0;
			loop while: (count < s) and ci < length(current_path.edges){
				segment_list << copy_between(road(current_path.edges[ci]).shape.points,cs,cs+2);
				tmp_vec_ref << road(current_path.edges[ci]).vec_ref[cs];
				lr << road(current_path.edges[ci]);
				count <- count + 1;
				cs <- cs + 1;
				if (cs > length(road(current_path.edges[ci]).shape.points)-2){
					cs <- 0;
					ci <- ci + 1;
				}
			}
			list<point> offset_list <- [tmp_vec_ref[0][1]*lr[0].compute_offset(current_lane)];
			list<float> weight_list <- [1.0];
			loop i from: 0 to: length(segment_list) - 2 step: 1{		
				float a <- angle_between(last(segment_list[i]),first(segment_list[i]),last(segment_list[i+1]));
				if !is_number(a){//probleme de precision avec angle_between qui renvoie un #nan
					a <- 180.0;
				}
				weight_list << 1+abs(a-180);
				if abs(abs(a-90)-90)<5{
					offset_list << tmp_vec_ref[i][1]*lr[i].compute_offset(current_lane);
				}else{
					offset_list << (tmp_vec_ref[i][0]*lr[i+1].compute_offset(current_lane)-tmp_vec_ref[i+1][0]*lr[i].compute_offset(current_lane))/sin(a);
				}
			}
			if (test_car){
				write segment_list;
				loop i from: 0 to: length(segment_list) - 1 step: 1{
					draw circle(2#m) at: last(segment_list[i]) color: rgb(255 - i *100,255 - i*100,255); 
					draw circle(0.5#m) at:  last(segment_list[i])+offset_list[i+1] color: rgb(255 - i *100,255 - i*100,255); 
				}	
			}
			point offset <- {0,0};
			loop i from: 0 to: length(offset_list)-1{
				offset <- offset + offset_list[i]*weight_list[i];
			}
			return offset / sum(weight_list);
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
		if(showIntervention){
			draw shape empty:true color:#white;		
			if(showGif and isActive){
			  draw gif_file(gifFile) size:{w,h} rotate:angle;	
			}
		}
			
		}
}

species signals_zone{
		aspect base {
			draw shape empty: true  color:#green;		
		}
}

species intersection skills: [skill_road_node] {
	rgb color <- #white; //used for integrity tests
	
	int phase;
	bool is_traffic_signal;
	bool is_crossing;
	int group;
	int id;
	int time_to_change <- 20;


	int counter <- rnd(time_to_change);
	list<road> ways1;
	list<road> ways2;
	bool is_green;
	rgb color_fire;
	rgb color_group;
	bool active <- true;
	list<bool> activityStates <- list_with(stateNumber, true);

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
	
	action change_activity{
		if active != activityStates[currentSimuState]{
			active <- activityStates[currentSimuState];
			if not active {
				stop[0] <- [];
			}
		}
	}

	reflex dynamic_node when: active and is_traffic_signal {
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
	float minimum_cycle_duration<-0.025;	
	output {
		display champ type:opengl background:#black draw_env:false /*fullscreen:1*/  rotate:angle toolbar:false autosave:false synchronized:true
camera_pos: {1577.7317,1416.6484,2491.6749} camera_look_pos: {1577.7317,1416.605,0.0019} camera_up_vector: {0.0,1.0,0.0}
	   	//camera_pos: {1812.4353,1521.601,3039.7286} camera_look_pos: {1812.4353,1521.548,0.0} camera_up_vector: {0.0,1.0,0.0}

	   	{
	   	    species graphicWorld aspect:base;	    	
	    	species intervention aspect: base;
		    species building aspect: base;
			species water aspect: base;
			species road aspect: base;
			species vizuRoad aspect:base transparency:0.8;
			species intersection;
			species car aspect:base;
			species coldSpot aspect:base;
									
			graphics 'tablebackground'{
				draw geometry(shape_file_bounds) color:#white empty:true;
				draw string("State: " + currentSimuState) rotate:angle at:{400,400} color:#white empty:true;
			}
			
			
			event["g"] action: {showGif<-!showGif;};
			
			event["m"] action: {showVizuRoad<-!showVizuRoad;};
		event["i"] action: {showIntervention<-!showIntervention;};
			
			event["a"] action: {showAmenities<-!showAmenities;};
			event["n"] action: {showGreen<-!showGreen;};
			event["u"] action: {showUsage<-!showUsage;};
			event["w"] action: {showWater<-!showWater;};
			event["h"] action: {showHotSpot<-!showHotSpot;};
			event["r"] action: {showRoad<-!showRoad;};						
			event["z"] action: {currentSimuState <- (currentSimuState + 1) mod stateNumber;updateSim<-true;};
			//event["1"] action: {if(currentSimuState!=1){currentSimuState<-1;updateSim<-true;}};
			
			
			//STORY TELLING
			event["1"] action: {ask world{do updateStoryTelling (1);}};
			event["2"] action: {ask world{do updateStoryTelling (2);}};
			event["3"] action: {ask world{do updateStoryTelling (3);}};
			event["4"] action: {ask world{do updateStoryTelling (4);}};
			event["5"] action: {ask world{do updateStoryTelling (5);}};
			event["6"] action: {ask world{do updateStoryTelling (6);}};
			

		}
	}
}


experiment ReChamp2Proj parent:ReChamp autorun:true{	
	
	output {	
		layout #split;
		display indicator type:opengl background:#black draw_env:true fullscreen:2 toolbar:false
		//camera_pos: {1812.4353,1521.574,1490.9658} camera_look_pos: {1812.4353,1521.548,0.0} camera_up_vector: {0.0,1.0,0.0}
		{
			/*graphics 'dashboardbackground'{
				draw rectangle(1920,1080) texture:dashboardbackground.path at:{world.shape.width/2,world.shape.height/2}color:#white empty:true;
				
			}*/
			
			graphics "state" {
				float textSize<-10#px;
				float spacebetween<-200#px;
				draw ((currentSimuState = 0) ? "Today" :"2024") color: #white font: font("Helvetica", textSize*2, #bold) at: {world.shape.width*0.75,world.shape.height*0.25};
				if(currentStoryTellingState=1){
				  draw (catchPhrase[0]) color: type_colors["car"] font: font("Helvetica", textSize, #bold) at: {0,world.shape.height/4};
				}
				if(currentStoryTellingState=2){
				  draw (catchPhrase[0]) color: type_colors["car"] font: font("Helvetica", textSize, #bold) at: {0,world.shape.height/4};	
				  draw (catchPhrase[1]) color: type_colors["bus"] font: font("Helvetica", textSize, #bold) at: {0+spacebetween,world.shape.height/4+spacebetween};
				}
				if(currentStoryTellingState=3){
				  draw (catchPhrase[0]) color: type_colors["car"] font: font("Helvetica", textSize, #bold) at: {0,world.shape.height/4};	
				  draw (catchPhrase[1]) color: type_colors["bus"] font: font("Helvetica", textSize, #bold) at: {0+spacebetween,world.shape.height/4+spacebetween};
				  draw (catchPhrase[2]) color: #white font: font("Helvetica", textSize, #bold) at: {0+spacebetween*2,world.shape.height/4+spacebetween*2};
				}
				if(currentStoryTellingState=4){
				  draw (catchPhrase[3]) color: type_colors["car"] font: font("Helvetica", textSize, #bold) at: {0,world.shape.height/4};
				  draw ("15% less car") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {0,world.shape.height/4+textSize*2};
				  draw ("1O% more sharing mobility") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {0,world.shape.height/4+textSize*4};
				}
				if(currentStoryTellingState=5){
				  draw (catchPhrase[3]) color: type_colors["car"] font: font("Helvetica", textSize, #bold) at: {0,world.shape.height/4};
				  draw ("15% less car") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {0,world.shape.height/4+textSize*2};
				  draw ("1O% more sharing mobility") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {0,world.shape.height/4+textSize*4};	
				  draw (catchPhrase[4]) color: type_colors["bus"] font: font("Helvetica", textSize, #bold) at: {0+spacebetween,world.shape.height/4+spacebetween};
				  draw ("20% more park") color: type_colors["bus"] font: font("Helvetica", textSize/3, #bold) at: {0+spacebetween,world.shape.height/4+spacebetween+textSize*2};
				  draw ("10% more biotopy") color: type_colors["bus"] font: font("Helvetica", textSize/3, #bold) at: {0+spacebetween,world.shape.height/4+spacebetween+textSize*4};
				}
				if(currentStoryTellingState=6){
				  draw (catchPhrase[3]) color: type_colors["car"] font: font("Helvetica", textSize, #bold) at: {0,world.shape.height/4};
				  draw ("15% less car") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {0,world.shape.height/4+textSize*2};
				  draw ("1O% more sharing mobility") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {0,world.shape.height/4+textSize*4};	
				  draw (catchPhrase[4]) color: type_colors["bus"] font: font("Helvetica", textSize, #bold) at: {0+spacebetween,world.shape.height/4+spacebetween};
				  draw ("20% more park") color: type_colors["bus"] font: font("Helvetica", textSize/3, #bold) at: {0+spacebetween,world.shape.height/4+spacebetween+textSize*2};
				  draw ("10% more biotopy") color: type_colors["bus"] font: font("Helvetica", textSize/3, #bold) at: {0+spacebetween,world.shape.height/4+spacebetween+textSize*4};
				  draw (catchPhrase[5]) color: #white font: font("Helvetica", textSize, #bold) at: {0+spacebetween*2,world.shape.height/4+spacebetween*2};
				  draw ("15% less is more ") color: #white font: font("Helvetica", textSize/3, #bold) at: {0+spacebetween*2,world.shape.height/4+spacebetween*2+textSize*2};
				  draw ("10% more restaurant") color: #white font: font("Helvetica", textSize/3, #bold) at: {0+spacebetween*2,world.shape.height/4+spacebetween*2+textSize*4};
				}
			}
			

		}
	}
}

