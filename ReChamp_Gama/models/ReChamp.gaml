  /***
* Name: ReChamp
* Author: Arnaud Grignard, Tri Nguyen-Huu, Patrick Taillandier, Nicolas Ayoub 
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
	file station_shapefile <- file("../includes/GIS/stations_metro.shp");
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
	
	list<graph> driving_road_network;
	
	float max_dev <- 10.0;
	float fuzzyness <- 1.0;
	float dist_group_traffic_light <- 50.0;

	
	bool showCar parameter: 'Car (c)' category: "Agent" <-true;
	bool showPeople parameter: 'Pedestrain (p)' category: "Agent" <-true;
	bool showBike parameter: 'Bike (b)' category: "Agent" <-true;
	bool showSharedMobility parameter: 'Shared Mobility (s)' category: "Agent" <-true;
	

	bool showVizuRoad parameter: 'Mobility(m)' category: "Infrastructure" <-false;
	bool showGreen parameter: 'Nature (n)' category: "Infrastructure" <-true;
	bool showUsage parameter: 'Usage (u)' category: "Infrastructure" <-true;

	bool showPeopleTrajectory parameter: 'People Trajectory' category: "Trajectory" <-true;
	bool showCarTrajectory parameter: 'Car Trajectory' category: "Trajectory" <-true;
	bool showBikeTrajectory parameter: 'Bike Trajectory' category: "Trajectory" <-true;
	bool showSharedMobilityTrajectory parameter: 'SharedMobility Trajectory' category: "Trajectory" <-true;
	
	int trajectorySizeMax<-100;
	int peopleTrajectoryLengthBefore <-25 parameter: 'People Trajectory length Before' category: "Trajectory" min: 0 max:50;
	int peopleTrajectoryLengthAfter <-25 parameter: 'People Trajectory length After' category: "Trajectory" min: 0 max:50;
	int carTrajectoryLengthBefore <-25 parameter: 'Car Trajectory length Before' category: "Trajectory" min: 0 max: 50;
	int carTrajectoryLengthAfter <-25 parameter: 'Car Trajectory length After' category: "Trajectory" min: 0 max: 50;
	int bikeTrajectoryLengthBefore <-25 parameter: 'Bike Trajectory Before' category: "Trajectory" min: 0 max: 50;
	int bikeTrajectoryLengthAfter <-25 parameter: 'Bike Trajectory After' category: "Trajectory" min: 0 max: 50;
	int busTrajectoryLengthBefore <-25 parameter: 'Bus Trajectory length' category: "Trajectory" min: 0 max: 50;
	int busTrajectoryLengthAfter <-25 parameter: 'Bus Trajectory length' category: "Trajectory" min: 0 max: 50;

	float step <-5#sec parameter: 'Simulation Step' category: "AAAA" min: 1#sec max: 30#sec;
	
	bool smoothTrajectory parameter: 'Smooth Trajectory' category: "Trajectory" <-true;
	float peopleTrajectoryTransparencyBefore <-0.25 parameter: 'People Trajectory transparency Before' category: "Trajectory Transparency" min: 0.0 max: 1.0;
	float peopleTrajectoryTransparencyAfter <-0.25 parameter: 'People Trajectory transparency After' category: "Trajectory Transparency" min: 0.0 max: 1.0;
	float carTrajectoryTransparencyBefore <-0.25 parameter: 'Car Trajectory transparency Before' category: "Trajectory Transparency" min: 0.0 max: 1.0;
	float carTrajectoryTransparencyAfter <-0.25 parameter: 'Car Trajectory transparency After' category: "Trajectory Transparency" min: 0.0 max: 1.0;
	float bikeTrajectoryTransparencyBefore <-0.25 parameter: 'Bike Trajectory transparency Before' category: "Trajectory Transparency" min: 0.0 max: 1.0;
	float bikeTrajectoryTransparencyAfter <-0.25 parameter: 'Bike Trajectory transparency After' category: "Trajectory Transparency" min: 0.0 max: 1.0;
	float busTrajectoryTransparencyBefore <-0.25 parameter: 'Bus Trajectory transparency Before' category: "Trajectory Transparency" min: 0.0 max: 1.0;
	float busTrajectoryTransparencyAfter <-0.25 parameter: 'Bus Trajectory transparency After' category: "Trajectory Transparency" min: 0.0 max: 1.0;

	
	bool showBikeLane  parameter: 'Bike Lane (v)' category: "Parameters" <-false;
	bool showBusLane parameter: 'Bus Lane(j)' category: "Parameters" <-false;
	bool showMetroLane parameter: 'Metro Lane (q)' category: "Parameters" <-false;
	bool showStation parameter: 'Station (s)' category: "Parameters" <-false;
	bool showTrafficSignal parameter: 'Traffic signal (t)' category: "Parameters" <-false;
	bool showBuilding parameter: 'Building (b)' category: "Parameters" <-false;
	bool showRoad parameter: 'Road Simu(r)' category: "Parameters" <-false;
	
	bool showWater parameter: 'Water (w)' category: "Parameters" <-false;
	bool showWaitingLine parameter: 'Waiting Line (x)' category: "Parameters" <-false;
	bool showAmenities parameter: 'Amenities (a)' category: "Parameters" <-false;
	bool showIntervention parameter: 'Intervention (i)' category: "Parameters" <-false;
	bool showBackground <- false parameter: "Background (Space)" category: "Parameters";
	float factor<-0.8;
	float peopleSize <-(8.0)#m parameter: 'Peoplesize' category: "Parameters" min: 0.5#m max: 5.0#m;
	float carSize <-(6.0)#m parameter: 'Dot size' category: "Parameters" min: 0.5#m max: 5.0#m;
	float bikeSize <-(6.0)#m parameter: 'Dot size' category: "Parameters" min: 0.5#m max: 5.0#m;
	float busSize <-(6.0)#m parameter: 'Dot size' category: "Parameters" min: 0.5#m max: 5.0#m;
	
	
	bool showGif  parameter: 'Gif (g)' category: "Parameters" <-false;
	bool showHotSpot  parameter: 'HotSpot (h)' category: "Parameters" <-true;
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
	map<string, rgb> nature_colors <- ["exi"::rgb(140,200,135),"pro"::rgb(140,200,135)];
	map<string, rgb> usage_colors <- ["exi"::rgb(175,175,175),"pro"::rgb(175,175,175)];
	
	float angle<-26.25;

	int stateNumber <- 2;
	string currentSimuState_str <- "present" among: ["present", "future"];
	int currentSimuState<-0;
	int currentStoryTellingState<-0;
	list<string> catchPhrase<-["traffic","public space","vibrancy","traffic","public space","vibrancy"];
	bool updateSim<-true;
	int nbAgent<-1000;
	
	map<string,float> mobilityRatioNow <-["people"::0.6, "car"::0.8,"bike"::0.1, "bus"::0];
	map<string,float> mobilityRatioFuture <-["people"::2.0, "car"::0.4,"bike"::0.3, "bus"::0.1];

	
	map<bikelane,float> weights_bikelane;
	list<list<intersection>> input_intersections <-list_with(stateNumber, []);
	list<list<intersection>> output_intersections <-list_with(stateNumber, []);
	list<list<intersection>> possible_targets <-list_with(stateNumber, []);
	list<list<intersection>> possible_sources <-list_with(stateNumber, []);
	
	map<agent,float> proba_choose_park;
	map<agent,float> proba_choose_culture;
	
	list<park> activated_parks;
	list<culture> activated_cultures;
	list<intersection> vertices;
	
	
	int chrono_size <- 30;
	bool fps_monitor <- false;
	float m_time;
	list<float> chrono <- list_with(chrono_size,0.0);
	
	float meanSpeedCar<-15 #km/#h;
	float deviationSpeedCar<-10 #km/#h;
	
	float minSpeedPeople<-2 #km/#h;
	float maxSpeedPeople<-5 #km/#h;
	
	
	
	init {
		
		//------------------ STATIC AGENT ----------------------------------- //
		create park from: (Nature_Future_shapefile) with: [type:string(read ("type"))] {
			state<<"future";
			if (shape = nil or shape.area = 0 or not(shape overlaps world)) {
				do die;
			}
			
		}
		loop g over: Nature_Now_shapefile {
			
			if (g != nil and not empty(g)) and (g overlaps world) {
				park p <- (park first_with(each.shape.area = g.area));
				if (p = nil) {p <- park first_with (each.location = g.location);}
				if (p != nil){p.state << "present";}
			}
		}
		create culture from: Usage_Future_shapefile where (each != nil) with: [type:string(read ("type")),style:string(read ("style")),capacity:float(read ("capacity"))]{
			state<<"future";
			if (shape = nil or shape.area = 0) {
				do die;
			}
		}
		loop g over: Usage_Now_shapefile where (each != nil and each.area > 0) {
			culture p <- (culture first_with(each.shape.area = g.area));
			if (p = nil) {p <- culture first_with (each.location = g.location);}
			if (p != nil){p.state << "present";}
		}
		
		create vizuRoad from: Mobility_Now_shapefile with: [type:string(read ("type"))] {
			state<<"present";
		}
		create vizuRoad from: Mobility_Future_shapefile with: [type:string(read ("type"))] {
			state<<"future";
		}
		
		do manage_waiting_line;
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
			loop i from: 0 to: max(lanes_nb)-1{
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
//		driving_road_network <- (as_driving_graph(road, intersection)) use_cache false ;
		graph tmp <- as_driving_graph(road, intersection) use_cache false;
		vertices <- list<intersection>(tmp.vertices);
		loop i from: 0 to: length(vertices) - 1 {
			vertices[i].id <- i; 
		}
		
		
//		loop j from: 0 to: stateNumber - 1{
//			loop i over: intersection{
//				if empty(i.roads_out where (road(each).lanes_nb[j] != 0)){output_intersections[j] << i;}
//				if empty(i.roads_in where (road(each).lanes_nb[j] != 0)){input_intersections[j] << i;}
//			}
//			possible_targets[j] <- intersection - input_intersections[j];
//		}
		
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
		
		loop j from: 0 to:  stateNumber-1{
			map general_speed_map <- road as_map (each::((each.hot_spot ? 1 : 10) * (each.shape.perimeter / each.maxspeed)/(1+each.lanes)));
			driving_road_network << (as_driving_graph(road where (each.lanes_nb[j] > 0), intersection)) with_weights general_speed_map;
		}
		
		loop i over: intersection{
			i.roads_in <- remove_duplicates(i.roads_in);
			i.roads_out <- remove_duplicates(i.roads_out);
		}
		
		loop j from: 0 to:  stateNumber-1{
			ask intersection{
				self.reachable_by_all[j] <- false;
				self.can_reach_all[j] <- false;
			}

			list<list<intersection>> il <- find_connection(intersection[4], j);
			ask il[0]{
				self.reachable_by_all[j] <- true;
			}
			ask il[1]{
				self.can_reach_all[j] <- true;
			}	
		}

		loop j from: 0 to: stateNumber - 1{
			loop i over: intersection{
				if not(i.can_reach_all[j]) {output_intersections[j] << i;}
				if not(i.reachable_by_all[j]){input_intersections[j] << i;}
			}
			possible_targets[j] <- intersection - input_intersections[j];
			possible_sources[j] <- intersection - output_intersections[j];
		}
		
		loop j from: 0 to: stateNumber - 1{
			loop i over: intersection where not(each.can_reach_all[j]) {
				if empty(i.roads_out where (road(each).lanes_nb[j] != 0)){
					i.exit[j] <- i;
				}else{
					road o <- one_of(i.roads_out) as road;
					intersection i2 <- one_of(intersection where (each.roads_in contains o));
					if i2.exit[j] = nil{
						i.exit[j] <- i2;
					}else{
						i.exit[j] <- i2.exit[j];
					}
					ask intersection where(each.exit[j] = i){
						exit[j] <- i.exit[j];
					}
				}
			}
			possible_targets[j] <- intersection - input_intersections[j];
		}	

	//	do check_signals_integrity;
		
		do updateSimuState;
		
		create water from: water_shapefile ;
		create station from: station_shapefile with: [type:string(read ("type")), capacity:int(read ("capacity"))];
		create coldSpot from:coldspot_shapefile;
		
		//------------------- NETWORK -------------------------------------- //
		create metro_line from: metro_shapefile with: [number:string(read ("c_ligne")),nature:string(read ("c_nature"))];
		//do manage_cycle_network;
		create bikelane from:bikelane_shapefile{
			color<-type_colors["bike"];
		}
		create bus_line from: bus_shapefile{
			color<-type_colors["bus"];
		}
		
		//------------------- AGENT ---------------------------------------- //
		
		do create_cars(round(nbAgent*world.get_mobility_ratio()["car"]));
		
		//Create Pedestrain
		do create_pedestrian(round(nbAgent*world.get_mobility_ratio()["people"]));
		
        //Create Bike
	    create bike number:round(nbAgent*world.get_mobility_ratio()["bike"]){
	       type <- "bike";
		  location<-any_location_in(one_of(building));	
		}
				
		people_graph <- as_edge_graph(road);
		//people_graph<- people_graph use_cache false;
			
		weights_bikelane <- bikelane as_map(each::each.shape.perimeter);
		map<bikelane,float> weights_bikelane_sp <- bikelane as_map(each::each.shape.perimeter * (each.from_road ? 10.0 : 0.0));
		
		bike_graph <- (as_edge_graph(bikelane) with_weights weights_bikelane_sp) ;
		//bike_graph<- bike_graph use_cache false;
		
		
		 //Create Bus
	    create bus number:round(nbAgent*mobilityRatioNow["bus"]){
	      type <- "bus";
		  location<-any_location_in(one_of(road));	
		}
		bus_graph <- (as_edge_graph(road)) ;
		//bus_graph<- bus_graph use_cache false;
		
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
			write "fps: "+round((1/mean(chrono))*10000)/10+"    ("+round(mean(chrono))+"ms per frame)";
			}
		m_time <- new_m_time;
	}
	
	
	action create_pedestrian(int nb) {
		create pedestrian number:nb{
		  current_trajectory <- [];
		  type <- "people";
			if flip(0.3) {
				target_place <- proba_choose_park.keys[rnd_choice(proba_choose_park.values)];
				target <- (any_location_in(target_place));
				location<-copy(target);
				state <- "stroll";
			} else {
				location<-any_location_in(one_of(road));
			}
		  	
		}
	}
	action create_cars(int nb) {
		create car number:nb{
		 	type <- "car";
		  	max_speed <- 160 #km / #h;
		  	speed<-meanSpeedCar + rnd(deviationSpeedCar);
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
	action manage_cycle_network {

		list<geometry> lines <- copy(bikelane_shapefile.contents);
		list<geometry> lines2 <- (roads_shapefile.contents);
		graph g <- as_edge_graph(lines);
		loop v over: g.vertices {
			if (g degree_of v) = 1{
				geometry r <- lines2 closest_to v;
				if (v distance_to r) < 20.0 {
					point pt <- (v closest_points_with r)[1];
					if (pt != first(r.points) and pt != last(r.points)) {
						lines2 >> r;
						list<geometry> sl <- r split_at pt;
						lines2 <- lines2 + sl;
					}
					lines2 << line([v,pt]);
				} 
			}
		}
		lines2 <- lines2 where (each != nil  and each.perimeter > 0);
		
		lines <- lines + lines2;
		lines <- clean_network(lines,3.0, true,true);
		
		list<float> ref <- bikelane_shapefile.contents collect each.perimeter;
		create bikelane from:lines{
			from_road <- not (shape.perimeter in ref) ;
			color<-from_road ? #red : type_colors["bike"];
		}
		create bikelane from:list(road);
		save bikelane type: shp to: "../includes/GIS/reseau-cyclable_reconnected.shp" with: [from_road::"from_road"];
		
	}
	
	reflex updateSimuState when:updateSim=true{
		currentSimuState <- (currentSimuState + 1) mod stateNumber;
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
	
	action manage_waiting_line {
		loop wl over: Waiting_line_shapefile.contents {
			culture cult <- culture closest_to wl;
			
			ask cult {
				queue <- wl;
				do manage_queue;
			}
			
		}
		ask culture where (each.queue = nil) {
			do default_queue;
		}
	}
	
	action updateSimuState {
		if (currentSimuState = 0){currentSimuState_str <- "present";}
		if (currentSimuState = 1){currentSimuState_str <- "future";}
		ask road {do change_number_of_lanes(lanes_nb[currentSimuState]);}
		ask intersection where(each.is_traffic_signal){do change_activity;}
		ask car {self.to_update <- true;}
		updateSim<-false;
		activated_parks <- park where (currentSimuState_str in each.state);
		activated_cultures <- culture where (currentSimuState_str in each.state);
		ask  (culture - activated_cultures) {
			ask waiting_tourists {
				do die;
			}
			waiting_tourists <- [];
		}
		list<agent> to_remove <- (park - activated_parks) + (culture - activated_cultures);
		ask pedestrian {
			if (target_place in to_remove) {
				do die;
			}
		}
		proba_choose_park <- activated_parks as_map (each::each.shape.area);
		//proba_choose_culture <- activated_cultures as_map (each::each.shape.area);
		proba_choose_culture <- activated_cultures as_map (each::each.capacity);

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
	  	
		
		int nb_people <- length(pedestrian);
		int nb_people_target <- round(nbAgent * get_mobility_ratio()["people"]);
		if (nb_people_target > nb_people) {
			do create_pedestrian(nb_people_target - nb_people);
		} else if (nb_people_target < nb_people) {
			ask (nb_people - nb_people_target) among pedestrian {
				do die;
			}
		}
		
		int nb_bikes <- length(bike);
		int nb_bikes_target <- round(nbAgent * get_mobility_ratio()["bike"]);
		if (nb_bikes_target > nb_bikes) {
			create bike number:nb_bikes_target - nb_bikes{
	      		type <- "bike";
		  		location<-any_location_in(one_of(building));	
			}
		} else if (nb_bikes_target < nb_bikes) {
			ask (nb_bikes - nb_bikes_target) among bike {
				do die;
			}
		}
		
		int nb_bus <- length(bus);
		int nb_bus_target <- round(nbAgent * get_mobility_ratio()["bus"]);
		if (nb_bus_target > nb_bus) {
			 create bus number:nb_bus_target - nb_bus{
	      		type <- "bus";
		  		location<-any_location_in(one_of(road));	
			}
		} else if (nb_bus_target < nb_bus) {
			ask (nb_bus - nb_bus_target) among bus {
				do die;
			}
		}
	}
	
	
	list<list<intersection>> find_connection(intersection i1, int state){
		list<intersection> reachable <-[];
		list<intersection> can_reach <-[];
		loop i over: driving_road_network[state].vertices - i1{
			if not(empty(path_between(driving_road_network[state],i1,intersection(i)).edges)){reachable <<i;}
			if not(empty(path_between(driving_road_network[state],intersection(i),i1).edges)){can_reach <<i;}
		}
		return [reachable, can_reach];
	}
		
}

species culture{
	list<string> state;
	string type;
	string style;
	float capacity;
	float capacity_per_min <- 1.0;
	geometry queue;
	list<pedestrian> people_waiting;
	list<pedestrian> waiting_tourists;
	list<point> positions;
	geometry waiting_area;
	
	//float queue_length <- 10.0;
	
	action default_queue {
		point pt <- any_location_in(shape.contour);
	 	float vect_x <- (location.x - pt.x) ; 
		float vect_y <- (location.y - pt.y) ; 
		
		queue <- line([pt, pt - {vect_x,vect_y}]);
		do manage_queue();
		
	}
	
	action manage_queue {
		positions <- queue points_on (2.0); 
		waiting_area <- (last(positions) + 10.0)  - (queue + 1.0);
	}
	action add_people(pedestrian the_tourist) {
		if (length(waiting_tourists) < length(positions)) {
			the_tourist.location <- positions[length(waiting_tourists)];
		} else {
			the_tourist.location  <- any_location_in(waiting_area);
		}
		waiting_tourists << the_tourist;
	}
	
	reflex manage_visitor when: not empty(waiting_tourists) and every(60 / capacity_per_min) {
		pedestrian the_tourist <- first(waiting_tourists);
		waiting_tourists >> the_tourist;
		the_tourist.ready_to_visit<-true;
		if (not empty(waiting_tourists)) {
			loop i from: 0 to: length(waiting_tourists) - 1 {
				if (i < length(positions)) {
					waiting_tourists[i].location <- positions[i];
				}
			}
		
		}
		
	}
	
	aspect base {
		if(showUsage and (currentSimuState_str in state)){
		  draw shape color: usage_colors[type];	
		  if(showWaitingLine){
		    draw queue color: #white;	
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
		if(showBuilding){
		  draw shape color:rgb(75,75,75) empty:true;	
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
	list<string> state;
	string type; 
	rgb color <- #darkgreen  ;
	
	aspect base {
		if(showGreen and (currentSimuState_str in state)){
		  draw shape color: nature_colors[type]-100 border:nature_colors[type];	
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
	list<bool> is_tunnel <- list_with(stateNumber,false);
	rgb color;
	string mode;
	float capacity;		
	string oneway;
	bool hot_spot <- false;
	bool to_display <- true;
	list<int> lanes_nb;
	list<list<point>> vec_ref;
	list<float> offset_list;
	list<float> angles;

	
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
		return offset_list[min(current_lane,max(0,lanes_nb[currentSimuState] -1))];
	}
	
//	float compute_offset(int current_lane){
//		return (oneway='no')?((lanes - min([current_lane,lanes -1]) - 0.5)*3 + 0.25):((0.5*lanes - min([current_lane, lanes - 1]) - 0.5)*3);
//	}
//	
	aspect base {
		if(showRoad and to_display){
			draw shape color:is_tunnel[currentSimuState]?rgb(50,0,0):type_colors["car"] width:1;	
		}
	}
}

species bikelane{
	bool from_road <- true;
	int lanes;
	aspect base {
		if(showBikeLane and not from_road){
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

species station schedules: station where (each.type="metro") {
	rgb color;
	string type;
	int capacity;
	float capacity_pca;
	float delay <- rnd(2.0,8.0) #mn ;
	
	//Create people going in and out of metro station
	reflex add_people when: (length(pedestrian) < nbAgent*mobilityRatioNow["people"]) and every(delay){
		
		create pedestrian number:rnd(0,10)*int(capacity){
			type<-"people";
			location<-any_location_in(myself);
		}
	}
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


species pedestrian skills:[moving] control: fsm{
	string type;
	agent target_place;
	point target;
	int stroll_time;
	int visiting_time;
	float speed_walk <- rnd(minSpeedPeople,maxSpeedPeople) #km/#h;
	bool to_exit <- false;
	float proba_sortie <- 0.3;
	float proba_wandering <- 0.5;
	float proba_culture <- 0.7;
	float offset <- rnd(0.0,2.0);
	
	bool wandering <- false;
	bool to_culture <- false;
	bool visiting <- false;
	bool ready_to_visit <- false;
	bool walking <- false;
	bool stroling_in_city<-false;
	bool stroling_in_park<-false;
	float val_f <- rnd(-max_dev,max_dev);
	list<point> current_trajectory;
	bool applyFuzzyness<-false;
	
	action updatefuzzTrajectory{
		if(showPeopleTrajectory){
			float val_pt <- val_f + rnd(-fuzzyness, fuzzyness);
		  	point pt <- applyFuzzyness ? location + {cos(heading + 90) * val_pt, sin(heading + 90) * val_pt} : location ;  
		    loop while:(length(current_trajectory) > ((currentSimuState=0) ? peopleTrajectoryLengthBefore : peopleTrajectoryLengthAfter))
	  	    {
	        current_trajectory >> first(current_trajectory);
	        }
	        current_trajectory << pt;	
		}
	}
	state walk_to_objective initial: true{
		enter {
			walking <- true;
			wandering <- false;
			to_culture <- false;
			float speed_walk_current <- speed_walk;
			if flip(proba_sortie) {
				target <- (station where (each.type="metro") closest_to self).location;
				to_exit <- true;
			} else {
				if flip(proba_wandering) {
					target <- any_location_in(agent(one_of(people_graph.edges)));
					wandering <- true;
					speed_walk_current <- speed_walk_current/ 3.0;
				} else {
					if flip(proba_culture) {
						target_place <- proba_choose_culture.keys[rnd_choice(proba_choose_culture.values)];
						to_culture <- true;
						target <- first(culture(target_place).positions);
					} else {
						target_place <- proba_choose_park.keys[rnd_choice(proba_choose_park.values)];
						target <- (target_place closest_points_with self) [0] ;
					}
				}
			}
		}
		do goto target: target on:people_graph speed: speed_walk_current;
		transition to: stroll_in_city when: not to_exit and wandering and location = target;
		transition to: stroll_in_park when: not to_exit and not wandering and not to_culture and location = target;
		transition to: queueing when: not to_exit and to_culture and location = target;
		transition to: outside_sim when:to_exit and location = target;
		do updatefuzzTrajectory;		
		exit {
			walking <- false;
		}	
	}
	
	
	state stroll_in_city {
		enter {
			stroll_time <- rnd(1, 10) *60;
			stroling_in_city<-true;
		}
		stroll_time <- stroll_time - 1;
		do wander amplitude:10.0 speed:2.0#km/#h;
		do updatefuzzTrajectory;
		transition to: walk_to_objective when: stroll_time = 0;
		exit{
			stroling_in_city<-false;
		}
	}
	
	
	state stroll_in_park {
		enter {
			stroll_time <- rnd(1, 10) * 60;
			stroling_in_park<-true;
		}
		stroll_time <- stroll_time - 1;
		do wander bounds:target_place amplitude:10.0 speed:2.0#km/#h;
		do updatefuzzTrajectory;
		transition to: walk_to_objective when: stroll_time = 0;
		exit{
		  stroling_in_park<-false;	
		}
	}
	
	state outside_sim {
		do updatefuzzTrajectory;
		do die;
	}
	
	//ce mot existe ?
	state queueing {
		enter {
			ask culture(target_place) {
				do add_people(myself);
			}
		}
		transition to: visiting_place when: ready_to_visit;
		do updatefuzzTrajectory;
		exit {
			visiting <- false;
			ready_to_visit <- false;
		}
	}
	
	state visiting_place {
		enter {
			visiting <- true;
			visiting_time <- rnd(1,10) * 60;
		}
		visiting_time <- visiting_time - 1;
		do wander bounds:target_place amplitude:10.0 speed:2.0#km/#h;
		do updatefuzzTrajectory;
		transition to: walk_to_objective when: visiting_time = 0;
		exit {
			visiting <- false;
		}
	}
	
	point calcul_loc {
		if (current_edge = nil) {
			return location;
		} else {
			float val <- (road(current_edge).lanes +1)*3 +offset;
			if (val = 0) {
				return location;
			} else {
				return (location + {cos(heading + 90) * val, sin(heading + 90) * val});
			}
		}
	} 
	
	aspect base{
		if(showPeople){
			 draw square(peopleSize) color:type_colors[type] at:walking ? calcul_loc() :location rotate: angle;	
		}
		if(showPeopleTrajectory){
	       draw line(current_trajectory) color: rgb(type_colors[type].red,type_colors[type].green,type_colors[type].blue,(currentSimuState = 0) ? peopleTrajectoryTransparencyBefore : peopleTrajectoryTransparencyAfter);	
	  	}	
	}
}

species bike skills:[moving]{
	string type;
	point my_target;
	list<point> current_trajectory;
	
	reflex choose_target when: my_target = nil {
		my_target <- any_location_in(one_of(bikelane));
	}
	reflex move{
	  do goto on: bike_graph target: my_target speed: 8#km/#h move_weights:weights_bikelane ;
	  if (my_target = location) {my_target <- nil;}
	  loop while:(length(current_trajectory) > ((currentSimuState=0) ? bikeTrajectoryLengthBefore : bikeTrajectoryLengthAfter))
  	    {
        current_trajectory >> first(current_trajectory);
        }
        current_trajectory << location;
	}
	aspect base{
		if(showBike){
		 draw rectangle(bikeSize,bikeSize*2) color:type_colors[type] rotate:heading-90;	
		}	
		if(showBikeTrajectory){
	       draw line(current_trajectory) color: rgb(type_colors[type].red,type_colors[type].green,type_colors[type].blue,(currentSimuState = 0) ? bikeTrajectoryTransparencyBefore : bikeTrajectoryTransparencyAfter);	
	  }
	}
}


species bus skills:[moving]{
	string type;
	point my_target;
	list<point> current_trajectory;
	
	reflex choose_target when: my_target = nil {
		my_target <- any_location_in(one_of(road));
	}
	reflex move{
	  do goto on: bus_graph target: my_target speed: 15#km/#h ;
	  if (my_target = location) {my_target <- nil;}
	  loop while:(length(current_trajectory) > ((currentSimuState=0) ? busTrajectoryLengthBefore : busTrajectoryLengthAfter))
  	    {
        current_trajectory >> first(current_trajectory);
        }
        current_trajectory << location;
	}
	aspect base{
		if(showSharedMobility){
		 draw rectangle(busSize,busSize*3) color:type_colors[type] rotate:heading-90;	
		}	
		if(showSharedMobilityTrajectory){
	       draw line(current_trajectory) color: rgb(type_colors[type].red,type_colors[type].green,type_colors[type].blue,(currentSimuState = 0) ? busTrajectoryTransparencyBefore : busTrajectoryTransparencyAfter);	
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
	intersection target_intersection;
	string nationality;
	string profile;
	string aspect;
	string type;
	float speed;
	bool in_tunnel -> current_road != nil and road(current_road).is_tunnel[currentSimuState];
	list<point> current_trajectory;
	intersection current_intersection;
	point target;
	
	

	
	
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
		if smoothTrajectory{
			if (old_segment_index != segment_index_on_road) or (old_index != current_index){
				target_offset <- compute_offset(3);
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
	}
	


//	bool use_blocked_road {
//		if currentSimuState = 0 {return false;}
//		if (current_path = nil) {/*write "reason nil path";
//			write "car "+ int(self); 
//			write current_path;*/
//	//		ask world {do pause;}
//			return false;
//		}
//		loop rd over:current_path.edges {
//			if road(rd).lanes_nb[1] = 0 {
//				//write "blocked road: "+road(rd);
//				return true;
//			}
//		}
//		return false;	
//	}
	
	
	reflex leave when: final_target = nil  {
		if (target_intersection != nil and target_intersection.exit[currentSimuState]=target_intersection) {// reached an exit
			if current_road != nil {
				ask current_road as road {
					do unregister(myself);
				}
			}
			current_lane <- 0;
			current_intersection <- one_of(possible_sources[currentSimuState]);
			location <-current_intersection.location;
			target_intersection <- one_of(possible_targets[currentSimuState] - current_intersection);
			current_trajectory <- [];
			current_offset <- {0,0};
		}else if (target_intersection != nil and target_intersection.exit[currentSimuState] != nil) {// reached a dead end
			target_intersection <- target_intersection.exit[currentSimuState];
		}else{ // reached a generic target
			target_intersection <- one_of(possible_targets[currentSimuState] - current_intersection);
		}
		current_path <- compute_path(graph: driving_road_network[currentSimuState], target: target_intersection);
	}
	
	
	reflex move when: final_target != nil{	
	  	do drive;	
	  	//on tente le tout pour le tout
	  	loop while:(length(current_trajectory) > ((currentSimuState =0) ? carTrajectoryLengthBefore : carTrajectoryLengthAfter))
  	    {
        current_trajectory >> first(current_trajectory);
        }
        current_trajectory << location+current_offset;
	}
	
	
	action update{// il reste du code pour debuguer a nettoyer, ne pas trop toucher aux trucs chelous
		path new_path;
		if current_road != nil{
			if road(current_road).lanes_nb[currentSimuState] = 0{//current road is not good. Fading
				fade_count <- 15;
			}else{//current road is good
				intersection ci <- driving_road_network[currentSimuState] target_of current_road;
				if (target_intersection in possible_targets[currentSimuState]) and (ci != target_intersection) {// target is good. Computing a new path				
					point save_location <- location;
					road cr <- road(current_road);
					location <- last(cr.shape.points);			
					if ci.exit[currentSimuState] != nil{// current intersection is in a dead end
						target_intersection<- ci.exit[currentSimuState];
					}		
					new_path <- compute_path(graph: driving_road_network[currentSimuState], target: target_intersection);
//					if new_path = nil{
//						write "Error";
//					}
					current_path <- ([cr]+list<road> (new_path.edges)) as_path driving_road_network[currentSimuState];
					ask current_road as road {
						do unregister(myself);
					}
					current_road <- cr;
					ask cr{
						do register(myself, 0);// remplacer 0 par lane
					}
					current_index <- 0;
					final_target <- target_intersection.location;
					targets <- list<point> (current_path.edges accumulate (driving_road_network[currentSimuState] target_of each));
					current_target <- first(targets);					
					location <- save_location;
				}else{//target is not good or car in last road of path
					current_path <- [road(current_road)] as_path driving_road_network[currentSimuState];
					target_intersection <- driving_road_network[currentSimuState] target_of current_road;
					current_index <- 0;
					final_target <- target_intersection.location;
					current_target <- final_target;
					targets <- [final_target];
				}	
			}			
		}
		to_update <- false;	
	}

	reflex fade when: (fade_count > 0){
		fade_count <- fade_count - 1;
		if fade_count = 0{
			if current_road != nil {
				ask current_road as road {
					do unregister(myself);
				}
			}			
			current_intersection <- one_of(possible_sources[currentSimuState]);
			location <-current_intersection.location;
			target_intersection <- one_of(possible_targets[currentSimuState]);
			current_path <- compute_path(graph: driving_road_network[currentSimuState], target: target_intersection);
			final_target <- target_intersection.location;
			current_lane <- 0;
			current_trajectory <- [];
			current_offset <- {0,0};
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
		    draw rectangle(carSize,carSize*3) at: calcul_loc() rotate:heading-90 color:in_tunnel?rgb(50,0,0):rgb(type_colors[type],(fade_count=0)?1:fade_count/20);	   
	  	}
	  	if(showCarTrajectory){
	       draw line(current_trajectory) color: rgb(type_colors[type].red,type_colors[type].green,type_colors[type].blue,(currentSimuState = 0) ? carTrajectoryTransparencyBefore : carTrajectoryTransparencyAfter);	
	  	}
	  	if (test_car){
	  		
	  		if current_path != nil{
	  			loop e over: current_path.edges{
	  				draw 1 around(road(e).shape) color: #white;
	  			}
	  		}
	  		loop p over: targets{
	  			draw circle(2#m) at: p color: #black; 
	  		}
	  		draw circle(2#m) at: first(targets) color: #yellow; 
	  		draw circle(2#m) at: last(targets) color: #yellow; 
	  		draw circle(2#m) at: current_target color: #blue;
	  		draw circle(5#m) at: location color:#blue; 
	  	}
	}	
	

	

		
	point compute_offset(int s){	
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
					weight <- weight + w;
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
		return offset_comp / weight;
		}	
	}
	
	
	
//	point compute_offset(int s){
//		if current_road = nil or current_path = nil{
//			return current_offset;
//		}else{
//			int ci <- current_index;
//			int cs <- segment_index_on_road;
//			list<list<point>> segment_list <- [];
//			list<road> lr <- [];
//			list<list<point>> tmp_vec_ref <- [];
//			int count <- 0;
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
//			list<point> offset_list <- [tmp_vec_ref[0][1]*lr[0].compute_offset(current_lane)];
//			list<float> weight_list <- [1.0];
//			loop i from: 0 to: length(segment_list) - 2 step: 1{		
//				float a <- angle_between(last(segment_list[i]),first(segment_list[i]),last(segment_list[i+1]));
//				if !is_number(a){//probleme de precision avec angle_between qui renvoie un #nan
//					a <- 180.0;
//				}
//				weight_list << 1+abs(a-180);
//				if abs(abs(a-90)-90)<5{
//					offset_list << tmp_vec_ref[i][1]*lr[i].compute_offset(current_lane);
//				}else{
//					offset_list << (tmp_vec_ref[i][0]*lr[i+1].compute_offset(current_lane)-tmp_vec_ref[i+1][0]*lr[i].compute_offset(current_lane))/sin(a);
//				}
//			}
//			if (test_car){
//				loop i from: 0 to: length(segment_list) - 2 step: 1{
//					draw circle(1#m) at: last(segment_list[i]) color: rgb(255 - i *100,255 - i*100,255); 
//					draw circle(0.5#m) at:  last(segment_list[i])+offset_list[i+1] color: rgb(255 - i *100,255 - i*100,255); 
//				}	
//			}
//			point offset <- {0,0};
//			loop i from: 0 to: length(offset_list)-1{
//				offset <- offset + offset_list[i]*weight_list[i];
//			}
//			// ne pas effacer ce qui suit, peut servir pour des tests et ameliorer le smooth 
////			if norm(offset/sum(weight_list)) > 100 {
////				write "car: "+int(self)+ " "+ norm(offset/sum(weight_list))+" offset "+ offset/sum(weight_list);//+" angle "+a;
////				write "offset list "+offset_list;
////				write "angles "+angles;
////				write angles accumulate (abs(abs(a-90)-90));
////				loop i from: 0 to: length(offset_list)-1{
////					write "offset "+i+": "+tmp_vec_ref[i][1]*lr[i].compute_offset(current_lane);
////				}
//////				write "vec_ref "+tmp_vec_ref[i][0]+"/"+tmp_vec_ref[i+1][0]+" "+lr[i].compute_offset(current_lane)+"/"+lr[i+1].compute_offset(current_lane);
//////				write tmp_vec_ref[i][0]*lr[i+1].compute_offset(current_lane);
//////				write tmp_vec_ref[i+1][0]*lr[i].compute_offset(current_lane);
//////				write sin(a);
//////				write tmp_offset;
////				ask world {do pause;}
////			}
//			return offset / sum(weight_list);
//		}
//	}

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
	list<bool> reachable_by_all <- list_with(stateNumber,false);
	list<bool> can_reach_all <- list_with(stateNumber,false);
	list<intersection> exit <- list_with(stateNumber, nil);
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
		if (active and is_traffic_signal and showTrafficSignal) {
			draw circle(5) color: color_fire;
		}
		if showTrafficSignal{
			draw circle(3#m) color: color;
		}
	}
}

species coldSpot{
		aspect base {
			if(showHotSpot){
			  draw shape color:rgb(0,0,0);	
			}	
		}
}

experiment ReChamp type: gui autorun:true{
	float minimum_cycle_duration<-0.025;	
	output {
		display champ type:opengl background:#black draw_env:false fullscreen:1  rotate:angle toolbar:false autosave:false synchronized:true
		camera_pos: {1812.4353,1521.5935,2609.8917} camera_look_pos: {1812.4353,1521.548,0.0} camera_up_vector: {0.0,1.0,0.0}
	   	{
	   	    species graphicWorld aspect:base;	    	
	    	species intervention aspect: base;
		    species building aspect: base;
			species park aspect: base transparency:0.5;
			species culture aspect: base transparency:0.5;
			species water aspect: base;
			species road aspect: base;
			species vizuRoad aspect:base transparency:0.5;
			species bus_line aspect: base;
			species metro_line aspect: base;
			species amenities aspect:base;
			species intersection;
			species car aspect:base transparency:0.5;
			species pedestrian aspect:base;
			species bike aspect:base transparency:0.5;
			species bus aspect:base transparency:0.5;
			species coldSpot aspect:base transparency:0.6;
			species station aspect: base;
			species bikelane aspect:base;

									
			graphics 'tablebackground'{
				draw geometry(shape_file_bounds) color:#white empty:true;
				draw string("State: " + currentSimuState) rotate:angle at:{400,400} color:#white empty:true;
			}
			
			event["p"] action: {showPeople<-!showPeople;};
			event["c"] action: {showCar<-!showCar;};
			event["b"] action: {showBike<-!showBike;};
			event["s"] action: {showSharedMobility<-!showSharedMobility;};
			event["g"] action: {showGif<-!showGif;};
			event["l"] action: {showBuilding<-!showBuilding;};
			event["r"] action: {showRoad<-!showRoad;};
			event["m"] action: {showVizuRoad<-!showVizuRoad;};
			event["v"] action: {showBikeLane<-!showBikeLane;};
			event["i"] action: {showIntervention<-!showIntervention;};
			event["q"] action: {showMetroLane<-!showMetroLane;};
			event["j"] action: {showBusLane<-!showBusLane;};
			event["s"] action: {showStation<-!showStation;};
			event["a"] action: {showAmenities<-!showAmenities;};
			event["n"] action: {showGreen<-!showGreen;};
			event["u"] action: {showUsage<-!showUsage;};
			event["w"] action: {showWater<-!showWater;};
			event["h"] action: {showHotSpot<-!showHotSpot;};
			event["f"] action: {showTrafficSignal<-!showTrafficSignal;};			
			event["z"] action: {updateSim<-true;};
			//event["1"] action: {if(currentSimuState!=1){currentSimuState<-1;updateSim<-true;}};
		}
	}
}


experiment ReChamp2Proj parent:ReChamp autorun:true{	
	
	output {	
		layout #split;
		display indicator type:opengl background:#black draw_env:false fullscreen:1 toolbar:false
		//camera_pos: {1812.4353,1521.574,1490.9658} camera_look_pos: {1812.4353,1521.548,0.0} camera_up_vector: {0.0,1.0,0.0}
		{
			/*graphics 'dashboardbackground'{
				draw rectangle(1920,1080) texture:dashboardbackground.path at:{world.shape.width/2,world.shape.height/2}color:#white empty:true;
				
			}*/
			
			graphics "state" {
				float textSize<-10#px;
				float spacebetween<-200#px;
				float spacebetweenSame<-250#px;
				draw ((currentSimuState = 0 ) ? "Today" :"2024") color: #white font: font("Helvetica", textSize*2, #bold) at: {world.shape.width*0.75,world.shape.height*0.25};
				if(currentStoryTellingState=1 or currentStoryTellingState=4){
				  draw (catchPhrase[0]) color: type_colors["car"] font: font("Helvetica", textSize, #bold) at: {0,world.shape.height/4};
				  draw ("Véhicules Individuels 55%") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {0,world.shape.height/4+textSize*2};
				  draw ("Véhicules Partagés 55%") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {0,world.shape.height/4+textSize*4};
				  draw ("Mobilités Douces 55%") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {0,world.shape.height/4+textSize*6};
				  draw ("Espace Piéton 55%") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {0,world.shape.height/4+textSize*8};	
				  
				  draw ("Emission de CO2 55") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame,world.shape.height/4+textSize*2};
				  draw ("Vehicule/heure: 1000") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame,world.shape.height/4+textSize*4};
				  
				  draw ("Arret de bus:10") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame*2,world.shape.height/4+textSize*2};
				  draw ("Stations de Vélos:500") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame*2,world.shape.height/4+textSize*4};			
				}
				if(currentStoryTellingState=2 or currentStoryTellingState=5){
				  draw (catchPhrase[0]) color: type_colors["car"] font: font("Helvetica", textSize, #bold) at: {0,world.shape.height/4};
				  draw ("Véhicules Individuels 55%") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {0,world.shape.height/4+textSize*2};
				  draw ("Véhicules Partagés 55%") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {0,world.shape.height/4+textSize*4};
				  draw ("Mobilités Douces 55%") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {0,world.shape.height/4+textSize*6};
				  draw ("Espace Piéton 55%") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {0,world.shape.height/4+textSize*8};	
				  
				  /*draw ("Emission de CO2 55") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame,world.shape.height/4+textSize*2};
				  draw ("Vehicule/heure: 1000") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame,world.shape.height/4+textSize*4};
				  
				  draw ("Arret de bus:10") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame*2,world.shape.height/4+textSize*2};
				  draw ("Stations de Vélos:500") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame*2,world.shape.height/4+textSize*4};	*/	
				  
				  
				  draw (catchPhrase[1]) color: type_colors["bus"] font: font("Helvetica", textSize, #bold) at: {0+spacebetween,world.shape.height/4+spacebetween};
				  draw ("Pleine Terre 30 000 m2") color: type_colors["bus"] font: font("Helvetica", textSize/3, #bold) at: {0+spacebetween,world.shape.height/4+textSize*2+spacebetween};
				  draw ("Strate Arbustrive 30 000m2") color: type_colors["bus"] font: font("Helvetica", textSize/3, #bold) at: {0+spacebetween,world.shape.height/4+textSize*4+spacebetween};
				  draw ("Sol Perméable 55%") color: type_colors["bus"] font: font("Helvetica", textSize/3, #bold) at: {0+spacebetween,world.shape.height/4+textSize*6+spacebetween};
				  draw ("Sol Imperméable 55%") color: type_colors["bus"] font: font("Helvetica", textSize/3, #bold) at: {0+spacebetween,world.shape.height/4+textSize*8+spacebetween};	
				  
				  draw ("Coefficient de Biotope: 5%") color: type_colors["bus"] font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame+spacebetween,world.shape.height/4+textSize*2+spacebetween};
				  draw ("Nombre d'arbes: 55 000") color: type_colors["bus"] font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame+spacebetween,world.shape.height/4+textSize*4+spacebetween};
				  
				  draw ("Volume Evapo-Transpiré: 55%") color: type_colors["bus"] font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame*2+spacebetween,world.shape.height/4+textSize*2+spacebetween};
				  draw ("Abbatement sur pluie 12mm: 55%") color: type_colors["bus"] font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame*2+spacebetween,world.shape.height/4+textSize*4+spacebetween};
				}
				if(currentStoryTellingState=3 or currentStoryTellingState=6){
				  draw (catchPhrase[0]) color: type_colors["car"] font: font("Helvetica", textSize, #bold) at: {0,world.shape.height/4};
				  draw ("Véhicules Individuels 55%") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {0,world.shape.height/4+textSize*2};
				  draw ("Véhicules Partagés 55%") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {0,world.shape.height/4+textSize*4};
				  draw ("Mobilités Douces 55%") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {0,world.shape.height/4+textSize*6};
				  draw ("Espace Piéton 55%") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {0,world.shape.height/4+textSize*8};	
				  
				  /*draw ("Emission de CO2 55") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame,world.shape.height/4+textSize*2};
				  draw ("Vehicule/heure: 1000") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame,world.shape.height/4+textSize*4};
				  
				  draw ("Arret de bus:10") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame*2,world.shape.height/4+textSize*2};
				  draw ("Stations de Vélos:500") color: type_colors["car"] font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame*2,world.shape.height/4+textSize*4};	*/	
				  
				  
				  draw (catchPhrase[1]) color: type_colors["bus"] font: font("Helvetica", textSize, #bold) at: {0+spacebetween,world.shape.height/4+spacebetween};
				  draw ("Pleine Terre 30 000 m2") color: type_colors["bus"] font: font("Helvetica", textSize/3, #bold) at: {0+spacebetween,world.shape.height/4+textSize*2+spacebetween};
				  draw ("Strate Arbustrive 30 000m2") color: type_colors["bus"] font: font("Helvetica", textSize/3, #bold) at: {0+spacebetween,world.shape.height/4+textSize*4+spacebetween};
				  draw ("Sol Perméable 55%") color: type_colors["bus"] font: font("Helvetica", textSize/3, #bold) at: {0+spacebetween,world.shape.height/4+textSize*6+spacebetween};
				  draw ("Sol Imperméable 55%") color: type_colors["bus"] font: font("Helvetica", textSize/3, #bold) at: {0+spacebetween,world.shape.height/4+textSize*8+spacebetween};	
				  
				  /*draw ("Coefficient de Biotope: 5%") color: type_colors["bus"] font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame+spacebetween,world.shape.height/4+textSize*2+spacebetween};
				  draw ("Nombre d'arbes: 55 000") color: type_colors["bus"] font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame+spacebetween,world.shape.height/4+textSize*4+spacebetween};
				  
				  draw ("Volume Evapo-Transpiré: 55%") color: type_colors["bus"] font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame*2+spacebetween,world.shape.height/4+textSize*2+spacebetween};
				  draw ("Abbatement sur pluie 12mm: 55%") color: type_colors["bus"] font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame*2+spacebetween,world.shape.height/4+textSize*4+spacebetween};*/
				  
				  draw (catchPhrase[2]) color: #yellow font: font("Helvetica", textSize, #bold) at: {0+spacebetween*1.5,world.shape.height/4+spacebetween*2};
				  draw ("Offre Gastronomiques: 20") color: #yellow font: font("Helvetica", textSize/3, #bold) at: {0+spacebetween*1.5,world.shape.height/4+textSize*2+spacebetween*2};
				  draw ("Surface Pique-Nique 3 000 m2") color: #yellow font: font("Helvetica", textSize/3, #bold) at: {0+spacebetween*1.5,world.shape.height/4+textSize*4+spacebetween*2};
				  draw ("Surface Pietonne 30 000m2") color: #yellow font: font("Helvetica", textSize/3, #bold) at: {0+spacebetween*1.5,world.shape.height/4+textSize*6+spacebetween*2};
				  draw ("Surface Ombragée 30 000m2") color: #yellow font: font("Helvetica", textSize/3, #bold) at: {0+spacebetween*1.5,world.shape.height/4+textSize*8+spacebetween*2};	
				  
				  draw ("Espaces de rencontre :55 000 m2") color: #yellow font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame+spacebetween*1.5,world.shape.height/4+textSize*2+spacebetween*2};
				  draw ("Equipement Sportifs: 55 000m2") color: #yellow font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame+spacebetween*1.5,world.shape.height/4+textSize*4+spacebetween*2};
				  
				  draw ("Volume Evapo-Transpiré: 55%") color: #yellow font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame*2+spacebetween*1.5,world.shape.height/4+textSize*2+spacebetween*2};
				  draw ("Abbatement sur pluie 12mm: 55%") color: #yellow font: font("Helvetica", textSize/3, #bold) at: {spacebetweenSame*2+spacebetween*1.5,world.shape.height/4+textSize*4+spacebetween*2};
				}
			}
			

		}
	}
}

