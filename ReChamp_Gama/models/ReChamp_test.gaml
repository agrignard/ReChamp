/***
* Name: ReChamp
* Author: Arnaud Grignard, Nicolas Ayoub
* Description: ReChamp - 2019
* Tags: Tag1, Tag2, TagN
***/

model ReChamp

global {
	file buildings_shapefile <- file("../includes/GIS/buildings_WGS84.shp");
	file shape_file_bounds <- file("../includes/GIS/TableBounds_WGS84.shp");
	geometry shape <- envelope(shape_file_bounds);
	file gamaRaster <- file('../includes/PNG/4k still_proposal.png');
	list<file> backGrounds <- [file('../includes/PNG/4K still_white.png'),file('../includes/PNG/4k still_proposal.png'),file('../includes/PNG/4k still_existing.png'),file('../includes/PNG/4K still_black.png'),file('../includes/PNG/4k still_B_proposal.png'),file('../includes/PNG/4k still_B_existing.png')];
	bool showBackground <- true parameter: "Background:" category: "Vizu";
	int currentBackGround <-0;

	float angle<-26.5;
	
	init {

		create building from: buildings_shapefile with: [depth:float(read ("H_MOY")),date_of_creation:int(read ("AN_CONST"))];
		create graphicWorld from:shape_file_bounds;

	}

}

species building {
	string type; 
	int date_of_creation;
	float depth;
	rgb color <- rgb(75,75,75);
	aspect base {
		  draw shape color: #gray;	
	}
}

species graphicWorld{
	aspect base{
		if(showBackground){
		  draw shape texture:backGrounds[currentBackGround].path;	
		}
	}
}



experiment ReChamp type: gui autorun:true{
	float minimum_cycle_duration<-0.0125;	
	output {
		display champ type:opengl background:#black draw_env:false fullscreen:1  rotate:angle toolbar:false autosave:false synchronized:true
	   	camera_pos: {1770.4355,1602.6887,2837.8093} camera_look_pos: {1770.4355,1602.6392,-0.0014} camera_up_vector: {0.0,1.0,0.0}{

	    	
	    	species graphicWorld aspect:base;
			species building aspect: base;// transparency:0.5;
			

						
			graphics 'tablebackground'{
				draw geometry(shape_file_bounds) color:#white empty:true;
			}

            event["b"] action: {showBackground<-!showBackground;};
			
		}
	}
}

