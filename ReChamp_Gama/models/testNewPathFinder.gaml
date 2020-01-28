  /***
* Name: validateShapeFile
* Author: Arnaud Grignard, Tri Nguyen-Huu, Patrick Taillandier, Nicolas Ayoub 
* Description: ReChamp - 2019
* Tags: Tag1, Tag2, TagN
***/

model shapeFileTester

global {
	
	
	//EXISTING SHAPEFILE (FROM OPENDATA and OPENSTREETMAP)
	file shape_file_bounds <- file("../includes/GIS/TableBounds.shp");	
	file roads_shapefile <- file("../includes/GIS/roads_OSM.shp");
	file nodes_shapefile <- file("../includes/GIS/nodes_OSM.shp");
	file signals_zone_shapefile <- file("../includes/GIS/signals_zone.shp");
	file intervention_shapefile <- file("../includes/GIS/Intervention.shp");	
	file origin_destination_shapefile <- shape_file("../includes/GIS/origin_destination_line.shp");		
	geometry shape <- envelope(shape_file_bounds);

	float proba_used_od <- 1.0;
	list<road> sp;
	list<road> lp;
	list<road> pb;
	list<road> djk;
	map<road,float> general_speed_map;	

	list<graph> driving_road_network;
	float dist_group_traffic_light <- 50.0;

	bool showCar parameter: 'Car (c)' category: "Agent" <-true;
	bool showCarTrajectory parameter: 'Car Trajectory' category: "Trajectory" <-true;
	int carTrajectoryLength <-25 parameter: 'Car Trajectory length' category: "Trajectory" min: 0 max: 50;

	bool smoothTrajectory parameter: 'Smooth Trajectory' category: "Trajectory" <-true;
	float trajectoryTransparency <-0.5 parameter: 'Trajectory transparency' category: "Trajectory" min: 0.0 max: 1.0;
	bool showTrafficSignal parameter: 'Traffic signal (t)' category: "Parameters" <-false;
	bool showRoad parameter: 'Road Simu(r)' category: "Parameters" <-true;
	bool showIntervention parameter: 'Intervention (i)' category: "Parameters" <-false;
	bool showBackground <- false parameter: "Background (Space)" category: "Parameters";
	float dotPoint <-2.0#m parameter: 'Dot size' category: "Parameters" min: 0.5#m max: 5.0#m;
	 
	bool right_side_driving <- true;
	
	map<string, rgb> type_colors <- ["default"::#white,"people"::#yellow, "car"::rgb(255,0,0),"bike"::rgb(18,145,209), "bus"::rgb(131,191,98)];
	
	
	float angle<-26.25;

	int stateNumber <- 2;
	string currentSimuState_str <- "present" among: ["present", "future"];
	int currentSimuState<-0;
	bool updateSim<-true;
	int nbAgent<-1000;
	float step <- 10 #sec;
	map<string,float> mobilityRatioNow <-["people"::0.49, "car"::0.3,"bike"::0.2, "bus"::0.01];

	list<list<intersection>> input_intersections <-list_with(stateNumber, []);
	list<list<intersection>> output_intersections <-list_with(stateNumber, []);
	list<list<intersection>> possible_targets <-list_with(stateNumber, []);
	list<list<intersection>> possible_sources <-list_with(stateNumber, []);

	list<intersection> vertices;
	list<map<int,int>> od_weights <- list_with(stateNumber, nil);
	list<map<int,intersection>> od_origins <- list_with(stateNumber, nil);
	list<map<int,intersection>> od_destinations <-list_with(stateNumber, nil);
	
	init {
		
		//------------------ STATIC AGENT ----------------------------------- //
	
		create intersection from: nodes_shapefile with: [is_traffic_signal::(read("type") = "traffic_signals"),  is_crossing :: (string(read("crossing")) = "traffic_signals"), group :: int(read("group")), phase :: int(read("phase"))];
		create signals_zone from: signals_zone_shapefile;
		create road from: roads_shapefile with: [lanes_nb::[int(read("lanes")),int(read("pro_lanes"))], oneway::string(read("oneway")), is_tunnel::[(read("tunnel")="yes"?true:false),(read("pro_tunnel")="yes"?true:false)]] {
			maxspeed <- (lanes = 1 ? 30.0 : (lanes = 2 ? 40.0 : 50.0)) °km / °h;
			lanes <- lanes_nb[currentSimuState];
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
			perimeter <- shape.perimeter;
			tmp <- perimeter/maxspeed;
			tmp2 <-  tmp/(1+lanes)^2;
		}
		
		
		vertices <- list<intersection>((as_driving_graph(road, intersection)).vertices);
		loop i from: 0 to: length(vertices) - 1 {
			vertices[i].id <- i; 
		}
		
		
		ask intersection where each.is_traffic_signal{
			if empty(signals_zone overlapping self){
				is_traffic_signal <- false;
			}
		}
		do init_traffic_signal;
		loop j from: 0 to: stateNumber - 1{
			ask intersection where each.is_traffic_signal {
				activityStates[j] <- (roads_in first_with (road(each).lanes_nb[j] > 0) != nil);	//roads_in has already been calculated at this point ?
			}
		}
		
	
		
		loop j from: 0 to:  stateNumber-1{
			general_speed_map <- road as_map (each::((each.hot_spot ? 1 : 10) * (each.shape.perimeter / each.maxspeed)/(1+each.lanes)));
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
		
		loop j from: 0 to: stateNumber - 1{
			int index <- 0;
			loop pt over: origin_destination_shapefile.contents {
				int weight <- int(pt.attributes['capacity']);
				intersection i <- possible_sources[j] closest_to first(pt.points);
				intersection o <- possible_targets[j] closest_to last(pt.points);
				od_weights[j] << index::weight;
				od_origins[j] << index::i;
				od_destinations[j] << index::o;
				index <- index + 1;	
			} 
		}
		
		loop j from: 0 to: stateNumber - 1{
			loop k over: od_weights[j].keys {
				intersection i <- od_origins[j][k];
				intersection o <- od_destinations[j][k];
				if i.reachable_by_all[j] {
					write "Warning: input intersection "+i+" is not a pure input location.";
				}
				if o.can_reach_all[j] {
					write "Warning: output intersection "+o+" is not a pure output location.";
				}
			} 
		}
	
		write "test connection";
		do updateSimuState;
		
	
		
		//------------------- AGENT ---------------------------------------- //
		
		do create_cars(round(nbAgent*world.get_mobility_ratio()["car"]));
		
		
		ask first(10,car){test_car <- true;}
		
		ask first(car){
			test_car <- true;
			location <- intersection[2072].location;
			current_intersection <- intersection[2072];
			current_path <- new_shortest_path(driving_road_network[currentSimuState], intersection[2028], general_speed_map);
			float longueur <- sum(current_path.edges accumulate (road(each).perimeter));
			write "longueur chemin "+self+": "+longueur;
			float l2 <- sum(current_path.edges accumulate (float(general_speed_map[road(each)])));
			write "longueur avec poids: "+l2;
			write current_path;
			write "";
		}
		
		//	map general_speed_map <- road as_map (each::((each.hot_spot ? 1 : 50) * (each.shape.perimeter / each.maxspeed)/(1+each.lanes)^2));
		 sp <- [road(3187),road(3206),road(3205),road(3177),road(3289),road(3288),road(3176),road(3175),road(3174),road(3287),road(3173),road(3186),road(3185),road(3184),road(3307),road(3183),road(3182),road(1782),road(2082),road(2081),road(2103),road(1783),road(1784)];
	//	list<road> lp <- [road(3187),road(3206),road(3205),road(3177),road(3289),road(3288),road(3176),road(3175),road(3174),road(3287),road(3173),road(3186),road(3185),road(1585),road(1586),road(1587),road(1588),road(3047),road(3046),road(3045),road(3044),road(2775),road(2082),road(2081),road(2103),road(1783),road(1784)];
		 lp <- [road(2193),road(562),road(563),road(564),road(1145),road(1146),road(1147),road(1148),road(1149),road(1150),road(2965),road(3051),road(3050),road(3049),road(3048),road(1870),road(1871),road(1872),road(1873),road(3212),road(3211),road(3210),road(2754),road(2753),road(2081),road(2103),road(1783),road(1784)];
		
		write "chemin le plus court est valide (vert) ? "+check_path_validity(sp);
		write "chemin le plus long est valide (jaune) ? "+check_path_validity(lp);
		
		write "longeur chemin court (vert): "+sum(sp accumulate(each.perimeter));
		write "longeur chemin long (jaune): "+sum(lp accumulate(each.perimeter));
		write "longeur poids chemin court (weight map actuelle) (vert): "+sum(sp accumulate(float(general_speed_map[each])));
		//	write sp accumulate(general_speed_map[each]);
		write "longeur poids chemin long (weight map actuelle) (jaune): "+sum(lp accumulate(float(general_speed_map[each])));
		
		
		pb <- path_between(driving_road_network[currentSimuState],intersection[2072],intersection[2028]).edges accumulate(road(each));
//		djk <- first(car).new_shortest_path(driving_road_network[currentSimuState], intersection[2072].location, intersection[2028], general_speed_map);
		write "longeur poids chemin le plus court (bleu): "+sum(pb accumulate(float(general_speed_map[each])));
//		write "longeur poids chemin le plus court (Dijstra, violet): "+sum(djk accumulate(float(general_speed_map[each])));
				
		//First Intervention (Paris Now)
		create intervention from:intervention_shapefile with: [id::int(read ("id")),type::string(read ("type"))]
		{   
			do initialize;
			interventionNumber<-1;
			isActive<-true;
		}
		//Second Intervention (PCA proposal)
		create intervention from:intervention_shapefile with: [id::int(read ("id")),type::string(read ("type"))]
		{   
			do initialize;
			interventionNumber<-2;
			isActive<-false;
		}	
 
	}
	
	map<string,float> get_mobility_ratio {
		return mobilityRatioNow;
	}
	
	bool check_path_validity(list<road> l){
		bool res <- true;
		int i <- 0;
		loop i from: 0 to: length(l)-2 {
			if driving_road_network[currentSimuState] target_of l[i] != driving_road_network[currentSimuState] source_of l[i+1]{
				res <- false;
			}
		}
		
		return res;
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
				if flip(proba_used_od) {
			//	intersection i <- od_origins[currentSimuState].values[rnd_choice(od_weights[currentSimuState].values)];
			//	current_intersection <- one_of(origin_intersections[currentSimuState]);
				int od_index <- rnd_choice(od_weights[currentSimuState].values);
				current_intersection <- od_origins[currentSimuState].values[od_index];
				target_intersection <- od_destinations[currentSimuState].values[od_index];
			} else {
				current_intersection <- one_of(possible_sources[currentSimuState]);
			}
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
	
	reflex updateSimuState when:updateSim=true{
		currentSimuState <- (currentSimuState + 1) mod stateNumber;
		do updateSimuState;
	}

	reflex update_cars {
		ask first(100,shuffle(car where(each.to_update))){
			do update;
		}
	}
	

	
	action updateSimuState {
		write "changing at cycle "+cycle+" to state "+currentSimuState;
		if (currentSimuState = 0){currentSimuState_str <- "present";}
		if (currentSimuState = 1){currentSimuState_str <- "future";}
		ask intersection where(each.is_traffic_signal){do change_activity;}
		
//		if (driving_road_network != nil) {
//			map general_speed_map <- road as_map (each:: !each.to_display ? 1000000000.0 : ((each.hot_spot ? 1 : 10) * (each.shape.perimeter / each.maxspeed)/(1+each.lanes)));
//			driving_road_network <- driving_road_network with_weights general_speed_map;
//		}
		ask car {self.to_update <- true;}
		updateSim<-false;
	  	
		
	}
	// ne pas effacer ce qui suit, c'est pour des tests tant qu'on risque de modifier les shapefiles
	action check_signals_integrity {
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



species road  skills: [skill_road]  {
	float perimeter;
	float tmp;
	float tmp2;
	int id;
	list<bool> is_tunnel <- list_with(stateNumber,false);
	rgb color;
	string mode;
	float capacity;		
	string oneway;
	bool hot_spot <- false;
	bool to_display <- true;
	list<int> lanes_nb;


	
	
	aspect base {
		if(showRoad and to_display){
			draw shape color:is_tunnel[currentSimuState]?rgb(50,0,0):type_colors["car"] width:1;	
			if self in sp{
				draw 3 around(shape) color: #green;
			}
			if self in lp{
				draw 3 around(shape) color: #yellow;
			}
//			if self in pb{
//				draw 5 around(shape) color: #blue;
//			}
			if self in djk{
				draw 5 around(shape) color: #purple;
			}
		}
	}

}









species car skills:[advanced_driving]{
	bool to_update <- false;
	bool test_car <- false;
	point target_offset <- {0,0};
	int fade_count <- 0;
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
	
	path new_shortest_path(graph g, intersection dest, map<road, float> m){
		intersection init_i <- intersection closest_to self.location;
		list<intersection> visited_intersections <- [];
		map<intersection, float> path_length <- [init_i::0.0];
		map<intersection, list<road>> paths <- [init_i::[]];
		write "computing path for "+self;
		loop while: not(dest in visited_intersections){
			list<intersection> candidates_targets <- path_length.keys - visited_intersections;
			intersection next_i <- candidates_targets with_min_of (path_length[each]);
			visited_intersections << next_i;
			loop i over: successors_of (g, next_i){
				road r <- road(edge_between(g,next_i::intersection(i)));
				float dist <- path_length[next_i]+m[r];
				if not(intersection(i) in path_length.keys) or (dist < path_length[intersection(i)]) {
					put dist at: i in: path_length;
					put paths[next_i]+r at: i in: paths;
				}
			}
		}
		if current_road != nil{
			ask current_road as road {
				do unregister(myself);
			}
		}
		ask first(paths[dest]){
			do register(myself, 0);
		}
		targets <- paths[dest] accumulate (g target_of each);
		current_index <- 0;
		segment_index_on_road <- 0;
		current_target <- first(targets);
		final_target <- last(targets).location;
		return paths[dest] as path;
	}
	
	
	
	
	action remove_and_die {
		if (current_road != nil) {
			ask road(current_road) {
				do unregister(myself);
			}
		}
		do die;
	}

	

	
	
	reflex leave when: final_target = nil  {
			if (target_intersection != nil and target_intersection.exit[currentSimuState]=target_intersection) {// reached an exit
				if current_road != nil {
					ask current_road as road {
						do unregister(myself);
					}
				}
				current_lane <- 0;
				if flip(proba_used_od) {
					//current_intersection <- one_of(origin_intersections[currentSimuState]);
					int od_index <- rnd_choice(od_weights[currentSimuState].values);
					current_intersection <- od_origins[currentSimuState].values[od_index];
					target_intersection <- od_destinations[currentSimuState].values[od_index];
				} else {
					current_intersection <- one_of(possible_sources[currentSimuState]);
					target_intersection <- one_of(possible_targets[currentSimuState] - current_intersection);
				}
				location <-current_intersection.location;
				//target_intersection <- one_of(possible_targets[currentSimuState] - current_intersection);
				current_trajectory <- [];
			 }else if (target_intersection != nil and target_intersection.exit[currentSimuState] != nil) {// reached a dead end
				target_intersection <- target_intersection.exit[currentSimuState];
			}else{ // reached a generic target
				if flip(proba_used_od) {
					//current_intersection <- one_of(origin_intersections[currentSimuState]);
					int od_index <- rnd_choice(od_weights[currentSimuState].values);
					target_intersection <- od_destinations[currentSimuState].values[od_index];
				}else{
					target_intersection <- one_of(possible_targets[currentSimuState] - current_intersection);
				}
			}
			if int(self) = 0 {
				current_path <- new_shortest_path(driving_road_network[currentSimuState], target_intersection, general_speed_map);
			}else{
				current_path <- compute_path(graph: driving_road_network[currentSimuState], target: target_intersection);
			}
	}
	
	
	reflex move when: final_target != nil{	
		do drive;	  	
	  	//on tente le tout pour le tout
	  	loop while:(length(current_trajectory) > carTrajectoryLength)
  	    {
        current_trajectory >> first(current_trajectory);
        }
        current_trajectory << location;
	}
	
	
	action update{
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
					if int(self) = 0 {
						new_path <- new_shortest_path(driving_road_network[currentSimuState], target_intersection, general_speed_map);
					}else{
						new_path <- compute_path(graph: driving_road_network[currentSimuState], target: target_intersection);
					}	
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
			if flip(proba_used_od) {
				int od_index <- rnd_choice(od_weights[currentSimuState].values);
				current_intersection <- od_origins[currentSimuState].values[od_index];
				target_intersection <- od_destinations[currentSimuState].values[od_index];
//				current_intersection <- one_of(origin_intersections[currentSimuState]);
//				target_intersection <- one_of(destination_intersections[currentSimuState] - current_intersection);
			} else {
				current_intersection <- one_of(possible_sources[currentSimuState]);
				target_intersection <- one_of(possible_targets[currentSimuState] - current_intersection);
			}
			location <-current_intersection.location;
			if int(self) = 0 {
				current_path <- new_shortest_path(driving_road_network[currentSimuState], target_intersection, general_speed_map);
			}else{
				current_path <- compute_path(graph: driving_road_network[currentSimuState], target: target_intersection);
			}
			final_target <- target_intersection.location;
			current_lane <- 0;
			current_trajectory <- [];
		}	
	}
	

	
aspect base {
		if(showCar){
		    draw rectangle(1,2) at: location rotate:heading-90 color:in_tunnel?rgb(50,0,0):rgb(type_colors[type],(fade_count=0)?1:fade_count/20);	   
	  	}
	 
	  	if (test_car) and showCar{
	  		
	  		if current_path != nil{
	  			loop e over: current_path.edges{
	  				if int(self)=0{
	  					draw 5 around(road(e).shape) color: #cyan;
	  				}else{
	  					draw 3 around(road(e).shape) color: #white;
	  				}	
	  			}
	  		}
	  		loop p over: targets{
	  			draw circle(2#m) at: p color: #black; 
	  		}
	  		draw circle(2#m) at: current_intersection.location color: #blue; 
	  	//	draw circle(2#m) at: first(targets) color: #yellow; 
	  		draw circle(2#m) at: last(targets) color: #yellow; 
	  		draw circle(2#m) at: current_target color: #yellow;
	  		draw circle(5#m) at: location color:#blue; 
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
		if showTrafficSignal{
			color <- #white;
			if reachable_by_all[currentSimuState] {color <- #yellow;}
			if can_reach_all[currentSimuState] {color <- #blue;}
			if reachable_by_all[currentSimuState] and can_reach_all[currentSimuState] {color <- #green;}
			draw circle(5) color: color;
			if self in od_origins[currentSimuState].values{
			draw circle(2.5) color: #white;
			draw circle(1.5) color: #blue;
			loop i over: od_origins[currentSimuState].keys{
				if self = od_origins[currentSimuState][i]{
					draw line([location,od_destinations[currentSimuState][i]]) color: #white;
				}
			}
		}
		if self in od_destinations[currentSimuState].values{
			draw circle(2.5) color: #white;
			draw circle(1.5) color: #yellow;
		}
		}
		if (active and is_traffic_signal and showTrafficSignal) {
	//		draw triangle(5) color: color_group border: #black;
		}
	}
}



experiment test type: gui autorun:true{
	float minimum_cycle_duration<-0.025;	
	output {
		display champ type:opengl background:#black draw_env:false /*fullscreen:1*/  rotate:angle toolbar:false autosave:false synchronized:true
camera_pos: {1577.7317,1416.6484,2491.6749} camera_look_pos: {1577.7317,1416.605,0.0019} camera_up_vector: {0.0,1.0,0.0}
	  
	   	{	
			species road aspect: base;
			species intersection;
			species car aspect:base transparency:0.2;
									
			graphics 'tablebackground'{
				draw geometry(shape_file_bounds) color:#white empty:true;
				draw string("State: " + currentSimuState) rotate:angle at:{400,400} color:#white empty:true;
			}
			event["f"] action: {showTrafficSignal<-!showTrafficSignal;};	
			event["c"] action: {showCar<-!showCar;};
			event["r"] action: {showRoad<-!showRoad;};
			event["z"] action: {updateSim<-true;};
			
		

		}
	}
}

