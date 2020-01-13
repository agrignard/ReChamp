  /***
* Name: ReChamp
* Author: Arnaud Grignard, Tri Nguyen-Huu, Nicolas Ayoub 
* Description: ReChamp - 2019
* Tags: Tag1, Tag2, TagN
***/

model ReChamp

global {
	//EXISTING SHAPEFILE (FROM OPENDATA)
	file buildings_shapefile <- file("../includes/GIS/buildings.shp");
	
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
	
	//GENERATED SHAPEFILE (FROM QGIS)
	//MOBILITY
	file Champs_Mobility_Now_shapefile <- file("../includes/GIS/Champs_Mobility_Now.shp");
	file Etoile_Mobility_Now_shapefile <- file("../includes/GIS/Etoile_Mobility_Now.shp");
	file Concorde_Mobility_Now_shapefile <- file("../includes/GIS/Concorde_Mobility_Now.shp");
	file Palais_Mobility_Now_shapefile <- file("../includes/GIS/Palais_Mobility_Now.shp");
	
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
	
    graph Champs_Mobility_Now;
	graph Etoile_Mobility_Now;
	
	bool realData<-true;
	
	float max_dev <- 10.0;
	float fuzzyness <- 1.0;
		
	bool showPeople parameter: 'People (p)' category: "Agent" <-true;
	bool wander parameter: 'People Wandering' category: "Agent" <-true;
	
	bool showRoad parameter: 'Road (r)' category: "Mobility" <-false;
	bool showBike  parameter: 'Bike Lane (v)' category: "Mobility" <-false;
	bool showBuilding parameter: 'Building (b)' category: "Mobility" <-false;
	bool showBus parameter: 'Bus (n)' category: "Mobility" <-false;
	bool showMetro parameter: 'Metro (m)' category: "Mobility" <-false;
	bool showStation parameter: 'Station (s)' category: "Mobility" <-false;
	
	bool showGreen parameter: 'Green (j)' category: "Parameters" <-true;
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
    
	map<string, rgb> metro_colors <- ["1"::rgb("#FFCD00"), "2"::rgb("#003CA6"),"3"::rgb("#837902"), "6"::rgb("#E2231A"),"7"::rgb("#FA9ABA"),"8"::rgb("#E19BDF"),"9"::rgb("#B6BD00"),"12"::rgb("#007852"),"13"::rgb("#6EC4E8"),"14"::rgb("#62259D")];
	map<string, rgb> type_colors <- ["default"::#white,"people"::#white, "car"::rgb(204,0,106),"bike"::rgb(18,145,209), "bus"::rgb(131,191,98)];
	map<string, rgb> voirie_colors <- ["Piste"::#white,"Couloir Bus"::#green, "Couloir mixte bus-vélo"::#red,"Piste cyclable"::#blue];
	
	float angle<-26.25;

	int currentSimuState<-0;
	bool updateSim<-true;
	int nbAgent<-1000;
	map<string,float> mobilityRatio <-["people"::0.3, "car"::0.2,"bike"::0.1, "bus"::0.5];

	map<road,float> proba_use_road;
	
	init {
		//------------------ STATIC AGENT ----------------------------------- //
		create building from: buildings_shapefile with: [depth:float(read ("H_MOY"))];
		create road from: roads_shapefile with: [id:int(read ("OBJECTID"))];	
		create road from: Champs_Mobility_Now_shapefile  with: [mode:string(read ("mode")),proba_use:float(read("proba"))];
		create road from: Etoile_Mobility_Now_shapefile  with: [mode:string(read ("mode")),proba_use:float(read("proba"))];	
		create road from: Concorde_Mobility_Now_shapefile  with: [mode:string(read ("mode"))];
		create road from: Palais_Mobility_Now_shapefile  with: [mode:string(read ("mode"))];


		proba_use_road <- road as_map (each::each.proba_use);



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
		  location <- any_location_in(one_of(road where (each.mode="car")));
		}
		
		//Create Pedestrain
		create people number:nbAgent*mobilityRatio["people"]{
		  type <- "people";
		  location<-any_location_in(one_of(building));
		}
		
        //Create Bike
	    create people number:nbAgent*mobilityRatio["bike"]{
	      type <- "bike";
		  location<-any_location_in(one_of(building));	
		}
		
		//Create Bus
		create people number:nbAgent*mobilityRatio["bus"]{
		  type <- "bus";
		  location<-any_location_in(one_of(building));	
	    }
		
		car_graph <- as_edge_graph(road);
		people_graph <- as_edge_graph(road);
		bike_graph <- as_edge_graph(bikelane);
		bus_graph <- as_edge_graph(bus_line);
			
		Champs_Mobility_Now <- directed(as_edge_graph(road where (each.mode="car")));
			
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
	}
	
	reflex updateSimuState when:updateSim=true{
		//UPDATE NATURE
		ask stroller{do die;}
		if (currentSimuState = 0){
			
			ask greenSpace where (each.state="future"){
				do die;
			}
			create greenSpace from: Nature_Now_shapefile {
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
			ask greenSpace where (each.state="present"){
				do die;
			}
			create greenSpace from: Nature_Future_shapefile {
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
}

species culture{
	string state;
	aspect base {
		  draw shape color: #yellow;	
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
	string state;
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
	string mode;
	float proba_use <- 100.0;

	float capacity;		
	
	aspect base {
		if(showRoad){
			draw shape color:type_colors["car"] width:1;	
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


species stroller skills:[moving]{
	
	greenSpace myCurrentGarden;
		
	reflex strol{
		do wander bounds:myCurrentGarden.shape;
	}
	
	aspect base {
	  if(showPeople){
	    draw square(3#m) color:type_colors["people"] rotate: angle;   
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

	reflex leave when: (target = nil) {
		target <- any_location_in(one_of(building));
	}
	
	reflex move when: target != nil{	
	  if(type="bike"){
	  	if (wander){
	  	  do wander on:bike_graph speed:8.0#km/#h;	
	  	}else{
	  	  do goto target: target on: bike_graph  speed:8.0#km/#h recompute_path: false;
	  	}
	  }
	  if(type="bus"){
	  	if(wander){
	  	  do wander on:car_graph speed:6.0#km/#h;		
	  	}else{
	  	  do goto target: target on: car_graph  speed:6.0#km/#h recompute_path: false;	
	  	}
	  }	
	  if(type="car"){
	  	if(wander){
	  	  do wander on:Champs_Mobility_Now speed:25.0#km/#h proba_edges: proba_use_road ;	
	  	}else{
	  	  do goto target: target on: car_graph  speed:25.0#km/#h recompute_path: false;		
	  	}
	  }
	  if(type="people"){
	  	if(wander){
	  	  do wander on:people_graph speed:5.0#km/#h;		
	  	}else{
	  	  do goto target: target on: people_graph  speed:5.0#km/#h recompute_path: false;
	  	}
	  }	  
	}
	aspect base {
	  if(showPeople){
	     if (type="car"){
	     	 draw rectangle(5#m,10#m) rotate:heading-90 color:type_colors[type];	
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
			species greenSpace aspect: base ;
			species culture aspect: base ;
			species water aspect: base;
			species road aspect: base;
			species bus_line aspect: base;
			species metro_line aspect: base;
			species amenities aspect:base;
			species people aspect:base;
			species stroller aspect:base;
			species coldSpot aspect:base;
			species station aspect: base;
			species bikelane aspect:base;
						
			graphics 'tablebackground'{
				draw geometry(shape_file_bounds) color:#white empty:true;
				draw string("State: " + currentSimuState) rotate:angle at:{400,400} color:#white empty:true;
			}
			
			event["p"] action: {showPeople<-!showPeople;};
			event["g"] action: {showGif<-!showGif;};
			event["b"] action: {showBuilding<-!showBuilding;};
			event["r"] action: {showRoad<-!showRoad;};
			event["v"] action: {showBike<-!showBike;};
			event["m"] action: {showMetro<-!showMetro;};
			event["n"] action: {showBus<-!showBus;};
			event["s"] action: {showStation<-!showStation;};
			event["a"] action: {showAmenities<-!showAmenities;};
			event["j"] action: {showGreen<-!showGreen;};
			event["w"] action: {showWater<-!showWater;};
			event["f"] action: {randomColor<-!randomColor;};
			event["h"] action: {showHotSpot<-!showHotSpot;};
			event[" "] action: {showBackground<-!showBackground;};				
			event["0"] action: {if(currentSimuState!=0){currentSimuState<-0;updateSim<-true;}};
			event["1"] action: {if(currentSimuState!=1){currentSimuState<-1;updateSim<-true;}};
		}
	}
}

